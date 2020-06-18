1. Create a new Kubernetes cluster using the Quick Create option in OCI.
https://docs.cloud.oracle.com/en-us/iaas/Content/ContEng/Tasks/contengcreatingclusterusingoke.htm#create-quick-cluster

2. Access the cluster in Cloud Shell. You can access it from your local machine too but Cloud Shell is the easiest/fastest way.

3. In the Cloud Shell, run the following command to see the nodes in your cluster.

`kubectl get nodes`

You will see an output like below:
```
$ kubectl get nodes
NAME        STATUS   ROLES   AGE   VERSION
10.0.10.5   Ready    node    26h   v1.14.8
10.0.10.6   Ready    node    26h   v1.14.8
10.0.10.7   Ready    node    26h   v1.14.8
```

