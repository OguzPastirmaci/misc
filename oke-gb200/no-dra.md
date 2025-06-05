> [!IMPORTANT]  
> Do NOT use DRA and the static way explained here at the same time. That will cause your jobs to fail.

### Check if you configured auto creation of channel0
Our new image has this setting, but if you're using an earlier image, it won't have it.

`/etc/modprobe.d/nvidia.conf` should have `options nvidia NVreg_CreateImexChannel0=1`.

If you don't see that line, run:

```
echo "options nvidia NVreg_CreateImexChannel0=1" >> /etc/modprobe.d/nvidia.conf`

systemctl unmask nvidia-imex.service && systemctl enable --now nvidia-imex.service

update-initramfs -u
```

Reboot the node.

### Setup IMEX config
The instructions here are taken from the Slurm example [here](https://docs.nvidia.com/multi-node-nvlink-systems/imex-guide/deployment.html#slurm-scheduler-integration).

```
# Clean the config file in case the service gets started by accident
  > /etc/nvidia-imex/nodes_config.cfg

  NVIDIA_IMEX_START_TIMEOUT=60
  IMEX_CONN_WAIT_TIMEOUT=70
  NVIDIA_IMEX_STOP_TIMEOUT=15

# Clean up prev connection
  timeout $NVIDIA_IMEX_STOP_TIMEOUT systemctl stop nvidia-imex
  pkill -9 nvidia-imex

# Update peer list
# Add the IPs of the nodes that you want to use in channel0 to /etc/nvidia-imex/nodes_config.cfg

# Enable imex-ctl on all nodes so you can query imex status with: nvidia-imex-ctl -a -q
  sed -i "s/IMEX_CMD_PORT.*/IMEX_CMD_PORT=50005/" /etc/nvidia-imex/config.cfg
  sed -i "s/IMEX_CMD_ENABLED.*/IMEX_CMD_ENABLED=1/" /etc/nvidia-imex/config.cfg

# Set timeouts for start
  sed -i "s/IMEX_CONN_WAIT_TIMEOUT.*/IMEX_CONN_WAIT_TIMEOUT=${IMEX_CONN_WAIT_TIMEOUT}/" /etc/nvidia-imex/config.cfg
  timeout $NVIDIA_IMEX_START_TIMEOUT systemctl start nvidia-imex
```

### Running your jobs with the static channel0
Once you followed above steps in all nodes you want to be part of channel0, add `NVIDIA_IMEX_CHANNELS=0` as an env variable.

Example for NCCL tests below with specific nodes in selector.

```yaml
apiVersion: kubeflow.org/v2beta1
kind: MPIJob
metadata:
  name: nccl-test
spec:
  slotsPerWorker: 4
  launcherCreationPolicy: WaitForWorkersReady
  runPolicy:
    cleanPodPolicy: "Running"
  sshAuthMountPath: /root/.ssh
  mpiReplicaSpecs:
    Launcher:
      replicas: 1
      template:
        metadata:
          labels:
            nccl-test-replica: mpi-launcher
        spec:
          hostNetwork: true
          dnsPolicy: ClusterFirstWithHostNet
          containers:
          - name: mpi-launcher
            image: iad.ocir.io/hpc_limited_availability/nccl-tests:pytorch-25.03-nccl-2.26.6-1
            ports:
            - { name: mpijob-port, containerPort: 2222, protocol: TCP }
            command: ["bash", "-c"]
            args:
              - |
                NUM_GPUS=4
                NUM_HOSTS=$(sed -n '$=' /etc/mpi/hostfile)
                NP=$(($NUM_HOSTS*$NUM_GPUS))
                mpirun --allow-run-as-root -mca plm_rsh_args "-p 2222" \
                --bind-to none \
                --map-by ppr:4:node \
                --mca coll ^hcoll \
                -x NCCL_DEBUG=WARN \
                -x NCCL_MNNVL_ENABLE=1 \
                -x NCCL_CUMEM_ENABLE=1 \
                -x NCCL_NET_PLUGIN=sys \
                -x NCCL_IB_HCA=mlx5_0,mlx5_1,mlx5_3,mlx5_4 \
                -x NCCL_NVLS_ENABLE=1 \
                -x NCCL_SOCKET_IFNAME=eth0 \
                -x NVIDIA_IMEX_CHANNELS=0 \
                -np $NP \
                /workspace/nccl-tests/build/all_reduce_perf -b 8 -e 32G -f 2 -g 1
    Worker:
      replicas: 4
      template:
        metadata:
          labels:
            nccl-test-replica: mpi-worker
        spec:
          hostNetwork: true
          dnsPolicy: ClusterFirstWithHostNet
          volumes:
          - { name: devinf, hostPath: { path: /dev/infiniband }}
          - { name: shm, emptyDir: { medium: Memory, sizeLimit: 32Gi }}
          affinity:
            nodeAffinity:
              requiredDuringSchedulingIgnoredDuringExecution:
                nodeSelectorTerms:
                - matchExpressions:
                  - key: kubernetes.io/hostname
                    operator: In
                    values:
                    - 10.140.48.17
                    - 10.140.49.2
                    - 10.140.49.207
                    - 10.140.50.214
          containers:
          - name: mpi-worker
            ports:
            - { name: mpijob-port, containerPort: 2222, protocol: TCP }
            volumeMounts:
            - { mountPath: /dev/infiniband, name: devinf }
            - { mountPath: /dev/shm, name: shm }
            securityContext:
              privileged: true
              capabilities:
                add: ["IPC_LOCK"]
            image: iad.ocir.io/hpc_limited_availability/nccl-tests:pytorch-25.03-nccl-2.26.6-1
            command:
              - /bin/bash
              - -c
              - mkdir -p /var/run/sshd; /usr/sbin/sshd -D -p 2222;
            resources:
              limits:
                nvidia.com/gpu: 4
```
