1. Build your image with Docker and Nvidia Container Toolkit.

Example:

```Dockerfile
FROM ubuntu:22.04

# Install Docker
RUN apt-get update && \
    apt-get install -y ca-certificates curl gnupg iptables uidmap && \
    install -m 0755 -d /etc/apt/keyrings && \
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg && \
    chmod a+r /etc/apt/keyrings/docker.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
      https://download.docker.com/linux/ubuntu jammy stable" \
      > /etc/apt/sources.list.d/docker.list && \
    apt-get update && \
    apt-get install -y docker-ce docker-ce-cli containerd.io && \
    rm -rf /var/lib/apt/lists/*

# Install Nvidia Container Toolkit (Docker integration)
RUN apt-get update && \
    apt-get install -y gnupg2 && \
    curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit.gpg && \
    curl -fsSL https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list \
      | sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit.gpg] https://#' \
      > /etc/apt/sources.list.d/nvidia-container-toolkit.list && \
    apt-get update && \
    apt-get install -y nvidia-container-toolkit && \
    rm -rf /var/lib/apt/lists/*

# Configure Docker to use Nvidia runtime by default
RUN mkdir -p /etc/docker && \
    printf '{\n  "default-runtime": "nvidia",\n  "runtimes": {\n    "nvidia": {\n      "path": "nvidia-container-runtime",\n      "runtimeArgs": []\n    }\n  }\n}\n' > /etc/docker/daemon.json

EXPOSE 2375
CMD ["dockerd", "--host=unix:///var/run/docker.sock", "--host=tcp://0.0.0.0:2375"]
```

2. Run a pod with the image you built.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: dind-gpu
spec:
  restartPolicy: Never
  securityContext:
    seccompProfile: { type: Unconfined }
  containers:
  - name: dind
    image: iad.ocir.io/hpc_limited_availability/dind:v1
    securityContext:
      privileged: true
      allowPrivilegeEscalation: true
    resources:
      limits:
        nvidia.com/gpu: 1
    env:
      - name: DOCKER_TLS_CERTDIR
        value: ""
    ports:
      - containerPort: 2375
        name: docker
    volumeMounts:
      - name: docker-graph
        mountPath: /var/lib/docker
      - name: dind-tmp
        mountPath: /tmp
  volumes:
    - name: docker-graph
      emptyDir: {}
    - name: dind-tmp
      emptyDir: {}
```

3. Exec into the pod and run `nvidia-smi` inside a container running inside the pod.

```
kubectl exec -it dind-gpu -- bash
```

Then run below commands inside the pod:

```
docker info | grep -i runtime
docker run --rm --gpus all nvidia/cuda:12.4.1-base-ubuntu22.04 nvidia-smi
```

Example output:
```
root@dind-gpu:/# docker info | grep -i runtime
[DEPRECATION NOTICE]: API is accessible on http://0.0.0.0:2375 without encryption.
         Access to the remote API is equivalent to root access on the host. Refer
         to the 'Docker daemon attack surface' section in the documentation for
         more information: https://docs.docker.com/go/attack-surface/
In future versions this will be a hard failure preventing the daemon from starting! Learn more at: https://docs.docker.com/go/api-security/
 Runtimes: runc io.containerd.runc.v2 nvidia
 Default Runtime: nvidia

root@dind-gpu:/# docker run --rm --gpus all nvidia/cuda:12.4.1-base-ubuntu22.04 nvidia-smi
Fri Aug 29 05:02:00 2025
+-----------------------------------------------------------------------------------------+
| NVIDIA-SMI 570.172.08             Driver Version: 570.172.08     CUDA Version: 12.8     |
|-----------------------------------------+------------------------+----------------------+
| GPU  Name                 Persistence-M | Bus-Id          Disp.A | Volatile Uncorr. ECC |
| Fan  Temp   Perf          Pwr:Usage/Cap |           Memory-Usage | GPU-Util  Compute M. |
|                                         |                        |               MIG M. |
|=========================================+========================+======================|
|   0  NVIDIA A10                     On  |   00000000:00:04.0 Off |                    0 |
|  0%   51C    P0             81W /  150W |       0MiB /  23028MiB |      0%      Default |
|                                         |                        |                  N/A |
+-----------------------------------------+------------------------+----------------------+

+-----------------------------------------------------------------------------------------+
| Processes:                                                                              |
|  GPU   GI   CI              PID   Type   Process name                        GPU Memory |
|        ID   ID                                                               Usage      |
|=========================================================================================|
|  No running processes found                                                             |
+-----------------------------------------------------------------------------------------+
root@dind-gpu:/#
```

