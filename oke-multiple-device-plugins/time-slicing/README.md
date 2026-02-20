# NVIDIA GPU Split Device Plugin for OKE

Deploys two NVIDIA device plugin instances on the same node to expose different GPU groups as separate Kubernetes resources:

| Resource | GPU(s) | Replicas | Description |
|---|---|---|---|
| `nvidia.com/gpu` | GPU 0 | 1 | Dedicated full GPU, no time-slicing |
| `nvidia.com/gpu.shared` | GPUs 1-3 | 2 per GPU (6 total) | Time-sliced shared GPUs |

Tested on OKE with Ubuntu 24.04, `BM.GPU.A10.4` (4x NVIDIA A10), and `nvidia-device-plugin:v0.18.2`.

## How it works

The NVIDIA device plugin v0.18.2 does not support per-GPU configuration via the `devices` field. The workaround is to run two separate device plugin DaemonSets, each with `NVIDIA_VISIBLE_DEVICES` set to different GPU indices. The NVIDIA container toolkit hook restricts which GPUs each plugin instance can see via NVML.

- **DaemonSet 1** (`nvidia-device-plugin-gpu-full`): Sees only GPU 0, no config file, registers as `nvidia.com/gpu`
- **DaemonSet 2** (`nvidia-device-plugin-gpu-shared`): Sees GPUs 1-3, uses time-slicing config with `renameByDefault: true`, registers as `nvidia.com/gpu.shared`

The two instances use different kubelet device plugin sockets (`nvidia-gpu.sock` and `nvidia-gpu.shared.sock`) so they don't conflict.

## Prerequisites

- OKE cluster with GPU nodes (nodes must have label `nvidia.com/gpu=true`)
- NVIDIA drivers and container toolkit installed on GPU nodes

## Deployment

### 1. Disable the OKE-managed device plugin on GPU nodes

The OKE-managed plugin has `addonmanager.kubernetes.io/mode: Reconcile`, so direct edits get reverted. Disable it in your cluster:

```bash
oci ce cluster disable-addon --addon-name NvidiaGpuPlugin --cluster-id <CLUSTER OCID> --is-remove-existing-add-on true --force
```

Verify the OKE plugin pod is gone:

```bash
kubectl get pods -n kube-system -l k8s-app=nvidia-gpu-device-plugin
```

### 2. Apply the dual device plugin manifest

```bash
kubectl apply -f nvidia-device-plugin-dual.yaml
```

This creates:
- ServiceAccount, ClusterRole, ClusterRoleBinding
- ConfigMap with time-slicing config for GPUs 1-3
- DaemonSet for GPU 0 (dedicated)
- DaemonSet for GPUs 1-3 (time-sliced)

### 3. Verify

Check both pods are running:

```bash
kubectl get pods -n kube-system -l 'app in (nvidia-device-plugin-gpu-full, nvidia-device-plugin-gpu-shared)'
```

Check advertised resources on the GPU node:

```bash
kubectl get node <GPU_NODE_NAME> -o json | jq '.status.capacity | to_entries[] | select(.key | startswith("nvidia"))'
```

Expected output:

```json
{ "key": "nvidia.com/gpu", "value": "1" }
{ "key": "nvidia.com/gpu.shared", "value": "6" }
```

## Testing

Run the two test jobs to verify each device plugin is serving the correct GPUs:

```bash
kubectl apply -f test-gpu-dedicated.yaml -f test-gpu-shared.yaml
```

Wait for completion and check the output:

```bash
kubectl wait --for=condition=complete job/test-gpu-dedicated job/test-gpu-shared --timeout=120s
kubectl logs job/test-gpu-dedicated
kubectl logs job/test-gpu-shared
```

Each job runs `nvidia-smi`. Verify they report different PCI Bus IDs, confirming they were assigned different physical GPUs.

Clean up:

```bash
kubectl delete job test-gpu-dedicated test-gpu-shared
```

**Note:** Pods requesting `nvidia.com/gpu.shared` need an explicit toleration for the `nvidia.com/gpu` taint. Kubernetes only auto-tolerates taints matching the exact requested resource name, so the shared job includes:

```yaml
tolerations:
  - key: nvidia.com/gpu
    operator: Exists
    effect: NoSchedule
```

## Usage in pods

Request the dedicated GPU:

```yaml
resources:
  limits:
    nvidia.com/gpu: 1
```

Request a time-sliced GPU slot (remember to add the `nvidia.com/gpu` toleration):

```yaml
resources:
  limits:
    nvidia.com/gpu.shared: 1
```

## Customization

### Change GPU indices

Edit the `NVIDIA_VISIBLE_DEVICES` env var in each DaemonSet. For example, to make GPUs 0-1 dedicated and GPUs 2-3 shared:

- DaemonSet 1: `NVIDIA_VISIBLE_DEVICES: "0,1"`
- DaemonSet 2: `NVIDIA_VISIBLE_DEVICES: "2,3"`

### Change time-slicing replicas

Edit the `replicas` field in the `nvidia-device-plugin-gpu-shared` ConfigMap. Minimum value is 2.

## Known limitations

- **Minimum replicas**: Time-slicing requires `replicas >= 2`. You cannot set `replicas: 1`.
- **Resource naming**: The only custom name available is `nvidia.com/gpu.shared` (via `renameByDefault: true`). The dedicated GPU must use the default `nvidia.com/gpu`. Custom resource names are not yet supported.
