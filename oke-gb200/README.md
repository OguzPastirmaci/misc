#### Create a Compute Cluster
Can be done from the console or in python: 

```python
import oci
signer = oci.auth.signers.InstancePrincipalsSecurityTokenSigner()
compute_client = oci.core.ComputeClient(config={}, signer=signer)
cc_details=oci.core.models.CreateComputeClusterDetails(compartment_id="ocid1.compartment.oc1..,availability_domain="XXXX:AP-SYDNEY-1-AD-1",display_name=CN_name)
cn = compute_client.create_compute_cluster(create_compute_cluster_details=cc_details).data
cn_id=cn.id
```
#### Permisions: (any-user can be replaced by the group launching the cluster)

```python
Allow any-user to use compute-hpc-islands in tenancy
Allow any-user to use compute-network-blocks in tenancy
Allow any-user to use compute-local-blocks in tenancy
Allow any-user to use compute-bare-metal-hosts in tenancy
Allow any-user to use compute-gpu-memory-fabrics in tenancy
```
#### Gather the memory fabric ID

```python
import oci
signer = oci.auth.signers.InstancePrincipalsSecurityTokenSigner()
compute_client = oci.core.ComputeClient(config={}, signer=signer)
compute_client.list_compute_gpu_memory_fabrics(compartment_id="ocid1.tenancy.oc1..").data
```

#### Create a Memory Cluster

```python
import oci
signer = oci.auth.signers.InstancePrincipalsSecurityTokenSigner()
compute_client = oci.core.ComputeClient(config={}, signer=signer)
details=oci.core.models.CreateComputeGpuMemoryClusterDetails(availability_domain="XXXX:AP-SYDNEY-1-AD-1",compartment_id="ocid1.compartment.oc1..",compute_cluster_id="ocid1.computecluster.oc1.ap-sydney-1.",instance_configuration_id="ocid1.instanceconfiguration.oc1.ap-sydney-1.",size=2,gpu_memory_fabric_id="ocid1.computegpumemoryfabric.oc1.ap-sydney-1.",display_name="memoryFabric1")
output=compute_client.create_compute_gpu_memory_cluster(details)
```

#### Install GPU Operator
```console
helm repo add nvidia https://helm.ngc.nvidia.com/nvidia
helm repo update

helm install --wait \
  -n gpu-operator --create-namespace \
  gpu-operator nvidia/gpu-operator \
  --version v25.3.0 \
  --set driver.enabled=false \
  --set driver.rdma.enabled=true \
  --set driver.rdma.useHostMofed=true
```

#### Install DRA
```console
helm install nvidia-dra-driver-gpu nvidia/nvidia-dra-driver-gpu \
    --version=25.3.0-rc.2 \
    --create-namespace \
    --namespace nvidia-dra-driver-gpu \
    --set nvidiaDriverRoot=/ \
    --set nvidiaCtkPath=/usr/local/nvidia/toolkit/nvidia-ctk \
    --set resources.gpus.enabled=false \
    -f https://raw.githubusercontent.com/OguzPastirmaci/misc/refs/heads/master/oke-gb200/dra-values.yaml
```

#### Validate that the DRA driver components are running and in a Ready state

```console
kubectl get pod -n nvidia-dra-driver-gpu

NAME                                                           READY   STATUS    RESTARTS   AGE
nvidia-dra-driver-k8s-dra-driver-controller-67cb99d84b-5q7kj   1/1     Running   0          7m26s
nvidia-dra-driver-k8s-dra-driver-kubelet-plugin-7kdg9          1/1     Running   0          7m27s
nvidia-dra-driver-k8s-dra-driver-kubelet-plugin-bd6gn          1/1     Running   0          7m27s
nvidia-dra-driver-k8s-dra-driver-kubelet-plugin-bzm6p          1/1     Running   0          7m26s
nvidia-dra-driver-k8s-dra-driver-kubelet-plugin-xjm4p          1/1     Running   0          7m27s
```

#### Confirm that all GPU nodes are labeled with clique ids

```console
kubectl get nodes -l node.kubernetes.io/instance-type=BM.GPU.GB200.4 -o custom-columns="NODE:.metadata.name,CLIQUE:.metadata.labels.nvidia\.com/gpu\.clique"

NODE            CLIQUE
10.140.61.148   61248eac-4785-4fbf-9cbd-231635e37e9d.20663
10.140.63.103   61248eac-4785-4fbf-9cbd-231635e37e9d.20663
```

#### Run a simple test to validate IMEX daemons are started and IMEX channels are injected

