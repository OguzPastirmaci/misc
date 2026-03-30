# Soperator on OKE — Quick Start (RDMA with SR-IOV VFs)

This guide assumes:

- You created VFs using: https://github.com/oracle-quickstart/oci-hpc-oke/tree/vf
- FSS is deployed and a PV exists

---

## 1. Clone repo and install cert-manager

```bash
git clone https://github.com/nebius/soperator.git ~/soperator
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.14.5/cert-manager.yaml
kubectl wait --for=condition=Available deployment --all -n cert-manager --timeout=120s
```

## 2. Create namespaces, install CRDs

```bash
kubectl create namespace slurm1
kubectl create namespace soperator-system
kubectl apply --server-side -f ~/soperator/helm/soperator-crds/templates/
```

## 3. Create jail PVC

```bash
kubectl apply -f - <<'EOF'
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: jail-pvc
  namespace: slurm1
spec:
  accessModes: [ReadWriteMany]
  storageClassName: ""
  resources:
    requests:
      storage: 50Gi
  volumeName: fss-pv
EOF
```

## 4. Copy SR-IOV NetworkAttachmentDefinition to slurm1

```bash
kubectl get network-attachment-definitions sriov-rdma-vf -o yaml \
  | sed 's/namespace: default/namespace: slurm1/' | kubectl apply -f -
```

## 5. Add topology labels to GPU nodes (dummy for now, not looking at RDMA topo info)

```bash
# Repeat for each GPU node
kubectl label node <gpu-node-ip> topology.kubernetes.io/tier-1=switch0
```

## 6. Install soperator operator

```bash
cd ~/soperator/helm/soperator && helm dependency build && cd ~

cat > soperator-values.yaml <<'EOF'
controllerManager:
  manager:
    image:
      repository: cr.eu-north1.nebius.cloud/soperator/slurm-operator
      tag: "3.0.2"
    env:
      isMariadbCrdInstalled: "false"
      isPrometheusCrdInstalled: "false"
      isOpentelemetryCollectorCrdInstalled: "false"
      isApparmorCrdInstalled: "false"
      slurmOperatorWatchNamespaces: "*"
      topologyLabelPrefix: "topology.kubernetes.io"
    nodeSelector:
      oke.oraclecloud.com/pool.name: "oke-system"
certManager:
  enabled: true
kruise:
  installOperator: true
  manager:
    replicas: 1
    nodeSelector:
      oke.oraclecloud.com/pool.name: "oke-system"
serviceMonitor:
  enabled: false
EOF

helm install soperator ~/soperator/helm/soperator -n soperator-system -f soperator-values.yaml
```

## 7. Deploy Slurm cluster

Adjust `NodeName` lines to match your worker count. CPUs/memory should match your GPU shape.

