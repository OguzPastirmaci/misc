# AIStore on OKE — Quickstart

Deploy NVIDIA AIStore on an existing OKE cluster with BM.DenseIO.E5.128 nodes (12x 5.8T NVMe each).

## 1. Label Worker Nodes

```bash
for node in $(kubectl get nodes -l node.kubernetes.io/instance-type=BM.DenseIO.E5.128 -o name); do
  kubectl label $node aistore.nvidia.com/role=proxy-target --overwrite
done
kubectl get nodes -l aistore.nvidia.com/role=proxy-target
```

## 2. Prepare NVMe Drives

Deploy a DaemonSet that automatically formats and mounts all NVMe drives on each worker node:

```bash
kubectl apply -f - << 'EOF'
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: nvme-provisioner
  namespace: kube-system
spec:
  selector:
    matchLabels:
      app: nvme-provisioner
  template:
    metadata:
      labels:
        app: nvme-provisioner
    spec:
      nodeSelector:
        aistore.nvidia.com/role: proxy-target
      hostPID: true
      hostNetwork: true
      containers:
      - name: nvme-setup
        image: ubuntu:24.04
        securityContext:
          privileged: true
        command:
        - /bin/bash
        - -c
        - |
          apt-get update -qq && apt-get install -y -qq mdadm xfsprogs util-linux > /dev/null 2>&1

          set -euo pipefail
          echo "=== NVMe provisioner starting on $(hostname) ==="

          FSTAB="/host-etc/fstab"
          MDADM_CONF="/host-etc/mdadm/mdadm.conf"

          # Stop any existing RAID
          if grep -q md0 /proc/mdstat 2>/dev/null; then
            echo "Tearing down existing RAID..."
            umount /mnt/nvme 2>/dev/null || true
            mdadm --stop /dev/md0 2>/dev/null || true
            mdadm --stop --scan 2>/dev/null || true
            for dev in /dev/nvme*n1; do
              mdadm --zero-superblock $dev 2>/dev/null || true
            done
            echo "" > "${MDADM_CONF}" 2>/dev/null || true
            sed -i '/\/dev\/md0/d' "${FSTAB}"
            sed -i '/\/mnt\/nvme/d' "${FSTAB}"
          fi

          # Format and mount each NVMe drive individually
          DISKS=($(ls -1 /dev/nvme*n1 2>/dev/null | sort -V))
          echo "Found ${#DISKS[@]} NVMe drives"
          for idx in "${!DISKS[@]}"; do
            dev="${DISKS[$idx]}"
            mp="/mnt/nvme${idx}"
            if mountpoint -q "${mp}" 2>/dev/null; then
              echo "${mp} already mounted, skipping"
              continue
            fi
            echo "Setting up ${dev} -> ${mp}"
            mkdir -p "${mp}"
            wipefs -a "${dev}" 2>/dev/null || true
            mkfs.xfs -f "${dev}"
            mount -o defaults,noatime,nofail "${dev}" "${mp}"
            uuid=$(blkid -s UUID -o value "${dev}")
            sed -i "\|${mp}|d" "${FSTAB}"
            echo "UUID=${uuid} ${mp} xfs defaults,noatime,nofail 0 2" >> "${FSTAB}"
          done

          echo "=== NVMe provisioner done ==="
          df -h | grep nvme

          # Sleep forever to keep the DaemonSet running
          sleep infinity
        volumeMounts:
        - name: host-dev
          mountPath: /dev
        - name: host-mnt
          mountPath: /mnt
          mountPropagation: Bidirectional
        - name: host-etc
          mountPath: /host-etc
        - name: host-run
          mountPath: /run/mdadm
      volumes:
      - name: host-dev
        hostPath:
          path: /dev
      - name: host-mnt
        hostPath:
          path: /mnt
      - name: host-etc
        hostPath:
          path: /etc
      - name: host-run
        hostPath:
          path: /run/mdadm
      tolerations:
      - operator: Exists
EOF
```

Wait for all pods to complete setup:

```bash
kubectl -n kube-system get pods -l app=nvme-provisioner -o wide
kubectl -n kube-system logs -l app=nvme-provisioner --tail=5
```

