# Slinky on OKE -- RDMA Quickstart

## Prerequisites

### Fix CRI-O memlock

```sh
kubectl apply -f - <<'EOF'
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: crio-memlock-fix
  namespace: kube-system
spec:
  selector:
    matchLabels:
      app: crio-memlock-fix
  template:
    metadata:
      labels:
        app: crio-memlock-fix
    spec:
      hostNetwork: true
      hostPID: true
      nodeSelector:
        node.kubernetes.io/instance-type: BM.GPU.B4.8
      tolerations:
        - { key: nvidia.com/gpu, operator: Exists, effect: NoSchedule }
        - { key: nodeset.slinky.slurm.net/worker, operator: Exists, effect: NoExecute }
      initContainers:
        - name: fix
          image: alpine
          securityContext: { privileged: true }
          command: ["sh", "-c"]
          args:
            - |
              if nsenter -t 1 -m -- grep -q memlock /etc/crio/crio.conf.d/00-default.conf 2>/dev/null; then exit 0; fi
              nsenter -t 1 -m -- sed -i 's|default_ulimits = \["nofile=1048576:1048576"\]|default_ulimits = ["nofile=1048576:1048576", "memlock=-1:-1"]|' /etc/crio/crio.conf.d/00-default.conf
              nsenter -t 1 -m -u -i -n -p -- systemctl restart crio && sleep 5
      containers:
        - { name: pause, image: registry.k8s.io/pause:3.9 }
EOF
```

### Install cert-manager + Slinky operator

```sh
helm install cert-manager oci://quay.io/jetstack/charts/cert-manager \
  --namespace cert-manager --create-namespace --set crds.enabled=true

helm install slurm-operator-crds oci://ghcr.io/slinkyproject/charts/slurm-operator-crds

helm install slurm-operator oci://ghcr.io/slinkyproject/charts/slurm-operator \
  --namespace=slinky --create-namespace

# Wait for the operator webhook to be ready before installing the slurm cluster
kubectl -n slinky rollout status deployment/slurm-operator-webhook --timeout=60s
```

---

## Option A: hostNetwork

This needs:

- Manual GRES config instead of AutoDetect=nvidia (avoids core affinity mismatch on bare-metal)
- ReturnToService=2 to handle CPU count mismatches from cgroup detection

Uses PMIx images for `srun --mpi=pmix`.

### Create values file

```sh
cat > slinky-values-hostnetwork.yaml <<'EOF'
controller:
  slurmctld:
    image:
      repository: iad.ocir.io/idxzjcdglx2s/slinky
      tag: slurmctld-pmix-25.11-ubuntu24.04
  persistence:
    enabled: true
    storageClassName: oci-bv
    resources:
      requests:
        storage: 10Gi
  extraConfMap:
    GresTypes: "gpu"
    ReturnToService: 2                           # hostNetwork: cgroup CPU mismatch
    PropagateResourceLimitsExcept: MEMLOCK        # srun --mpi=pmix: RDMA memlock

configFiles:
  gres.conf: |
    Name=gpu Type=a100 File=/dev/nvidia[0-7]
  cgroup.conf: |
    CgroupPlugin=cgroup/v2
    IgnoreSystemd=yes
    ConstrainCores=yes
    ConstrainRAMSpace=no
    ConstrainDevices=yes
    ConstrainSwapSpace=no

restapi:
  replicas: 1

nodesets:
  slinky:
    enabled: false
  gpu-b4:
    enabled: true
    replicas: 2                          # Number of GPU nodes
    useResourceLimits: false
    slurmd:
      image:
        repository: iad.ocir.io/idxzjcdglx2s/slinky
        tag: slurmd-rdma-pmix-25.11-ubuntu24.04
      resources:
        limits:
          nvidia.com/gpu: 8
        requests:
          nvidia.com/gpu: 8
      volumeMounts:
        - { name: devinf, mountPath: /dev/infiniband }
        - { name: shm, mountPath: /dev/shm }
    logfile:
      image: { repository: docker.io/library/alpine, tag: latest }
    extraConfMap:
      Gres: ["gpu:a100:8"]
      Features: ["a100", "40gb", "rdma"]
      Weight: 1
    partition:
      enabled: true
      configMap:
        State: UP
        Default: "YES"
        MaxTime: UNLIMITED
    updateStrategy:
      type: RollingUpdate
      rollingUpdate:
        maxUnavailable: 25%
    podSpec:
      hostNetwork: true
      dnsPolicy: ClusterFirstWithHostNet
      nodeSelector:
        node.kubernetes.io/instance-type: BM.GPU.B4.8
      tolerations:
        - { key: nvidia.com/gpu, effect: NoSchedule, operator: Exists }
      volumes:
        - { name: devinf, hostPath: { path: /dev/infiniband } }
        - { name: shm, emptyDir: { medium: Memory, sizeLimit: 32Gi } }

partitions:
  all:
    enabled: true
    nodesets: [ALL]
    configMap: { State: UP, MaxTime: UNLIMITED }

loginsets:
  slinky:
    enabled: true
    replicas: 1
    rootSshAuthorizedKeys: "ssh-rsa YOUR_KEY_HERE"
    service:
      spec: { type: LoadBalancer }

accounting:
  enabled: false
vendor:
  nvidia:
    dcgm:
      enabled: false
EOF
```