```bash
cat > slurm-cluster-values.yaml <<'EOF'
clusterName: "slurm1"
clusterType: gpu
cudaVersion: "12.9.0"
useDefaultAppArmorProfile: false

k8sNodeFilters:
  - name: gpu
    affinity:
      nodeAffinity:
        requiredDuringSchedulingIgnoredDuringExecution:
          nodeSelectorTerms:
            - matchExpressions:
                - key: oke.oraclecloud.com/pool.name
                  operator: In
                  values: ["oke-rdma"]
    tolerations:
      - key: nvidia.com/gpu
        operator: Exists
        effect: NoSchedule
  - name: no-gpu
    affinity:
      nodeAffinity:
        requiredDuringSchedulingIgnoredDuringExecution:
          nodeSelectorTerms:
            - matchExpressions:
                - key: oke.oraclecloud.com/pool.name
                  operator: In
                  values: ["oke-system"]
  - name: system
    affinity:
      nodeAffinity:
        requiredDuringSchedulingIgnoredDuringExecution:
          nodeSelectorTerms:
            - matchExpressions:
                - key: oke.oraclecloud.com/pool.name
                  operator: In
                  values: ["oke-system"]

volumeSources:
  - name: jail
    createPVC: false
    storageClassName: ""
    size: ""
    persistentVolumeClaim:
      claimName: "jail-pvc"
      readOnly: false

customSlurmConfig: |
  SlurmctldParameters=conmgr_max_connections=1024,conmgr_threads=32,enable_configless
  NodeName=worker-gpu-0 CPUs=255 RealMemory=1900000 Gres=gpu:8 NodeAddr=worker-gpu-0.slurm1-nodeset-svc.slurm1.svc.cluster.local
  NodeName=worker-gpu-1 CPUs=255 RealMemory=1900000 Gres=gpu:8 NodeAddr=worker-gpu-1.slurm1-nodeset-svc.slurm1.svc.cluster.local
  SuspendTime=-1

populateJail:
  overwrite: true
  k8sNodeFilterName: "gpu"

slurmConfig:
  defMemPerNode: 0
  defCpuPerGPU: 4
  completeWait: 5
  maxJobCount: 20000
  minJobAge: 28800
  messageTimeout: 60
  topologyPlugin: "topology/tree"
  topologyParam: "SwitchAsNodeRank"

slurmNodes:
  controller:
    k8sNodeFilterName: "no-gpu"
    slurmctld:
      resources:
        cpu: "1000m"
        memory: "3Gi"
        ephemeralStorage: "20Gi"
    volumes:
      spool:
        volumeClaimTemplateSpec:
          accessModes: ["ReadWriteOnce"]
          resources:
            requests:
              storage: 50Gi
          storageClassName: "oci-bv"
      jail:
        volumeSourceName: "jail"
  login:
    size: 1
    k8sNodeFilterName: "no-gpu"
    sshRootPublicKeys:
      - "ssh-rsa AAAA... your-key-here"
    sshdServiceType: "NodePort"
    sshdServiceNodePort: 30022
    volumes:
      jail:
        volumeSourceName: "jail"
  exporter:
    enabled: true
    size: 1
    k8sNodeFilterName: "no-gpu"
    volumes:
      jail:
        volumeSourceName: "jail"

sConfigController:
  node:
    k8sNodeFilterName: "system"
    size: 1
  serviceMonitor:
    enabled: false

# All built-in slurm health checks work on OKE with SR-IOV VFs — no need to disable any
EOF

helm install slurm-cluster ~/soperator/helm/slurm-cluster -n slurm1 -f slurm-cluster-values.yaml
```

## 8. Deploy NodeSets with RDMA

