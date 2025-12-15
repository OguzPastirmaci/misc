# Enable lazy image pulling in OKE

Lazy container image loading (sometimes called lazy pulling or on-demand image loading) is a technique that allows a container to start running before the full image is downloaded. Only the parts of the image that are needed at runtime are fetched, reducing startup time—especially for large images.

Normally, when you run a container:
- The container runtime (e.g., crio, containerd) downloads the entire image from the registry.
- It unpacks all image layers.
- Only after all layers are downloaded & unpacked does the container start.

With lazy loading:
- The container starts immediately, using a virtual filesystem (image is not locally present yet).
- When the application accesses a file, the runtime fetches just the required content from the remote registry on-demand.
- Additional files are downloaded only when actually used.

Container images need to be repacked to support lazy loading. Using the [eStargz format](https://github.com/containerd/stargz-snapshotter/blob/main/docs/estargz.md), the image is repacked into small independently decompressible chunks. This allows the container runtime to fetch only the necessary chunks when the container starts.

eStargz images contains a regular file called TOC which records metadata (e.g. name, file type, owners, offset etc) of all file entries in eStargz, except TOC itself. Container runtimes MAY use TOC to mount the container's filesystem without downloading the entire layer contents.

## Prerequisites

1. An OKE cluster. (Required)
2. GPU nodes for testing. (Optional)

## Setup

Considering OKE is using cri-o, we need to setup Stargz Store plugin. This is an implementation of additional layer store plugin of CRI-O/Podman. Stargz Store provides remotely-mounted eStargz layers to CRI-O/Podman.

1. Download the latest version from the [stargz-snapshotter Github page](https://github.com/containerd/stargz-snapshotter).

    ```
    wget https://github.com/containerd/stargz-snapshotter/releases/download/v0.18.1/stargz-snapshotter-v0.18.1-linux-amd64.tar.gz
    ```

2. Extract the `stargz-store` to `/usr/local/bin`.

    ```
    tar -C /usr/local/bin -xvf stargz-snapshotter-v0.18.1-linux-amd64.tar.gz stargz-store
    ```

3. Update the `/etc/containers/storage.conf` file to include `additionallayerstores` in the `[storage.options]` section.

    ```
    [storage]
    driver = "overlay"
    graphroot = "/var/lib/containers/storage"
    runroot = "/run/containers/storage"

    [storage.options]
    additionallayerstores = ["/var/lib/stargz-store/store:ref"]
    ```

4. Ensure `fuse` is installed and loaded.

    ```
    apt-get install fuse
    modprobe fuse
    ```

5. Enable `stargz-store` service.

    ```
    wget -O /etc/systemd/system/stargz-store.service https://raw.githubusercontent.com/containerd/stargz-snapshotter/main/script/config-cri-o/etc/systemd/system/stargz-store.service
    systemctl daemon-reload
    systemctl restart stargz-store crio
    ```

6. Confirm `crio` and `stargz-store` services are running.

    ```
    systemctl status stargz-store
    systemctl status crio
    ```

## Rebuild the container image

1. Create a container repo in OCIR. In our test tenancy with OS namespace `idxzjcdglx2s`, we will create a repo called `vllm/vllm-openai`.

2. Install [docker] and download [nerdctl](https://github.com/containerd/nerdctl) on a Linux machine. (non K8s worker node)

    ```
    wget https://github.com/containerd/nerdctl/releases/download/v2.2.0/nerdctl-2.2.0-linux-amd64.tar.gz
    tar -xf nerdctl-2.2.0-linux-amd64.tar.gz
    ```

3. Convert the image to stargz format.

    ```
    ./nerdctl image convert --estargz --oci docker.io/vllm/vllm-openai:v0.11.0 kix.ocir.io/idxzjcdglx2s/vllm/vllm-openai:v0.11.0-esg
    ```

4. Authenticate to the registry

    ```
    ./nerdctl login kix.ocir.io
    ```

5. Push the image to the registry

    ```
    ./nerdctl image push kix.ocir.io/idxzjcdglx2s/vllm/vllm-openai:v0.11.0-esgz
    ```

6. You can use docker to pull/push the regular image to OCIR using docker.

    ```
    docker image pull docker.io/vllm/vllm-openai:v0.11.0
    docker iamge tag docker.io/vllm/vllm-openai:v0.11.0 kix.ocir.io/idxzjcdglx2s/vllm/vllm-openai:v0.11.0
    docker image push kix.ocir.io/idxzjcdglx2s/vllm/vllm-openai:v0.11.0
    ```

7. Apply the following manifest to the OKE cluster:

    ```
    ---
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: test-estargz
      namespace: default
      labels:
        app: test-estargz
    spec:
      strategy:
        type: Recreate
      replicas: 1
      selector:
        matchLabels:
          app: test-estargz
      template:
        metadata:
          labels:
            app: test-estargz
        spec:
          volumes:
          - name: workspace
            hostPath:
              path: /mnt/nvme/estargz
              type: DirectoryOrCreate
          - name: shm
            emptyDir:
              medium: Memory
              sizeLimit: "20Gi"
          containers:
          - image: kix.ocir.io/idxzjcdglx2s/vllm/vllm-openai:v0.11.0-esgz
            name: test
            args:
            - cpatonn/Qwen3-30B-A3B-Instruct-2507-AWQ-4bit
            - --tensor-parallel-size
            - "1"
            - --max-model-len
            - "8192"
            env:
            - name: HF_HOME
              value: "/workspace"
            resources:
              requests:
                nvidia.com/gpu: 1
              limits:
                nvidia.com/gpu: 1
            securityContext:
              capabilities:
                add:
                - IPC_LOCK
            volumeMounts:
            - mountPath: /workspace/
              name: workspace
            - mountPath: /dev/shm
              name: shm
          # nodeName: 10.140.34.52
          tolerations:
          - key: nvidia.com/gpu
            operator: Exists
            effect: NoSchedule
    ---
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: test-regular
      namespace: default
      labels:
        app: test-regular
    spec:
      strategy:
        type: Recreate
      replicas: 1
      selector:
        matchLabels:
          app: test-regular
      template:
        metadata:
          labels:
            app: test-regular
        spec:
          volumes:
          - name: workspace
            hostPath:
              path: /mnt/nvme/regular
              type: DirectoryOrCreate
          - name: shm
            emptyDir:
              medium: Memory
              sizeLimit: "20Gi"
          containers:
          - image: kix.ocir.io/idxzjcdglx2s/vllm/vllm-openai:v0.11.0-regular
            name: test
            args:
            - cpatonn/Qwen3-30B-A3B-Instruct-2507-AWQ-4bit
            - --max-model-len
            - "8192"
            env:
            - name: HF_HOME
              value: "/workspace"
            resources:
              requests:
                nvidia.com/gpu: 1
              limits:
                nvidia.com/gpu: 1
            securityContext:
              capabilities:
                add:
                - IPC_LOCK
            volumeMounts:
            - mountPath: /workspace/
              name: workspace
            - mountPath: /dev/shm
              name: shm
          # nodeName: 10.140.34.52    
          tolerations:
          - key: nvidia.com/gpu
            operator: Exists
            effect: NoSchedule
    ```

## Test results

1. Pod start time is `33s` for eStargz and `4m` for regular image.

    ```
    $ k get pods -w
    NAME                            READY   STATUS              RESTARTS   AGE
    test-estargz-5699988945-2zxmh   0/1     ContainerCreating   0          8s
    test-regular-55fbdf64c8-hn6hg   0/1     ContainerCreating   0          7s
    test-estargz-5699988945-2zxmh   1/1     Running             0          33s
    test-regular-55fbdf64c8-hn6hg   1/1     Running             0          4m
    ```

2. Application starts on the pod using the eStargz image in `1m27s`.

    ```
    INFO 12-11 07:59:02 [__init__.py:216] Automatically detected platform cuda.
    (APIServer pid=1) INFO 12-11 07:59:26 [api_server.py:1839] vLLM API server version 0.11.0
    (APIServer pid=1) INFO 12-11 07:59:26 [utils.py:233] non-default args: {'model_tag': 'cpatonn/Qwen3-30B-A3B-Instruct-2507-AWQ-4bit', 'max_model_len': 8192, 'enforce_eager': True}
    ...
    (APIServer pid=1) INFO 12-11 08:00:29 [launcher.py:42] Route: /metrics, Methods: GET
    (APIServer pid=1) INFO:     Started server process [1]
    (APIServer pid=1) INFO:     Waiting for application startup.
    (APIServer pid=1) INFO:     Application startup complete.
    ```

3. Application starts on the pod using the regular image in `32s`.

    ```
    INFO 12-11 08:01:19 [__init__.py:216] Automatically detected platform cuda.
    (APIServer pid=1) INFO 12-11 08:01:22 [api_server.py:1839] vLLM API server version 0.11.0
    (APIServer pid=1) INFO 12-11 08:01:22 [utils.py:233] non-default args: {'model_tag': 'cpatonn/Qwen3-30B-A3B-Instruct-2507-AWQ-4bit', 'max_model_len': 8192, 'enforce_eager': True}
    ...
    (APIServer pid=1) INFO 12-11 08:01:51 [launcher.py:42] Route: /metrics, Methods: GET
    (APIServer pid=1) INFO:     Started server process [1]
    (APIServer pid=1) INFO:     Waiting for application startup.
    (APIServer pid=1) INFO:     Application startup complete.
    ```

4. The pod using the eStargz image is ready to serve traffic `1m22s` faster than the regular one.

## Conclusions

The implementation of lazy image pulling using eStargz format in OKE demonstrates significant improvements in pod initialization time, reducing container startup from 4 minutes to just 33 seconds, an 87% reduction. While the application initialization time within the eStargz container takes approximately 1 minute longer than the regular image (1m27s vs 32s), the overall time to ready state is still 1m22s faster, making the pod available for traffic more quickly. This trade-off proves particularly valuable in production environments where rapid scaling, pod rescheduling, or cold starts are critical, as the substantial reduction in initial container pull time outweighs the modest increase in application startup overhead. For workloads using large container images, especially AI workloads, lazy pulling with eStargz offers a practical solution to accelerate deployment without requiring changes to application code or significant infrastructure modifications.

## References

1. https://github.com/containerd/stargz-snapshotter/blob/main/docs/INSTALL.md
2. https://blog.cubieserver.de/2022/experimenting-with-estargz-image-pulling-on-openshift/
3. https://github.com/containerd/nerdctl/blob/main/docs/stargz.md
