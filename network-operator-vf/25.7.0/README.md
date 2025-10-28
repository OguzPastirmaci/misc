
### Deploy GPU Operator and Network Operator
```yaml
helm repo add nvidia https://helm.ngc.nvidia.com/nvidia
helm repo update

helm upgrade -i gpu-operator nvidia/gpu-operator \
    --version=v25.3.4 \
    --create-namespace \
    --namespace gpu-operator \
    --set cdi.enabled=true \
    --set driver.enabled=false \
    --set driver.rdma.enabled=true \
    --set driver.rdma.useHostMofed=true \
    --set dcgmExporter.enabled=false \
    --wait

helm upgrade -i network-operator nvidia/network-operator \
  -n nvidia-network-operator \
  --create-namespace \
  --version v25.7.0 \
  --set sriovNetworkOperator.enabled=true \
  --set nfd.enabled=false \
  --wait
```

### Create NicClusterPolicy

```yaml
apiVersion: mellanox.com/v1alpha1
kind: NicClusterPolicy
metadata:
  name: nic-cluster-policy
spec:
  nvIpam:
    image: nvidia-k8s-ipam
    repository: nvcr.io/nvidia/mellanox
    version: network-operator-v25.7.0
    enableWebhook: false
  secondaryNetwork:
    cniPlugins:
      image: plugins
      repository: nvcr.io/nvidia/mellanox
      version: network-operator-v25.7.0
    multus:
      image: multus-cni
      repository: nvcr.io/nvidia/mellanox
      version: network-operator-v25.7.0
```

### Create IPPool for nv-ipam
```yaml
apiVersion: nv-ipam.nvidia.com/v1alpha1
kind: IPPool
metadata:
  name: sriov-pool
  namespace: nvidia-network-operator
spec:
  subnet: 192.168.2.0/24
  perNodeBlockSize: 50
  gateway: 192.168.2.1
```