```bash
cat > nodesets-values.yaml <<'EOF'
images:
  munge:
    repository: "cr.eu-north1.nebius.cloud/soperator/munge"
    tag: "3.0.2-slurm25.11.3"
  slurmd:
    repository: "cr.eu-north1.nebius.cloud/soperator/worker_slurmd"
    tag: "3.0.2-slurm25.11.3"

nodesets:
  - name: worker-gpu
    replicas: 2
    enableHostUserNamespace: true
    gpu:
      enabled: true
      nvidia:
        gdrCopyEnabled: true
    nodeConfig:
      features: ["gpu", "cuda"]
      static: "Boards=1 SocketsPerBoard=2 CoresPerSocket=64 ThreadsPerCore=2"
      dynamic: "InstanceId={{ .PodName }}"
      gresConfig:
        - "Name=gpu Type=nvidia File=/dev/nvidia[0-7]"
    slurmd:
      image:
        repository: "cr.eu-north1.nebius.cloud/soperator/worker_slurmd"
        tag: "3.0.2-slurm25.11.3"
        pullPolicy: "IfNotPresent"
      customEnv:
        - { name: "NVIDIA_DRIVER_CAPABILITIES", value: "compute,utility,video" }
        - { name: "NCCL_IB_HCA", value: "mlx5" }
        - { name: "NCCL_IB_GID_INDEX", value: "3" }
        - { name: "NCCL_IB_TC", value: "41" }
        - { name: "NCCL_IB_SL", value: "0" }
        - { name: "NCCL_IB_TIMEOUT", value: "22" }
        - { name: "NCCL_IB_SPLIT_DATA_ON_QPS", value: "0" }
        - { name: "NCCL_IB_QPS_PER_CONNECTION", value: "4" }
        - { name: "HCOLL_ENABLE_MCAST_ALL", value: "0" }
        - { name: "UCX_TLS", value: "tcp" }
        - { name: "UCX_NET_DEVICES", value: "eth0" }
      resources:
        cpu: "60000m"
        memory: "1900Gi"
        ephemeralStorage: "55Gi"
        gpu: 8
      volumes:
        spool:
          volumeClaimTemplateSpec:
            storageClassName: "oci-bv"
            accessModes: ["ReadWriteOnce"]
            resources:
              requests:
                storage: "128Gi"
        jail:
          persistentVolumeClaim:
            claimName: "jail-pvc"
        sharedMemorySize: "32Gi"
        customVolumeMounts:
          - name: devinf
            mountPath: /dev/infiniband
            volumeSource:
              hostPath:
                path: /dev/infiniband
      security:
        appArmorProfile: "unconfined"
    munge:
      image:
        repository: "cr.eu-north1.nebius.cloud/soperator/munge"
        tag: "3.0.2-slurm25.11.3"
        pullPolicy: "IfNotPresent"
      resources:
        cpu: "2000m"
        memory: "4Gi"
        ephemeralStorage: "5Gi"
    workerAnnotations:
      k8s.v1.cni.cncf.io/networks: "sriov-rdma-vf,sriov-rdma-vf,sriov-rdma-vf,sriov-rdma-vf,sriov-rdma-vf,sriov-rdma-vf,sriov-rdma-vf,sriov-rdma-vf,sriov-rdma-vf,sriov-rdma-vf,sriov-rdma-vf,sriov-rdma-vf,sriov-rdma-vf,sriov-rdma-vf,sriov-rdma-vf,sriov-rdma-vf"
    affinity:
      nodeAffinity:
        requiredDuringSchedulingIgnoredDuringExecution:
          nodeSelectorTerms:
            - matchExpressions:
                - key: oke.oraclecloud.com/pool.name
                  operator: In
                  values: ["oke-rdma"]
    tolerations:
      - key: nvidia.com/gpu
        operator: Exists
        effect: NoSchedule
EOF

helm install nodesets ~/soperator/helm/nodesets -n slurm1 -f nodesets-values.yaml
```

## 9. Patch NodeSet CR (Helm can't set these)

```bash
kubectl patch nodeset worker-gpu -n slurm1 --type merge -p '{
  "spec": {
    "enableHostUserNamespace": true,
    "slurmd": {
      "security": { "procMount": "Default" },
      "resources": { "nvidia.com/sriov-rdma-vf": "16" }
    }
  }
}'
```

## 10. Wait for populate-jail, then switch to overwrite=false

The first populate-jail run (~5-10 minutes) will error on FSS's `.snapshot` directory — this is cosmetic, the jail is populated. Wait for it to complete, then:

```bash
# Wait for jail to be populated (watch for Completed or Error)
kubectl get pods -n slurm1 -l job-name=slurm1-populate-jail -w

# Switch to overwrite=false and delete the job
# (use sed -i '' on macOS)
sed -i 's/overwrite: true/overwrite: false/' slurm-cluster-values.yaml
helm upgrade slurm-cluster ~/soperator/helm/slurm-cluster -n slurm1 -f slurm-cluster-values.yaml
kubectl delete job slurm1-populate-jail -n slurm1
```

Wait for all pods to come up:

```bash
kubectl get pods -n slurm1 -w
# Wait until controller-0, login-0, worker-gpu-0, worker-gpu-1 are all 2/2 Running
```

## 11-12. Fix gres.conf, clean spool, restart (combined)

The operator continuously reconciles the gres.conf ConfigMap back to `AutoDetect=nvidia`. You must scale the operator to 0 first, then patch, clean, and restart.

