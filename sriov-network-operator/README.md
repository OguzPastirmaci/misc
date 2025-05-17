```
helm install -n sriov-network-operator --create-namespace --version 1.5.0 -f https://raw.githubusercontent.com/OguzPastirmaci/misc/refs/heads/master/sriov-network-operator/BM.Optimized3.36-values.yaml sriov-network-operator oci://ghcr.io/k8snetworkplumbingwg/sriov-network-operator-chart
```

```
kubectl apply -f https://raw.githubusercontent.com/OguzPastirmaci/misc/refs/heads/master/sriov-network-operator/BM.Optimized3.36-policy.yaml
```