### Install

```sh
helm install slurm oci://ghcr.io/slinkyproject/charts/slurm \
  -f slinky-values-hostnetwork.yaml --namespace=slurm --create-namespace
```

### Verify

```sh
kubectl -n slurm get pods
kubectl -n slurm exec slurm-controller-0 -c slurmctld -- sinfo
kubectl -n slurm exec slurm-controller-0 -c slurmctld -- srun --gres=gpu:8 nvidia-smi -L
```

### Run NCCL test (srun --mpi=pmix)

```sh
kubectl -n slurm exec slurm-controller-0 -c slurmctld -- bash -c 'cat > /tmp/nccl.sh << "NCCL"
#!/bin/bash
#SBATCH --gres=gpu:8 -N 2 --ntasks-per-node=8

export LD_LIBRARY_PATH=/usr/local/openmpi/lib:/usr/lib/x86_64-linux-gnu:/usr/local/cuda/lib64
export NCCL_DEBUG=WARN NCCL_SOCKET_IFNAME=eth0
export NCCL_IB_SPLIT_DATA_ON_QPS=0 NCCL_IB_QPS_PER_CONNECTION=4 NCCL_IB_GID_INDEX=3
export NCCL_IB_HCA="=mlx5_1,mlx5_2,mlx5_3,mlx5_4,mlx5_5,mlx5_6,mlx5_7,mlx5_8,mlx5_14,mlx5_15,mlx5_16,mlx5_17,mlx5_9,mlx5_10,mlx5_11,mlx5_12"
export NCCL_IB_TC=41 NCCL_IB_SL=0 NCCL_IB_TIMEOUT=22
export OMPI_MCA_oob_tcp_if_include=eth0
export OMPI_MCA_btl_tcp_if_include=eth0

srun --mpi=pmix /opt/nccl-tests/bin/all_reduce_perf -b 1G -f 2 -g 1 -e 4G -c 1
NCCL
chmod +x /tmp/nccl.sh && sbatch --output=/tmp/nccl-out.txt --wait /tmp/nccl.sh && echo OK'

# Read output
kubectl -n slurm exec slurm-worker-gpu-b4-0 -c slurmd -- cat /tmp/nccl-out.txt 2>/dev/null || \
kubectl -n slurm exec slurm-worker-gpu-b4-1 -c slurmd -- cat /tmp/nccl-out.txt
```

---

## Option B: SR-IOV Virtual Functions

Requires NVIDIA Network Operator with SR-IOV. Simpler config than hostNetwork — no DNS, OpenMPI, or CPU mismatch workarounds.

Follow the steps in https://github.com/oracle-quickstart/oci-hpc-oke/tree/vf to create the VFs.

### Copy NetworkAttachmentDefinition to slurm namespace

```sh
kubectl create namespace slurm
kubectl get net-attach-def sriov-rdma-vf -o json | \
  jq '.metadata = {name: .metadata.name, namespace: "slurm", annotations: .metadata.annotations}' | \
  kubectl apply -f -
```

### Create values file

