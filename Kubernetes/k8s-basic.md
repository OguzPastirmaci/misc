Deploying a basic application to Kubernetes
Here's what will do:

Run five instances of a Hello World application.
Create a Service object that exposes an external IP address.
Use the Service object to access the running application.
Let's create a service for an application running in five pods.
Here's the yaml that has everything for the configuration.

You can see that we can set the number of replicas (number of pods to be deployed) with the replicas field in the yaml below.

apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app.kubernetes.io/name: load-balancer-example
  name: hello-world
spec:
  replicas: 5
  selector:
    matchLabels:
      app.kubernetes.io/name: load-balancer-example
  template:
    metadata:
      labels:
        app.kubernetes.io/name: load-balancer-example
    spec:
      containers:
      - image: gcr.io/google-samples/node-hello:1.0
        name: hello-world
        ports:
        - containerPort: 8080
We will apply the yaml above with the following command:
kubectl apply -f https://k8s.io/examples/service/load-balancer-example.yaml
Run the following command to get the status of the deployment:
kubectl get deployment
You should see something similar to this:

$ kubectl get deployment                
NAME          READY   UP-TO-DATE   AVAILABLE   AGE
hello-world   5/5     5            5           55s
This tells us that we have asked for 5 replicas and all of them are up and running.

To see the individual pods that the deployment has, you can type the following command:
kubectl get pods
You should see something similar to this:

$ kubectl get pods
NAME                           READY   STATUS    RESTARTS   AGE
hello-world-7dc74ff97c-89h59   1/1     Running   0          3m36s
hello-world-7dc74ff97c-9zr4j   1/1     Running   0          3m36s
hello-world-7dc74ff97c-c2zq5   1/1     Running   0          3m36s
hello-world-7dc74ff97c-n4tf8   1/1     Running   0          3m36s
hello-world-7dc74ff97c-x4dgt   1/1     Running   0          3m36s
This deployment is not accesible publicly. We need to expose it to make it accessible with the following command.
kubectl expose deployment hello-world --type=LoadBalancer --name=my-service
Notice that they type is LoadBalancer. Because we have an OKE cluster, it know how to talk to OCI APIs to create a load balancer. So Kubernetes will create a load balancer in OCI for us and attach its public IP to our service.

Let see the details of our service. Run:
kubectl get service
The output should be similar to this:

$ kubectl get service
NAME           TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)          AGE
my-service     LoadBalancer   10.96.164.137   <pending>     8080:31178/TCP   8s
The EXTERNAL-IP will be pending for about 30 seconds. We will see a public IP after that. Run the same command again:

kubectl get svc                
NAME         TYPE           CLUSTER-IP      EXTERNAL-IP       PORT(S)          AGE
my-service   LoadBalancer   10.96.164.137   150.136.190.208   8080:31178/TCP   5m15s
Now you have successfully deployed an application and exposed it publicly in Kubernetes.
Open a browser tab and go to the IP that is shown under EXTERNAL-IP and port 8080.

For example:

http://150.136.190.208:8080

You should see a page that says Hello Kubernetes!.