Verify from any worker node: `df -h | grep nvme` should show 12 drives at `/mnt/nvme0` through `/mnt/nvme11`.

## 3. Apply Network Tuning

Deploy a DaemonSet that applies sysctl tuning on all worker nodes:

```bash
kubectl apply -f - << 'EOF'
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: sysctl-tuner
  namespace: kube-system
spec:
  selector:
    matchLabels:
      app: sysctl-tuner
  template:
    metadata:
      labels:
        app: sysctl-tuner
    spec:
      nodeSelector:
        aistore.nvidia.com/role: proxy-target
      hostPID: true
      hostNetwork: true
      initContainers:
      - name: sysctl-apply
        image: ubuntu:24.04
        securityContext:
          privileged: true
        command:
        - /bin/bash
        - -c
        - |
          cat << 'SYSCTL' > /host-etc/sysctl.d/99-aistore.conf
          net.core.somaxconn=65535
          net.core.rmem_max=134217728
          net.core.wmem_max=134217728
          net.core.optmem_max=25165824
          net.core.netdev_max_backlog=250000
          net.ipv4.tcp_wmem=4096 16384 134217728
          net.ipv4.tcp_rmem=4096 262144 134217728
          net.ipv4.tcp_tw_reuse=1
          net.ipv4.ip_local_port_range=2048 65535
          net.ipv4.tcp_max_tw_buckets=1440000
          net.ipv4.tcp_max_syn_backlog=100000
          net.ipv4.tcp_mtu_probing=2
          net.ipv4.tcp_slow_start_after_idle=0
          net.ipv4.tcp_adv_win_scale=1
          SYSCTL
          sysctl -p /host-etc/sysctl.d/99-aistore.conf
          echo "=== sysctl tuning applied on $(hostname) ==="
        volumeMounts:
        - name: host-etc
          mountPath: /host-etc
      containers:
      - name: pause
        image: registry.k8s.io/pause:3.9
      volumes:
      - name: host-etc
        hostPath:
          path: /etc
      tolerations:
      - operator: Exists
EOF
```

Verify:

```bash
kubectl -n kube-system get pods -l app=sysctl-tuner
kubectl -n kube-system logs -l app=sysctl-tuner -c sysctl-apply
```

## 4. Install Cert-Manager (if not present)

```bash
# Check if cert-manager is already running
if kubectl get pods -n cert-manager 2>/dev/null | grep -q Running; then
  echo "cert-manager already running, skipping"
else
  # Install cert-manager
kubectl create namespace cert-manager --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.16.2/cert-manager.crds.yaml
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.16.2/cert-manager.yaml
kubectl -n cert-manager rollout status deploy/cert-manager --timeout=120s
kubectl -n cert-manager rollout status deploy/cert-manager-webhook --timeout=120s
kubectl -n cert-manager rollout status deploy/cert-manager-cainjector --timeout=120s
fi
```

## 5. Install AIStore Operator

```bash
kubectl create namespace ais
helm repo add ais https://nvidia.github.io/ais-k8s/charts
helm repo update
helm upgrade --install ais-operator ais/ais-operator --namespace ais

# Service account
kubectl -n ais create serviceaccount ais-sa
kubectl create clusterrolebinding ais-sa-cluster-admin \
  --clusterrole=cluster-admin --serviceaccount=ais:ais-sa

# Verify
kubectl get pods -n ais
kubectl get crd | grep ais
```

## 6. Deploy AIStore

