### Deploying and accessing an OKE cluster

1. Create a new Kubernetes cluster using the Quick Create option in OCI.
https://docs.cloud.oracle.com/en-us/iaas/Content/ContEng/Tasks/contengcreatingclusterusingoke.htm#create-quick-cluster

2. Access the cluster in Cloud Shell. You can access it from your local machine too but Cloud Shell is the easiest/fastest way.

3. In the Cloud Shell, run the following command to see the nodes in your cluster.

```sh
kubectl get nodes
```

You will see an output like below:
```
$ kubectl get nodes
NAME        STATUS   ROLES   AGE   VERSION
10.0.10.5   Ready    node    26h   v1.14.8
10.0.10.6   Ready    node    26h   v1.14.8
10.0.10.7   Ready    node    26h   v1.14.8
```

### Basic example: Deploying a PHP Guestbook application with Redis

We will deploy a simple, multi-tier web application using Kubernetes.

The application consists of:

- A single-instance Redis master to store guestbook entries
- Multiple replicated Redis instances to serve reads
- Multiple web frontend instances
- Objectives

1. We will create the Redis Master Deployment first. 

Here's the YAML file that configures our deployment. This YAML has all the necessary information for deploying the container.



```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: redis-master
  labels:
    app: redis
spec:
  selector:
    matchLabels:
      app: redis
      role: master
      tier: backend
  replicas: 1
  template:
    metadata:
      labels:
        app: redis
        role: master
        tier: backend
    spec:
      containers:
      - name: master
        image: k8s.gcr.io/redis:e2e
        resources:
          requests:
            cpu: 100m
            memory: 100Mi
        ports:
        - containerPort: 6379
```

2. Apply the Redis Master Deployment with the following command:

```sh
kubectl apply -f https://k8s.io/examples/application/guestbook/redis-master-deployment.yaml
```

3. Get the list of pods with the following command:

```sh
kubectl get pods
```

The response will be similar to this:

```sh
$ kubectl get pods
NAME                           READY   STATUS    RESTARTS   AGE
redis-master-596696dd4-f9sdh   1/1     Running   0          81s
```