```console
cat <<EOF > imex-channel-injection.yaml
---
apiVersion: resource.nvidia.com/v1beta1
kind: ComputeDomain
metadata:
  name: imex-channel-injection
spec:
  numNodes: 1
  channel:
    resourceClaimTemplate:
      name: imex-channel-0
---
apiVersion: v1
kind: Pod
metadata:
  name: imex-channel-injection
spec:
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
        - matchExpressions:
          - key: nvidia.com/gpu.clique
            operator: Exists
  tolerations:
  - key: "nvidia.com/gpu"
    value: "present"
    operator: "Equal"
    effect: "NoSchedule"
  containers:
  - name: ctr
    image: ubuntu:22.04
    command: ["bash", "-c"]
    args: ["ls -la /dev/nvidia-caps-imex-channels; trap 'exit 0' TERM; sleep 9999 & wait"]
    resources:
      claims:
      - name: imex-channel-0
  resourceClaims:
  - name: imex-channel-0
    resourceClaimTemplateName: imex-channel-0
EOF
```

```console
kubectl apply -f imex-channel-injection.yaml

computedomain.resource.nvidia.com/imex-channel-injection created
pod/imex-channel-injection created
```

```console
kubectl get pods -n nvidia-dra-driver-gpu -l resource.nvidia.com/computeDomain

NAME                                 READY   STATUS    RESTARTS   AGE
imex-channel-injection-vmvtq-h7wls   1/1     Running   0          75s
```

```console
kubectl logs imex-channel-injection

total 0
drwxr-xr-x 2 root root     60 May 24 05:59 .
drwxr-xr-x 6 root root    380 May 24 05:59 ..
crw-rw-rw- 1 root root 234, 0 May 24 05:59 channel0
```

```console
kubectl delete -f imex-channel-injection.yaml

computedomain.resource.nvidia.com "imex-channel-injection" deleted
pod "imex-channel-injection" deleted
```

### RUN NCCL-tests

#### Install MPI Operator
```console
kubectl create -f https://github.com/kubeflow/mpi-operator/releases/download/v0.6.0/mpi-operator.yaml
```

#### Run NCCL-tests
```console
cat <<EOF > nccl-test-job.yaml
---
apiVersion: resource.nvidia.com/v1beta1
kind: ComputeDomain
metadata:
  name: nccl-test-compute-domain
spec:
  numNodes: 2
  channel:
    resourceClaimTemplate:
      name: nccl-test-compute-domain-channel
 
---
apiVersion: kubeflow.org/v2beta1
kind: MPIJob
metadata:
  name: nccl-test
spec:
  slotsPerWorker: 4
  launcherCreationPolicy: WaitForWorkersReady
  runPolicy:
    cleanPodPolicy: Running
  sshAuthMountPath: /root/.ssh
  mpiReplicaSpecs:
    Launcher:
      replicas: 1
      template:
        metadata:
          labels:
            nccl-test-replica: mpi-launcher
        spec:
          containers:
          - name: mpi-launcher
            image: ghcr.io/coreweave/nccl-tests:12.8.1-devel-ubuntu22.04-nccl2.26.2-1-0708d2e
            command: ["bash", "-c"]
            args:
              - |
                mpirun \
                --bind-to none \
                --map-by ppr:4:node \
                --mca coll ^hcoll \
                -x NCCL_DEBUG=INFO \
                -x NCCL_MNNVL_ENABLE=1 \
                -x NCCL_CUMEM_ENABLE=1 \
                -x NCCL_IB_HCA="^mlx5" \
                -x NCCL_NVLS_ENABLE=1 \
                -x NCCL_SOCKET_IFNAME=eth0 \
                -np 8 \
                /opt/nccl-tests/build/all_reduce_perf -b 8 -e 32G -f 2 -g 1
            env:
              - name: OMPI_ALLOW_RUN_AS_ROOT
                value: "1"
              - name: OMPI_ALLOW_RUN_AS_ROOT_CONFIRM
                value: "1"
    Worker:
      replicas: 2
      template:
        metadata:
          labels:
            nccl-test-replica: mpi-worker
        spec:
          affinity:
            podAffinity:
              requiredDuringSchedulingIgnoredDuringExecution:
              - labelSelector:
                  matchExpressions:
                  - key: nccl-test-replica
                    operator: In
                    values:
                    - mpi-worker
                topologyKey: nvidia.com/gpu.clique
          containers:
          - name: mpi-worker
            image: ghcr.io/coreweave/nccl-tests:12.8.1-devel-ubuntu22.04-nccl2.26.2-1-0708d2e
            command: ["/usr/sbin/sshd"]
            args: ["-De"]
            env:
              - name: OMPI_ALLOW_RUN_AS_ROOT
                value: "1"
              - name: OMPI_ALLOW_RUN_AS_ROOT_CONFIRM
                value: "1"
            resources:
              limits:
                nvidia.com/gpu: 4
              claims:
              - name: compute-domain-channel
          resourceClaims:
          - name: compute-domain-channel
            resourceClaimTemplateName: nccl-test-compute-domain-channel
EOF
```