### Configure SR-IOV
```yaml
apiVersion: sriovnetwork.openshift.io/v1
kind: SriovNetworkNodePolicy
metadata:
  name: bm-gpu-a100-v2-8
  namespace: nvidia-network-operator
spec:
  deviceType: netdevice
  mtu: 4220
  nicSelector:
    rootDevices:
    - 0000:0c:00.0
    - 0000:0c:00.1
    - 0000:16:00.0
    - 0000:16:00.1
    - 0000:47:00.0
    - 0000:47:00.1
    - 0000:4b:00.0
    - 0000:4b:00.1
    - 0000:89:00.0
    - 0000:89:00.1
    - 0000:93:00.0
    - 0000:93:00.1
    - 0000:c3:00.0
    - 0000:c3:00.1
    - 0000:d1:00.0
    - 0000:d1:00.1
    vendor: "15b3"
  nodeSelector:
    node.kubernetes.io/instance-type: "BM.GPU.A100-v2.8"
  isRdma: true
  numVfs: 1
  priority: 90
  resourceName: sriov-rdma-vf
---
apiVersion: sriovnetwork.openshift.io/v1
kind: SriovNetworkNodePolicy
metadata:
  name: bm-gpu-b4-8
  namespace: nvidia-network-operator
spec:
  deviceType: netdevice
  mtu: 4220
  nicSelector:
    rootDevices:
    - 0000:0c:00.0
    - 0000:0c:00.1
    - 0000:16:00.0
    - 0000:16:00.1
    - 0000:47:00.0
    - 0000:47:00.1
    - 0000:4b:00.0
    - 0000:4b:00.1
    - 0000:89:00.0
    - 0000:89:00.1
    - 0000:93:00.0
    - 0000:93:00.1
    - 0000:c3:00.0
    - 0000:c3:00.1
    - 0000:d1:00.0
    - 0000:d1:00.1
    vendor: "15b3"
  nodeSelector:
    node.kubernetes.io/instance-type: "BM.GPU.B4.8"
  isRdma: true
  numVfs: 1
  priority: 90
  resourceName: sriov-rdma-vf
---
apiVersion: sriovnetwork.openshift.io/v1
kind: SriovNetworkNodePolicy
metadata:
  name: bm-gpu-h100-8
  namespace: nvidia-network-operator
spec:
  deviceType: netdevice
  mtu: 4220
  nicSelector:
    rootDevices:
    - 0000:0c:00.0
    - 0000:0c:01.0
    - 0000:16:00.0
    - 0000:16:01.0
    - 0000:48:00.0
    - 0000:48:01.0
    - 0000:4c:00.0
    - 0000:4c:01.0
    - 0000:8a:00.0
    - 0000:8a:01.0
    - 0000:94:00.0
    - 0000:94:01.0
    - 0000:c4:00.0
    - 0000:c4:01.0
    - 0000:d2:00.0
    - 0000:d2:01.0
    vendor: "15b3"
  nodeSelector:
    node.kubernetes.io/instance-type: "BM.GPU.H100.8"
  isRdma: true
  numVfs: 1
  priority: 90
  resourceName: sriov-rdma-vf
---
apiVersion: sriovnetwork.openshift.io/v1
kind: SriovNetworkNodePolicy
metadata:
  name: bm-gpu-h200-8
  namespace: nvidia-network-operator
spec:
  deviceType: netdevice
  mtu: 4220
  nicSelector:
    rootDevices:
    - 0000:0c:00.0
    - 0000:0c:01.0
    - 0000:16:00.0
    - 0000:16:01.0
    - 0000:48:00.0
    - 0000:48:01.0
    - 0000:4c:00.0
    - 0000:4c:01.0
    - 0000:8a:00.0
    - 0000:8a:01.0
    - 0000:94:00.0
    - 0000:94:01.0
    - 0000:c4:00.0
    - 0000:c4:01.0
    - 0000:d2:00.0
    - 0000:d2:01.0
    vendor: "15b3"
  nodeSelector:
    node.kubernetes.io/instance-type: "BM.GPU.H200.8"
  isRdma: true
  numVfs: 1
  priority: 90
  resourceName: sriov-rdma-vf
---
apiVersion: sriovnetwork.openshift.io/v1
kind: SriovNetworkNodePolicy
metadata:
  name: bm-gpu4-8
  namespace: nvidia-network-operator
spec:
  deviceType: netdevice
  mtu: 4220
  nicSelector:
    rootDevices:
    - 0000:0c:00.0
    - 0000:0c:00.1
    - 0000:16:00.0
    - 0000:16:00.1
    - 0000:47:00.0
    - 0000:47:00.1
    - 0000:4b:00.0
    - 0000:4b:00.1
    - 0000:89:00.0
    - 0000:89:00.1
    - 0000:93:00.0
    - 0000:93:00.1
    - 0000:c3:00.0
    - 0000:c3:00.1
    - 0000:d1:00.0
    - 0000:d1:00.1
    vendor: "15b3"
  nodeSelector:
    node.kubernetes.io/instance-type: "BM.GPU4.8"
  isRdma: true
  numVfs: 1
  priority: 90
  resourceName: sriov-rdma-vf

```

### Create SR-IOV Network
```yaml
apiVersion: sriovnetwork.openshift.io/v1
kind: SriovNetwork
metadata:
  name: sriov-rdma-vf
  namespace: nvidia-network-operator
spec:
  resourceName: sriov-rdma-vf
  spoofChk: "off"
  ipam: |
    {
      "type": "nv-ipam",
      "poolName": "sriov-pool"
    }
  metaPlugins: |
    {
      "type": "tuning",
      "sysctl": {
        "net.ipv4.conf.all.arp_announce": "2",
        "net.ipv4.conf.all.arp_filter": "1",
        "net.ipv4.conf.all.arp_ignore": "1",
        "net.ipv4.conf.all.rp_filter": "0",
        "net.ipv4.conf.all.accept_local": "1"
      },
      "mtu": 4220
    },
    {
      "type": "rdma"
    },
    {
      "type": "sbr"
    }
```