```bash
# Scale operator to 0 to stop reconciliation
kubectl scale deployment soperator-manager -n soperator-system --replicas=0
sleep 10

# Patch gres.conf
kubectl patch configmap slurm1-slurm-configs -n slurm1 --type merge \
  -p '{"data":{"gres.conf":"#Gres config\nName=gpu Type=nvidia File=/dev/nvidia[0-7]"}}'

# Verify
kubectl get configmap slurm1-slurm-configs -n slurm1 -o jsonpath='{.data.gres\.conf}'
# Must show: Name=gpu Type=nvidia File=/dev/nvidia[0-7]

# Clean slurmctld node state
CTRL_NODE=$(kubectl get pod controller-0 -n slurm1 -o jsonpath='{.spec.nodeName}')
kubectl run cleanup-spool --rm -it --restart=Never -n slurm1 \
  --overrides="{\"spec\":{\"nodeName\":\"$CTRL_NODE\",\"containers\":[{\"name\":\"c\",\"image\":\"busybox\",\"command\":[\"sh\",\"-c\",\"rm -f /spool/node_state /spool/node_state.old && echo DONE\"],\"volumeMounts\":[{\"name\":\"s\",\"mountPath\":\"/spool\"}]}],\"volumes\":[{\"name\":\"s\",\"persistentVolumeClaim\":{\"claimName\":\"controller-spool-controller-0\"}}],\"tolerations\":[{\"operator\":\"Exists\"}]}}" \
  --image=busybox

# Delete ALL pods in slurm1 to force clean restart
kubectl delete pods --all -n slurm1 --force

# Wait for controller, set nodes to IDLE
kubectl wait --for=condition=Ready pod/controller-0 -n slurm1 --timeout=300s
kubectl exec controller-0 -n slurm1 -c slurmctld -- scontrol update NodeName=ALL State=IDLE

# Wait for workers (2-3 minutes)
kubectl get pods -n slurm1 -w
# Wait until worker-gpu-0 and worker-gpu-1 are 2/2 Running

# Scale operator back
kubectl scale deployment soperator-manager -n soperator-system --replicas=1

# Verify
kubectl exec controller-0 -n slurm1 -c slurmctld -- sinfo
# Both nodes should show idle
```

## 13. Setup slurm scripts

```bash
# Fix directory ownership
kubectl exec worker-gpu-0 -n slurm1 -c slurmd -- chown 1001:1001 /mnt/jail/opt/slurm_scripts

# Create JailedConfig
kubectl apply -f - <<'EOF'
apiVersion: slurm.nebius.ai/v1alpha1
kind: JailedConfig
metadata:
  name: slurm-scripts
  namespace: slurm1
  labels:
    slurm.nebius.ai/jailed-aggregation: common
spec:
  configMap:
    name: slurm-scripts
  defaultMode: 0o755
  items:
    - {key: prolog.sh, path: /opt/slurm_scripts/prolog.sh}
    - {key: epilog.sh, path: /opt/slurm_scripts/epilog.sh}
    - {key: hc_program.sh, path: /opt/slurm_scripts/hc_program.sh}
    - {key: check_runner.py, path: /opt/slurm_scripts/check_runner.py}
    - {key: checks.json, path: /opt/slurm_scripts/checks.json}
    - {key: pyxis_caching_importer.sh, path: /opt/slurm_scripts/pyxis_caching_importer.sh}
    - {key: boot_disk_full.sh, path: /opt/slurm_scripts/boot_disk_full.sh}
    - {key: chmod_enroot_layers.sh, path: /opt/slurm_scripts/chmod_enroot_layers.sh}
    - {key: cleanup_enroot.sh, path: /opt/slurm_scripts/cleanup_enroot.sh}
    - {key: cleanup_scratch_data.sh, path: /opt/slurm_scripts/cleanup_scratch_data.sh}
    - {key: drop_page_cache.sh, path: /opt/slurm_scripts/drop_page_cache.sh}
    - {key: drop_posix_shmem.sh, path: /opt/slurm_scripts/drop_posix_shmem.sh}
EOF

# Wait for sconfigcontroller to write scripts
kubectl get jailedconfigs -n slurm1 slurm-scripts
# Wait until FILES WRITTEN shows "Success"

# Create symlinks (needed because slurmd looks at /opt/slurm_scripts/ not /mnt/jail/opt/slurm_scripts/)
for w in worker-gpu-0 worker-gpu-1; do
  kubectl exec $w -n slurm1 -c slurmd -- bash -c \
    "ln -sf /mnt/jail/opt/slurm_scripts /opt/slurm_scripts; \
     mkdir -p /mnt/jail/opt/soperator-outputs/slurm_scripts"
done
```

