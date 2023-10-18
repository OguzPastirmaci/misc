### Clone the repo
On the operator node, clone the repo.

```
git clone https://github.com/HewlettPackard/lustre-csi-driver.git
```

### Change the Volume Handle
Change the `volumeHandle` in `deploy/kubernetes/base/example_pv.yaml` to the value for your cluster from the previous step where you mounted the share.

For the test cluster use below:

```
volumeHandle: "10.0.6.230@tcp1:/lfsbv"
```

### Deploy the Helm chart

```
cd charts/ && helm install lustre-csi-driver lustre-csi-driver/ --values lustre-csi-driver/values.yaml 
```

### Deploy the PV, PVC, and example pod
```
kubectl apply -f deploy/kubernetes/base/example_pv.yaml
kubectl apply -f deploy/kubernetes/base/example_pvc.yaml
kubectl apply -f deploy/kubernetes/base/example_app.yaml
```

### Exec into the pod to confirm

```
kubectl exec -it app-example -- /bin/ash
 
# When inside the pod
 
touch /mnt/lus/testfile
```