```sh
cat > slinky-values-sriov.yaml <<'EOF'
controller:
  slurmctld:
    image:
      repository: iad.ocir.io/idxzjcdglx2s/slinky
      tag: slurmctld-pmix-25.11-ubuntu24.04
  persistence:
    enabled: true
    storageClassName: oci-bv
    resources:
      requests:
        storage: 10Gi
  extraConfMap:
    GresTypes: "gpu"
    PropagateResourceLimitsExcept: MEMLOCK        # srun --mpi=pmix: RDMA memlock

configFiles:
  gres.conf: |
    Name=gpu Type=a100 File=/dev/nvidia[0-7]
  cgroup.conf: |
    CgroupPlugin=cgroup/v2
    IgnoreSystemd=yes
    ConstrainCores=yes
    ConstrainRAMSpace=no
    ConstrainDevices=yes
    ConstrainSwapSpace=no

restapi:
  replicas: 1

nodesets:
  slinky:
    enabled: false
  gpu-b4:
    enabled: true
    replicas: 2                          # Number of GPU nodes
    useResourceLimits: false
    slurmd:
      image:
        repository: iad.ocir.io/idxzjcdglx2s/slinky
        tag: slurmd-rdma-pmix-25.11-ubuntu24.04
      resources:
        limits:
          nvidia.com/gpu: 8
          nvidia.com/sriov-rdma-vf: 16   # 16 SR-IOV RDMA VFs per node
        requests:
          nvidia.com/gpu: 8
          nvidia.com/sriov-rdma-vf: 16
      volumeMounts:
        - { name: devinf, mountPath: /dev/infiniband }
        - { name: shm, mountPath: /dev/shm }
    logfile:
      image: { repository: docker.io/library/alpine, tag: latest }
    extraConfMap:
      Gres: ["gpu:a100:8"]
      Features: ["a100", "40gb", "rdma", "sriov"]
      Weight: 1
    partition:
      enabled: true
      configMap:
        State: UP
        Default: "YES"
        MaxTime: UNLIMITED
    updateStrategy:
      type: RollingUpdate
      rollingUpdate:
        maxUnavailable: 25%
    metadata:
      annotations:
        k8s.v1.cni.cncf.io/networks: sriov-rdma-vf,sriov-rdma-vf,sriov-rdma-vf,sriov-rdma-vf,sriov-rdma-vf,sriov-rdma-vf,sriov-rdma-vf,sriov-rdma-vf,sriov-rdma-vf,sriov-rdma-vf,sriov-rdma-vf,sriov-rdma-vf,sriov-rdma-vf,sriov-rdma-vf,sriov-rdma-vf,sriov-rdma-vf
    podSpec:
      nodeSelector:
        node.kubernetes.io/instance-type: BM.GPU.B4.8
      tolerations:
        - { key: nvidia.com/gpu, effect: NoSchedule, operator: Exists }
      volumes:
        - { name: devinf, hostPath: { path: /dev/infiniband } }
        - { name: shm, emptyDir: { medium: Memory, sizeLimit: 32Gi } }

partitions:
  all:
    enabled: true
    nodesets: [ALL]
    configMap: { State: UP, MaxTime: UNLIMITED }

loginsets:
  slinky:
    enabled: true
    replicas: 1
    rootSshAuthorizedKeys: "ssh-rsa YOUR_KEY_HERE"
    service:
      spec: { type: LoadBalancer }

accounting:
  enabled: false
vendor:
  nvidia:
    dcgm:
      enabled: false
EOF
```

### Install

```sh
helm install slurm oci://ghcr.io/slinkyproject/charts/slurm \
  -f slinky-values-sriov.yaml --namespace=slurm --create-namespace
```

### Verify

```sh
kubectl -n slurm get pods
kubectl -n slurm exec slurm-controller-0 -c slurmctld -- sinfo
kubectl -n slurm exec slurm-controller-0 -c slurmctld -- srun --gres=gpu:8 nvidia-smi -L
```

### Run NCCL test (srun --mpi=pmix)

```sh
kubectl -n slurm exec slurm-controller-0 -c slurmctld -- bash -c 'cat > /tmp/nccl.sh << "NCCL"
#!/bin/bash
#SBATCH --gres=gpu:8 -N 2 --ntasks-per-node=8

export LD_LIBRARY_PATH=/usr/local/openmpi/lib:/usr/lib/x86_64-linux-gnu:/usr/local/cuda/lib64
export NCCL_DEBUG=WARN
export NCCL_IB_SPLIT_DATA_ON_QPS=0 NCCL_IB_QPS_PER_CONNECTION=4 NCCL_IB_GID_INDEX=3
export NCCL_IB_HCA=mlx5 NCCL_IB_TC=41 NCCL_IB_SL=0 NCCL_IB_TIMEOUT=22

srun --mpi=pmix /opt/nccl-tests/bin/all_reduce_perf -b 1G -f 2 -g 1 -e 4G -c 1
NCCL
chmod +x /tmp/nccl.sh && sbatch --output=/tmp/nccl-out.txt --wait /tmp/nccl.sh && echo OK'

# Read output
kubectl -n slurm exec slurm-worker-gpu-b4-0 -c slurmd -- cat /tmp/nccl-out.txt 2>/dev/null || \
kubectl -n slurm exec slurm-worker-gpu-b4-1 -c slurmd -- cat /tmp/nccl-out.txt
```

---

## Pre-Built Images

| Tag | Description |
|---|---|
| `iad.ocir.io/idxzjcdglx2s/slinky:slurmd-rdma-25.11-ubuntu24.04` | slurmd + CUDA/NCCL/RDMA + nccl-tests (stock OpenMPI) |
| `iad.ocir.io/idxzjcdglx2s/slinky:slurmd-rdma-pmix-25.11-ubuntu24.04` | Same + OpenMPI with PMIx (for `srun --mpi=pmix`) |
| `iad.ocir.io/idxzjcdglx2s/slinky:slurmctld-pmix-25.11-ubuntu24.04` | slurmctld + libpmix (pair with slurmd-rdma-pmix) |

Both values files above already include the `slurmctld-pmix` image and `PropagateResourceLimitsExcept: MEMLOCK`.

---

## Cleanup

```sh
helm uninstall slurm -n slurm
helm uninstall slurm-operator -n slinky
helm uninstall slurm-operator-crds
helm uninstall cert-manager -n cert-manager
kubectl delete namespace slurm slinky
```
