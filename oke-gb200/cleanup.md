## Run directly on all GPU nodes in the cluster

```
rm -rf /var/lib/kubelet/plugins/compute-domain.nvidia.com/checkpoint.json 
```

## Run from your local k8s env
```
kubectl delete computedomains.resource.nvidia.com -A --all
kubectl delete daemonsets.apps -A -l resource.nvidia.com/computeDomain
kubectl delete resourceclaimtemplates.resource.k8s.io -A -l resource.nvidia.com/computeDomain
kubectl delete resourceclaims.resource.k8s.io -A -l resource.nvidia.com/computeDomain
```
