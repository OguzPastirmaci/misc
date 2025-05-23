#### Create a Compute Cluster
Can be done from the console or in python: 

```
import oci
signer = oci.auth.signers.InstancePrincipalsSecurityTokenSigner()
compute_client = oci.core.ComputeClient(config={}, signer=signer)
cc_details=oci.core.models.CreateComputeClusterDetails(compartment_id="ocid1.compartment.oc1..,availability_domain="XXXX:AP-SYDNEY-1-AD-1",display_name=CN_name)
cn = compute_client.create_compute_cluster(create_compute_cluster_details=cc_details).data
cn_id=cn.id
```
#### Permisions: (any-user can be replaced by the group launching the cluster)
```
Allow any-user to use compute-hpc-islands in tenancy	Row with I.D. Allow any-user to use compute-hpc-islands in tenancy
Allow any-user to use compute-network-blocks in tenancy	Row with I.D. Allow any-user to use compute-network-blocks in tenancy
Allow any-user to use compute-local-blocks in tenancy	Row with I.D. Allow any-user to use compute-local-blocks in tenancy
Allow any-user to use compute-bare-metal-hosts in tenancy	Row with I.D. Allow any-user to use compute-bare-metal-hosts in tenancy
Allow any-user to use compute-gpu-memory-fabrics in tenancy	Row with I.D. Allow any-user to use compute-gpu-memory-fabrics in tenancy
```
#### Gather the memory fabric ID
```
import oci
signer = oci.auth.signers.InstancePrincipalsSecurityTokenSigner()
compute_client = oci.core.ComputeClient(config={}, signer=signer)
compute_client.list_compute_gpu_memory_fabrics(compartment_id="ocid1.tenancy.oc1..").data
```
#### Create a Memory Cluster
```
import oci
signer = oci.auth.signers.InstancePrincipalsSecurityTokenSigner()
compute_client = oci.core.ComputeClient(config={}, signer=signer)
details=oci.core.models.CreateComputeGpuMemoryClusterDetails(availability_domain="XXXX:AP-SYDNEY-1-AD-1",compartment_id="ocid1.compartment.oc1..",compute_cluster_id="ocid1.computecluster.oc1.ap-sydney-1.",instance_configuration_id="ocid1.instanceconfiguration.oc1.ap-sydney-1.",size=2,gpu_memory_fabric_id="ocid1.computegpumemoryfabric.oc1.ap-sydney-1.",display_name="memoryFabric1")
output=compute_client.create_compute_gpu_memory_cluster(details)
```
#### Install GPU Operator
```
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
```
helm install nvidia-dra-driver-gpu nvidia/nvidia-dra-driver-gpu \
    --version="25.3.0-rc.2" \
    --create-namespace \
    --namespace nvidia-dra-driver-gpu \
    --set nvidiaDriverRoot=/ \
    --set nvidiaCtkPath=/usr/local/nvidia/toolkit/nvidia-ctk \
    --set resources.gpus.enabled=false \
    -f https://raw.githubusercontent.com/OguzPastirmaci/misc/refs/heads/master/oke-gb200/dra-values.yaml
```

#### Validate that the DRA driver components are running and in a Ready state
```
kubectl get pod -n nvidia-dra-driver-gpu

NAME                                                           READY   STATUS    RESTARTS   AGE
nvidia-dra-driver-k8s-dra-driver-controller-67cb99d84b-5q7kj   1/1     Running   0          7m26s
nvidia-dra-driver-k8s-dra-driver-kubelet-plugin-7kdg9          1/1     Running   0          7m27s
nvidia-dra-driver-k8s-dra-driver-kubelet-plugin-bd6gn          1/1     Running   0          7m27s
nvidia-dra-driver-k8s-dra-driver-kubelet-plugin-bzm6p          1/1     Running   0          7m26s
nvidia-dra-driver-k8s-dra-driver-kubelet-plugin-xjm4p          1/1     Running   0          7m27s
```

#### Confirm that all GPU nodes are labeled with clique ids
```
(echo -e "NODE\tLABEL\tCLIQUE"; kubectl get nodes -o json | \
    jq -r '.items[] | [.metadata.name, "nvidia.com/gpu.clique", .metadata.labels["nvidia.com/gpu.clique"]] | @tsv') | \
    column -t

NODE                 LABEL                  CLIQUE
gb-nvl-043-bianca-1  nvidia.com/gpu.clique  9277d399-0674-44a9-b64e-d85bb19ce2b0.32766
gb-nvl-043-bianca-2  nvidia.com/gpu.clique  9277d399-0674-44a9-b64e-d85bb19ce2b0.32766
```

#### Run a simple test to validate IMEX daemons are started and IMEX channels are injected
```
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