```bash
kubectl apply -f - << 'EOF'
apiVersion: ais.nvidia.com/v1beta1
kind: AIStore
metadata:
  name: ais
  namespace: ais
spec:
  hostpathPrefix: "/mnt/aistore"
  logsDir: "/mnt/aistore/logs"
  nodeImage: "aistorage/aisnode:v4.3"
  initImage: "aistorage/ais-init:v4.3"
  enableExternalLB: false
  proxySpec:
    size: 6
    servicePort: 51080
    portPublic: 51080
    portIntraControl: 51082
    portIntraData: 51083
    nodeSelector:
      aistore.nvidia.com/role: proxy-target
  targetSpec:
    size: 6
    hostNetwork: true
    servicePort: 51081
    portPublic: 51081
    portIntraControl: 51082
    portIntraData: 51083
    nodeSelector:
      aistore.nvidia.com/role: proxy-target
    mounts:
    - path: "/mnt/nvme0"
      useHostPath: true
      size: 5Ti
      label: "nvme"
    - path: "/mnt/nvme1"
      useHostPath: true
      size: 5Ti
      label: "nvme"
    - path: "/mnt/nvme2"
      useHostPath: true
      size: 5Ti
      label: "nvme"
    - path: "/mnt/nvme3"
      useHostPath: true
      size: 5Ti
      label: "nvme"
    - path: "/mnt/nvme4"
      useHostPath: true
      size: 5Ti
      label: "nvme"
    - path: "/mnt/nvme5"
      useHostPath: true
      size: 5Ti
      label: "nvme"
    - path: "/mnt/nvme6"
      useHostPath: true
      size: 5Ti
      label: "nvme"
    - path: "/mnt/nvme7"
      useHostPath: true
      size: 5Ti
      label: "nvme"
    - path: "/mnt/nvme8"
      useHostPath: true
      size: 5Ti
      label: "nvme"
    - path: "/mnt/nvme9"
      useHostPath: true
      size: 5Ti
      label: "nvme"
    - path: "/mnt/nvme10"
      useHostPath: true
      size: 5Ti
      label: "nvme"
    - path: "/mnt/nvme11"
      useHostPath: true
      size: 5Ti
      label: "nvme"
EOF
```

Wait for pods:

```bash
kubectl -n ais get pods -w
# Wait until all proxy and target pods are Running
kubectl -n ais get sts
```

## 7. Create Load Balancer Service

```bash
kubectl apply -f - << 'EOF'
apiVersion: v1
kind: Service
metadata:
  name: ais-proxy-lb
  namespace: ais
  annotations:
    service.beta.kubernetes.io/oci-load-balancer-shape: "flexible"
    service.beta.kubernetes.io/oci-load-balancer-shape-flex-min: "100"
    service.beta.kubernetes.io/oci-load-balancer-shape-flex-max: "4900"
spec:
  type: LoadBalancer
  selector:
    app: ais
    component: proxy
  ports:
  - name: pub
    protocol: TCP
    port: 51080
    targetPort: 51080
EOF

# Wait for external IP
kubectl get svc -n ais ais-proxy-lb -w
```

## 8. Install AIS CLI and Test

```bash
# Install Go 1.26+ and build tools (system Go is typically too old)
sudo apt-get update && sudo apt-get install -y make
sudo rm -rf /usr/local/go
curl -fsSL https://go.dev/dl/go1.26.1.linux-amd64.tar.gz | sudo tar -C /usr/local -xz
export PATH=/usr/local/go/bin:$PATH
echo 'export PATH=/usr/local/go/bin:$PATH' >> ~/.bashrc
go version

# Build AIS CLI and aisloader from source
export GOPATH=$HOME/go
mkdir -p $GOPATH/src/github.com/NVIDIA
cd $GOPATH/src/github.com/NVIDIA
git clone https://github.com/NVIDIA/aistore.git
cd aistore
make cli aisloader
sudo cp $GOPATH/bin/ais $GOPATH/bin/aisloader /usr/local/bin/
ais version

# Set endpoint (auto-detect LB IP)
export AIS_ENDPOINT=http://$(kubectl get svc -n ais ais-proxy-lb -o jsonpath='{.status.loadBalancer.ingress[0].ip}'):51080

# Verify
ais show cluster

# Smoke test
ais create ais://test-bucket
echo "Hello from AIStore" > /tmp/test.txt
ais put /tmp/test.txt ais://test-bucket/test.txt
ais get ais://test-bucket/test.txt /tmp/test-out.txt
cat /tmp/test-out.txt
```

## 9. Run Benchmark

