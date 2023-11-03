#### Get IDs of instances in a cluster network
```sh
oci compute-management cluster-network list-instances --cluster-network-id $CLUSTER_NETWORK_ID -c $COMPARTMENT_ID | jq -r '.data[].id'
```

#### Get GPUs and VFs of BM GPU instances in OKE
```sh
kubectl get nodes -l 'node.kubernetes.io/instance-type in (BM.GPU.H100.8, BM.GPU.A100-v2.8, BM.GPU4.8, BM.GPU.B4.8)' --sort-by=.status.capacity."nvidia\.com/sriov_rdma_vf" -o=custom-columns='NODE:metadata.name,GPUs:status.allocatable.nvidia\.com/gpu,RDMA-VFs:status.allocatable.nvidia\.com/sriov_rdma_vf'
```
