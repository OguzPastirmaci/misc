## Running `ib_write_bw` test using RDMA CM between two nodes in OKE
### 1 - Deploy the RDMA test pods
Apply the following manifest to deploy 2 test pods (`rdma-test-pod-1` & `rdma-test-pod-2`).

> [!IMPORTANT]  
> Below manifest assumes you have all your RDMA enabled nodes in the same cluster network. If you have multiple cluster networks, choose the correct `nodeSelectorTerms` accordingly.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: rdma-test-pod-1
spec:
  hostNetwork: true
  tolerations: [{ operator: "Exists" }]
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
        - matchExpressions:
          - key: node.kubernetes.io/instance-type
            operator: In
            values:
            - BM.GPU.A100-v2.8
            - BM.GPU.B4.8
            - BM.GPU4.8
            - BM.GPU.H100.8
            - BM.Optimized3.36
            - BM.HPC.E5.144
            - BM.HPC2.36
  dnsPolicy: ClusterFirstWithHostNet
  volumes:
  - { name: devinf, hostPath: { path: /dev/infiniband }}
  - { name: shm, emptyDir: { medium: Memory, sizeLimit: 32Gi }}
  restartPolicy: OnFailure
  containers:
  - image: oguzpastirmaci/mofed-perftest:5.4-3.6.8.1-ubuntu20.04-amd64
    name: mofed-test-ctr
    securityContext:
      privileged: true
      capabilities:
        add: [ "IPC_LOCK" ]
    volumeMounts:
    - { mountPath: /dev/infiniband, name: devinf }
    - { mountPath: /dev/shm, name: shm }
    resources:
      requests:
        cpu: 8
        ephemeral-storage: 32Gi
        memory: 2Gi
    command:
    - sh
    - -c
    - |
      ls -l /dev/infiniband /sys/class/net
      sleep 1000000
---
apiVersion: v1
kind: Pod
metadata:
  name: rdma-test-pod-2
spec:
  hostNetwork: true
  tolerations: [{ operator: "Exists" }]
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
        - matchExpressions:
          - key: node.kubernetes.io/instance-type
            operator: In
            values:
            - BM.GPU.A100-v2.8
            - BM.GPU.B4.8
            - BM.GPU4.8
            - BM.GPU.H100.8
            - BM.Optimized3.36
            - BM.HPC.E5.144
            - BM.HPC2.36
  dnsPolicy: ClusterFirstWithHostNet
  volumes:
  - { name: devinf, hostPath: { path: /dev/infiniband }}
  - { name: shm, emptyDir: { medium: Memory, sizeLimit: 32Gi }}
  restartPolicy: OnFailure
  containers:
  - image: oguzpastirmaci/mofed-perftest:5.4-3.6.8.1-ubuntu20.04-amd64
    name: mofed-test-ctr
    securityContext:
      privileged: true
      capabilities:
        add: [ "IPC_LOCK" ]
    volumeMounts:
    - { mountPath: /dev/infiniband, name: devinf }
    - { mountPath: /dev/shm, name: shm }
    resources:
      requests:
        cpu: 8
        ephemeral-storage: 32Gi
        memory: 2Gi
    command:
    - sh
    - -c
    - |
      ls -l /dev/infiniband /sys/class/net
      sleep 1000000
```

```
kubectl get pods

NAME              READY   STATUS    RESTARTS   AGE
rdma-test-pod-1   1/1     Running   0          64m
rdma-test-pod-2   1/1     Running   0          64m
```

### 2 - Exec into the test pods in separate terminals
Exec into the test pods, and run the following commands to run a test with `ib_write_bw` using RDMA CM.

#### rdma-test-pod-1 
We will use this node as the server for `ib_write_bw`.

1 - Get the IP of `rdma0` by running `ip -f inet addr show rdma0 | sed -En -e 's/.*inet ([0-9.]+).*/\1/p'`. Example IP: `10.224.4.233`.
2 - Run the following command to start `ib_write_bw` as server: `ib_write_bw -F -x 3 --report_gbits -R -T 41 -q 4 -d mlx5_5`