```bash
# Tune sysctl on the machine running aisloader to avoid port exhaustion
sudo sysctl -w net.ipv4.ip_local_port_range="1024 65535"
sudo sysctl -w net.ipv4.tcp_tw_reuse=1

export AIS_ENDPOINT=http://$(kubectl get svc -n ais ais-proxy-lb -o jsonpath='{.status.loadBalancer.ingress[0].ip}'):51080

# Pre-create bucket
ais create ais://bench

# Write (32 workers, 1MB objects, 1 min)
aisloader -bucket=ais://bench -duration=1m -numworkers=32 \
  -minsize=1MB -maxsize=1MB -pctput=100 -cleanup=false

# Read
aisloader -bucket=ais://bench -duration=1m -numworkers=32 \
  -minsize=1MB -maxsize=1MB -pctput=0 -cleanup=false
```

For aggregate throughput, deploy a benchmark DaemonSet that runs aisloader from all worker nodes in parallel:

```bash
# Pre-create the bucket
ais create ais://ds-bench 2>/dev/null || true

# Deploy benchmark DaemonSet
LB_IP=$(kubectl get svc -n ais ais-proxy-lb -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

kubectl apply -f - << EOF
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: ais-bench
  namespace: ais
spec:
  selector:
    matchLabels:
      app: ais-bench
  template:
    metadata:
      labels:
        app: ais-bench
    spec:
      nodeSelector:
        aistore.nvidia.com/role: proxy-target
      hostNetwork: true
      containers:
      - name: bench
        image: aistorage/ais-util:latest
        command: ["/bin/bash", "-c"]
        args:
        - |
          /usr/bin/aisloader \
            -bucket=ais://ds-bench \
            -duration=2m \
            -numworkers=64 \
            -minsize=1MB \
            -maxsize=1MB \
            -pctput=100 \
            -cleanup=false \
            -ip=\${LB_IP} \
            -port=51080
          echo "=== Benchmark complete on \$(hostname) ==="
          sleep infinity
        env:
        - name: LB_IP
          value: "${LB_IP}"
      tolerations:
      - operator: Exists
      restartPolicy: Always
EOF

# Watch progress
sleep 10
kubectl -n ais logs -l app=ais-bench --tail=3

# View results per pod (pods sleep after completion)
for pod in $(kubectl get pods -n ais -l app=ais-bench -o name); do
  NODE=$(kubectl get -n ais $pod -o jsonpath='{.spec.nodeName}')
  echo "$NODE: $(kubectl logs -n ais $pod | grep -E '^[0-9].*PUT.*GiB/s' | tail -1)"
done

# Cleanup write benchmark
kubectl delete ds ais-bench -n ais
```

### Read Benchmark DaemonSet

Run after the write benchmark (reads the objects written above):

```bash
LB_IP=$(kubectl get svc -n ais ais-proxy-lb -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

kubectl apply -f - << EOF
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: ais-bench-read
  namespace: ais
spec:
  selector:
    matchLabels:
      app: ais-bench-read
  template:
    metadata:
      labels:
        app: ais-bench-read
    spec:
      nodeSelector:
        aistore.nvidia.com/role: proxy-target
      hostNetwork: true
      containers:
      - name: bench
        image: aistorage/ais-util:latest
        command: ["/bin/bash", "-c"]
        args:
        - |
          /usr/bin/aisloader \
            -bucket=ais://ds-bench \
            -duration=2m \
            -numworkers=64 \
            -minsize=1MB \
            -maxsize=1MB \
            -pctput=0 \
            -cleanup=false \
            -ip=\${LB_IP} \
            -port=51080
          echo "=== Read benchmark complete on \$(hostname) ==="
          sleep infinity
        env:
        - name: LB_IP
          value: "${LB_IP}"
      tolerations:
      - operator: Exists
      restartPolicy: Always
EOF

# View results
sleep 150
for pod in $(kubectl get pods -n ais -l app=ais-bench-read -o name); do
  NODE=$(kubectl get -n ais $pod -o jsonpath='{.spec.nodeName}')
  echo "$NODE: $(kubectl logs -n ais $pod | grep -E '^[0-9].*GET.*GiB/s' | tail -1)"
done

# Cleanup
kubectl delete ds ais-bench-read -n ais
```