## 14. Verify

```bash
# Reconfigure slurmctld to pick up NodeName entries
kubectl exec controller-0 -n slurm1 -c slurmctld -- scontrol reconfigure

# Check nodes
kubectl exec controller-0 -n slurm1 -c slurmctld -- sinfo -N -l

# Test basic job
kubectl exec login-0 -n slurm1 -c sshd -- chroot /mnt/jail srun hostname

# Test GPU
kubectl exec login-0 -n slurm1 -c sshd -- chroot /mnt/jail srun --gres=gpu:1 nvidia-smi

# Verify RDMA VFs visible
kubectl exec login-0 -n slurm1 -c sshd -- chroot /mnt/jail \
  srun -N2 --gres=gpu:8 --ntasks-per-node=1 ibv_devices
```

## 15. Run NCCL test

Build NCCL tests with MPI (one-time):

```bash
kubectl exec worker-gpu-0 -n slurm1 -c slurmd -- chroot /mnt/jail bash -c "
  export PATH=/usr/local/cuda/bin:/usr/mpi/gcc/openmpi-4.1.7a1/bin:\$PATH
  cd /tmp && git clone https://github.com/NVIDIA/nccl-tests.git
  cd nccl-tests && make MPI=1 MPI_HOME=/usr/mpi/gcc/openmpi-4.1.7a1 CUDA_HOME=/usr/local/cuda NCCL_HOME=/usr -j8
  cp -r build /usr/local/nccl-tests
"
```

Run all_reduce across 2 nodes:

```bash
kubectl exec login-0 -n slurm1 -c sshd -- chroot /mnt/jail \
  srun -N2 --gres=gpu:8 --ntasks-per-node=8 --mpi=pmix \
  --export=ALL,NCCL_IB_HCA=mlx5,NCCL_IB_GID_INDEX=3,NCCL_IB_TC=41,NCCL_IB_SL=0,NCCL_IB_TIMEOUT=22,NCCL_IB_SPLIT_DATA_ON_QPS=0,NCCL_IB_QPS_PER_CONNECTION=4,NCCL_DEBUG=WARN,UCX_TLS=tcp,UCX_NET_DEVICES=eth0 \
  /usr/local/nccl-tests/all_reduce_perf -b 1G -f 2 -g 1 -e 4G -c 1
```

---

## Troubleshooting

**Nodes show `drain` with "Prolog error"**: Check symlinks exist: `kubectl exec worker-gpu-0 -n slurm1 -c slurmd -- ls -la /opt/slurm_scripts/prolog.sh`. If missing, re-run the symlink commands from step 13. If the JailedConfig lacks `defaultMode: 0o755`, scripts will be written without execute permission — add it and re-apply. Then undrain: `kubectl exec controller-0 -n slurm1 -c slurmctld -- scontrol update NodeName=ALL State=IDLE`

**Nodes show `gres/gpu GRES autodetect`**: The operator overwrote gres.conf. Fix sequence: (1) Re-patch gres.conf (step 11), (2) verify it stuck: `kubectl get configmap slurm1-slurm-configs -n slurm1 -o jsonpath='{.data.gres\.conf}'`, (3) clean spool (step 12), (4) restart controller ONLY: `kubectl delete pod controller-0 -n slurm1`, (5) wait for controller: `kubectl wait --for=condition=Ready pod/controller-0 -n slurm1 --timeout=300s`, (6) THEN delete workers: `kubectl delete pod worker-gpu-0 worker-gpu-1 -n slurm1`.

**Workers stuck in `Init:CrashLoopBackOff`**: The worker-init tries `scontrol update state=UNDRAIN` on nodes in DOWN state, which fails. Fix: set nodes to IDLE first (`kubectl exec controller-0 -n slurm1 -c slurmctld -- scontrol update NodeName=ALL State=IDLE`), then workers will succeed on retry. If still stuck, delete the worker pods.

**Worker sandbox fails with `VF pci addr is required`**: Missing VF resource request. Re-run step 9 patch.
