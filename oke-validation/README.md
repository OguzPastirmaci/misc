# OKE GPU & RDMA Validation

The steps below are intentionally manual, so that everyone gets hands-on experience with the validation process and understands what each step checks.

In the future, all of these validation steps will be part of the stack and will be automated.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Check that the dedicated pool was created](#check-that-the-dedicated-pool-was-created)
   - [Verify nodes are Ready](#verify-nodes-are-ready)
   - [Verify GPU resources are advertised](#verify-gpu-resources-are-advertised)
3. [Check Node Problem Detector health checks](#check-node-problem-detector-health-checks)
   - [Verify Node Problem Detector is running](#verify-node-problem-detector-is-running)
   - [Check node conditions](#check-node-conditions)
   - [List all nodes with issues](#list-all-nodes-with-issues)
4. [Run GPU Fryer](#run-gpu-fryer)
   - [Set your variables](#set-your-variables)
   - [Deploy GPU Fryer as a DaemonSet](#deploy-gpu-fryer-as-a-daemonset)
   - [Wait for GPU Fryer to complete](#wait-for-gpu-fryer-to-complete)
   - [Check results and label nodes](#check-results-and-label-nodes)
   - [Verify the labels](#verify-the-labels)
   - [Clean up](#clean-up)
5. [Run RVS (ROCm Validation Suite)](#run-rvs-rocm-validation-suite)
   - [Set your variables](#set-your-variables-1)
   - [Deploy RVS as a DaemonSet](#deploy-rvs-as-a-daemonset)
   - [Wait for RVS to complete](#wait-for-rvs-to-complete)
   - [Check results and label nodes](#check-results-and-label-nodes-1)
   - [Verify the labels](#verify-the-labels-1)
   - [Clean up](#clean-up-1)
6. [Run the NCCL/RCCL tests](#run-the-ncclrccl-tests)
   - [Check RDMA local block IDs (rails)](#check-rdma-local-block-ids-rails)
   - [What to look for](#what-to-look-for)
   - [Fix unlabeled nodes](#fix-unlabeled-nodes)
   - [Clean up the labeler](#clean-up-the-labeler)
   - [Deploy MPI Operator and Kueue](#deploy-mpi-operator-and-kueue)
   - [Run the NCCL/RCCL test](#run-the-ncclrccl-test)
   - [Check the NCCL/RCCL test results](#check-the-ncclrccl-test-results)
   - [Clean up the NCCL/RCCL test](#clean-up-the-ncclrccl-test)
7. [Access Grafana and set up notifications](#access-grafana-and-set-up-notifications)
   - [Access Grafana](#access-grafana)
   - [Verify dashboards are loaded](#verify-dashboards-are-loaded)
   - [Verify alert rules are loaded](#verify-alert-rules-are-loaded)
   - [Set up notifications with OCI Notifications Service](#set-up-notifications-with-oci-notifications-service)

## Prerequisites

- `kubectl` configured and pointing at your OKE cluster
- `jq` installed (used for parsing JSON output)
- The GPU node pool is in an **Active** state and nodes have joined the cluster

## Check that the dedicated pool was created

Before running any tests, confirm that the GPU nodes are registered and ready.

### Verify nodes are Ready

Set the shape to match the GPU nodes in your cluster:

```bash
SHAPE=BM.GPU.H100.8
```

List all nodes with that shape:

```bash
kubectl get nodes -l node.kubernetes.io/instance-type=$SHAPE -o wide
```

All nodes should show `Ready` in the `STATUS` column. If any show `NotReady`, the node may still be initializing or has a problem joining the cluster.

### Verify GPU resources are advertised

Pick any GPU node and check that the GPU device plugin is advertising GPUs:

```bash
kubectl get nodes -l node.kubernetes.io/instance-type=$SHAPE \
    -o custom-columns=NAME:.metadata.name,NVIDIA:.status.capacity.'nvidia\.com/gpu',AMD:.status.capacity.'amd\.com/gpu'
```

The output will be similar to:

```
NAME            NVIDIA   AMD
10.140.66.153   8        <none>
10.140.75.240   8        <none>
10.140.87.117   8        <none>
10.140.88.12    8        <none>
10.140.88.182   8        <none>
10.140.92.112   8        <none>
10.140.93.124   8        <none>
10.140.94.172   8        <none>
```

## Check Node Problem Detector health checks

[Node Problem Detector](https://github.com/kubernetes/node-problem-detector) is already deployed on the cluster and runs automated health checks on every GPU node every 5 minutes. Before running any stress tests, check that the nodes are reporting healthy.

The following checks run automatically:

| Check | What it validates |
|-------|-------------------|
| GpuCount | Expected number of GPUs are available |
| GpuEcc | No GPU ECC memory errors |
| GpuRowRemap | No GPU row remapping errors |
| GpuBus | No GPUs have fallen off the bus |
| GpuPcie | PCIe has expected bandwidth |
| GpuFabricMgr | Fabric Manager is running (NVIDIA multi-GPU) |
| GpuBadPages | No AMD GPU bad pages |
| GpuXid | No GPU Xid errors in dmesg |
| NvlinkSpeed | NVLink speeds match expected values |
| DcgmiHealth | DCGMI health check passed (NVIDIA) |
| Rocminfo | rocminfo health check passed (AMD) |
| NodeHasPcieErrors | No PCIe AER errors (correctable, non-fatal, fatal) |
| RdmaLink | All RDMA links are up |
| RdmaLinkFlapping | No RDMA links are flapping |
| RdmaWpaAuth | All RDMA interfaces are authenticated |
| RdmaRttcc | RTTCC is disabled on RDMA interfaces |
| IpAddress | All RDMA interfaces have an IP address |
| OcaVersion | Oracle Cloud Agent version is correct |
| CpuProfile | CPU profile is set to performance |

> **Note:** Not all checks run on every node. RDMA checks only run on nodes deployed in a Cluster Network, and GPU-specific checks depend on the GPU vendor (NVIDIA vs AMD).

### Verify Node Problem Detector is running

```bash
kubectl get pods -l app.kubernetes.io/name=node-problem-detector -o wide
```

You should see one pod per GPU node, all in `Running` state.

### Check node conditions

Pick a GPU node and inspect its conditions:

```bash
kubectl describe node $(kubectl get nodes -l node.kubernetes.io/instance-type=$SHAPE -o jsonpath='{.items[0].metadata.name}') | grep -A2 -E "GpuCount|GpuEcc|GpuRowRemap|GpuBus|GpuPcie|GpuFabricMgr|GpuXid|NvlinkSpeed|DcgmiHealth|Rocminfo|RdmaLink|RdmaLinkFlapping|RdmaWpaAuth|RdmaRttcc|IpAddress|CpuProfile"
```

For a healthy node, every check should show `Status: False` (meaning no issues detected). If any check shows `Status: True`, that node has a problem.

Example of a healthy node:

```
GpuEcc               False     GpuEccHasNoIssues             No ECC issues detected with GPUs
GpuCount             False     GpuCountHasNoIssues           Node has the expected number of GPUs
RdmaLink             False     RdmaLinkHasNoIssues           All RDMA links are up
```

Example of an unhealthy node:

```
GpuCount             True      GpuCountHasIssues             Node has missing GPU(s)
```

### List all nodes with issues

To quickly find all GPU nodes reporting problems:

```bash
kubectl get nodes -o json | jq -r '.items[]
| select (.metadata.labels."nvidia.com/gpu" == "true" or .metadata.labels."amd.com/gpu" == "true")
| { name: .metadata.name, ocid: .spec.providerID, serial: .metadata.labels["oci.oraclecloud.com/host.serial_number"], error: .status.conditions[]
| select(.reason | test("HasIssues$|^Pcie(Correctable|NonFatal|Fatal)$")) | .message }
| "\(.name)\t\(.ocid)\t\(.serial)\t\(.error)"'
```

**What this does:**
- Filters to only GPU nodes (NVIDIA or AMD)
- Finds conditions where the reason ends with `HasIssues` or matches PCIe error patterns
- Prints the node name, instance OCID, host serial number, and error message

If this produces no output, all GPU nodes are healthy. If it does produce output, investigate those nodes before continuing with stress tests. Example:

```
10.140.30.89    ocid1.instance.oc1.ap-melbourne-1.anww...   2210xcr0bv  Node has missing GPU(s)
```

## Run GPU Fryer

[GPU Fryer](https://github.com/huggingface/gpu-fryer) is a stress-testing tool by Hugging Face that hammers every GPU with matrix multiplications to detect thermal throttling and performance issues. It automatically picks the right precision (FP32, BF16, or FP8) based on your GPU model, allocates 95% of GPU memory, and checks that all GPUs perform within a consistent range.

> **Note:** GPU Fryer uses CUDA/CUBLAS and only works on NVIDIA GPUs. For AMD GPU shapes (e.g., `BM.GPU.MI300X.8`), skip this section.

### Set your variables

Set the shape to match the GPU nodes in your cluster. The GPU count is extracted automatically.

```bash
SHAPE=BM.GPU.H100.8
GPU_COUNT=${SHAPE##*.}
```

### Deploy GPU Fryer as a DaemonSet

We use a [DaemonSet](https://kubernetes.io/docs/concepts/workloads/controllers/daemonset/) so GPU Fryer runs once on **every** GPU node simultaneously. The `nodeSelector` ensures it only targets nodes with your chosen shape.

The argument `300` tells GPU Fryer to run for 300 seconds (5 minutes). After the test finishes, `sleep infinity` keeps the pod alive so you can check the logs at your own pace.

Create the manifest file:

```bash
cat <<'EOF' > gpu-fryer.yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: gpu-fryer
  labels:
    app: gpu-fryer
spec:
  selector:
    matchLabels:
      app: gpu-fryer
  template:
    metadata:
      labels:
        app: gpu-fryer
    spec:
      nodeSelector:
        node.kubernetes.io/instance-type: "${SHAPE}"
      tolerations:
        - operator: Exists
      containers:
        - name: gpu-fryer
          image: ghcr.io/huggingface/gpu-fryer:1.2.0
          command: ["/bin/sh", "-c"]
          args: ["gpu-fryer 300; sleep infinity"]
          resources:
            limits:
              nvidia.com/gpu: ${GPU_COUNT}
EOF
```

Replace the variables and apply:

```bash
sed "s/\${SHAPE}/$SHAPE/g; s/\${GPU_COUNT}/$GPU_COUNT/g" gpu-fryer.yaml | kubectl apply -f -
```

**What this does:**
- `nodeSelector` — schedules pods only on nodes with the matching instance type label
- `tolerations` with `operator: Exists` — tolerates any taint on GPU nodes so the pod can be scheduled
- `nvidia.com/gpu: ${GPU_COUNT}` — requests all GPUs on the node so GPU Fryer can test every one
- `sleep infinity` — keeps the container running after the test so logs aren't lost

### Wait for GPU Fryer to complete

First, check that all pods are running:

```bash
kubectl get pods -l app=gpu-fryer -o wide
```

You should see one pod per GPU node, all in `Running` state. Now wait for GPU Fryer to finish (about 5-6 minutes). You can watch the live output of one pod to see what's happening:

```bash
kubectl logs -f $(kubectl get pods -l app=gpu-fryer -o jsonpath='{.items[0].metadata.name}')
```

You'll see output like:
- TFLOPS measurements for each GPU (min, max, deviation)
- Temperature readings
- Throttling status flags

When the test finishes, you'll see either `All GPUs seem healthy` (pass) or an error message about throttling/performance issues (fail).

Press `Ctrl+C` to stop watching the logs once you see the test complete.

### Check results and label nodes

Once all pods have completed (waited at least 6 minutes), run the following loop to check each pod's logs and label the node accordingly:

```bash
for pod in $(kubectl get pods -l app=gpu-fryer -o jsonpath='{.items[*].metadata.name}'); do
  node=$(kubectl get pod "$pod" -o jsonpath='{.spec.nodeName}')
  if kubectl logs "$pod" | grep -q "All GPUs seem healthy"; then
    echo "PASSED: $node"
    kubectl label node "$node" gpu-fryer=passed --overwrite
  else
    echo "FAILED: $node"
    kubectl label node "$node" gpu-fryer=failed --overwrite
  fi
done
```

**What this does:**
- Loops through every GPU Fryer pod
- Finds which node each pod ran on (`spec.nodeName`)
- Searches the pod logs for the success message `All GPUs seem healthy`
- Labels the node with `gpu-fryer=passed` or `gpu-fryer=failed`

### Verify the labels

Check which nodes passed and which failed:

```bash
echo "=== PASSED ==="
kubectl get nodes -l gpu-fryer=passed -o wide

echo ""
echo "=== FAILED ==="
kubectl get nodes -l gpu-fryer=failed -o wide
```

If any nodes failed, check their logs for details on what went wrong:

```bash
# Replace <pod-name> with the pod running on the failed node
kubectl logs <pod-name>
```

Common failure reasons:
- **Thermal throttling** — the GPU is overheating, possibly a cooling issue on the bare-metal host
- **Performance deviation** — one or more GPUs are performing significantly worse than the others (default tolerance is 10%)

### Clean up

Once you've recorded your results, delete everything created by the manifest:

```bash
sed "s/\${SHAPE}/$SHAPE/g; s/\${GPU_COUNT}/$GPU_COUNT/g" gpu-fryer.yaml | kubectl delete -f -
```

## Run RVS (ROCm Validation Suite)

[RVS](https://github.com/ROCm/ROCmValidationSuite) is AMD's GPU validation tool. It runs stress tests (GPU Stress Test / `gst_single`) on each GPU to detect hardware issues and performance problems. This is the AMD equivalent of GPU Fryer.

> **Note:** RVS only works on AMD GPUs (ROCm). For NVIDIA GPU shapes, use [GPU Fryer](#run-gpu-fryer) instead.

### Set your variables

Set the shape to match the AMD GPU nodes in your cluster. The GPU count is extracted automatically.

```bash
SHAPE=BM.GPU.MI300X.8
GPU_COUNT=${SHAPE##*.}
```

### Deploy RVS as a DaemonSet

Create the manifest file. This includes both the ConfigMap (test configuration) and the DaemonSet:

```bash
cat <<'EOF' > rvs-test.yaml
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: rvs-config
data:
  config.json: |
    {
      "TestConfig": {
        "GPU_HEALTH_CHECK": {
          "TestLocationTrigger": {
            "global": {
              "TestParameters": {
                "MANUAL": {
                  "TestCases": [
                    {
                      "Recipe": "gst_single",
                      "Iterations": 1,
                      "StopOnFailure": true,
                      "TimeoutSeconds": 600,
                      "Arguments": "--parallel"
                    }
                  ]
                }
              }
            }
          }
        }
      }
    }
---
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: rvs-test
  labels:
    app: rvs-test
spec:
  selector:
    matchLabels:
      app: rvs-test
  template:
    metadata:
      labels:
        app: rvs-test
    spec:
      nodeSelector:
        node.kubernetes.io/instance-type: "${SHAPE}"
      tolerations:
        - operator: Exists
      volumes:
        - name: config-volume
          configMap:
            name: rvs-config
      containers:
        - name: amd-test-runner
          image: docker.io/rocm/test-runner:v1.4.0
          securityContext:
            privileged: true
          resources:
            limits:
              amd.com/gpu: ${GPU_COUNT}
          volumeMounts:
            - name: config-volume
              mountPath: /etc/test-runner/
          env:
            - name: TEST_TRIGGER
              value: "MANUAL"
            - name: NODE_NAME
              valueFrom:
                fieldRef:
                  fieldPath: spec.nodeName
EOF
```

Replace the variables and apply:

```bash
sed "s/\${SHAPE}/$SHAPE/g; s/\${GPU_COUNT}/$GPU_COUNT/g" rvs-test.yaml | kubectl apply -f -
```

**What this does:**
- **ConfigMap** — configures RVS to run the `gst_single` (GPU Stress Test) recipe once across all GPUs in parallel (`--parallel`), with a 10-minute timeout and stop-on-failure enabled
- `nodeSelector` — schedules pods only on nodes with the matching AMD GPU shape
- `privileged: true` — required for RVS to access GPU hardware directly
- `amd.com/gpu: ${GPU_COUNT}` — requests all AMD GPUs on the node
- The ConfigMap is mounted at `/etc/test-runner/` where the test-runner reads its configuration
- `TEST_TRIGGER: MANUAL` — tells the test-runner to use the MANUAL test case from the config

### Wait for RVS to complete

Check that all pods are running:

```bash
kubectl get pods -l app=rvs-test -o wide
```

You should see one pod per AMD GPU node. The `gst_single` test typically takes about 5-10 minutes. You can watch the live output of one pod:

```bash
kubectl logs -f $(kubectl get pods -l app=rvs-test -o jsonpath='{.items[0].metadata.name}')
```

When the test finishes, look for this line in the output:

```
cmd gst_single [iteration=1, pid=<number>] completed successfully
```

If you see that, the GPUs on that node passed. If the test fails, you'll see error messages about GPU failures or timeouts.

### Check results and label nodes

Once all pods have completed (waited at least 10 minutes), run the following loop to check each pod's logs and label the node:

```bash
for pod in $(kubectl get pods -l app=rvs-test -o jsonpath='{.items[*].metadata.name}'); do
  node=$(kubectl get pod "$pod" -o jsonpath='{.spec.nodeName}')
  if kubectl logs "$pod" --previous 2>/dev/null | grep -qE "cmd gst_single \[iteration=1, pid=[0-9]+\] completed successfully" || \
     kubectl logs "$pod" 2>/dev/null | grep -qE "cmd gst_single \[iteration=1, pid=[0-9]+\] completed successfully"; then
    echo "PASSED: $node"
    kubectl label node "$node" rvs-test=passed --overwrite
  else
    echo "FAILED: $node"
    kubectl label node "$node" rvs-test=failed --overwrite
  fi
done
```

**What this does:**
- Loops through every RVS test pod
- Checks both current and previous container logs (the container may have restarted after completing)
- Searches for the `gst_single completed successfully` message
- Labels the node with `rvs-test=passed` or `rvs-test=failed`

### Verify the labels

```bash
echo "=== PASSED ==="
kubectl get nodes -l rvs-test=passed -o wide

echo ""
echo "=== FAILED ==="
kubectl get nodes -l rvs-test=failed -o wide
```

If any nodes failed, check their logs for details:

```bash
# Replace <pod-name> with the pod running on the failed node
kubectl logs <pod-name>
# If the container restarted, check previous logs
kubectl logs <pod-name> --previous
```

### Clean up

Once you've recorded your results, delete everything created by the manifest:

```bash
sed "s/\${SHAPE}/$SHAPE/g; s/\${GPU_COUNT}/$GPU_COUNT/g" rvs-test.yaml | kubectl delete -f -
```

## Run the NCCL/RCCL tests

### Check RDMA local block IDs (rails)

Before running NCCL/RCCL tests, check how your nodes are grouped into RDMA local blocks. Nodes in the same local block have the lowest latency RDMA connectivity between them. The fewer local blocks you have, the better your cross-node GPU communication will perform.

> **Note:** RDMA topology information in IMDS is only available on nodes in a dedicated pool.

If you haven't already, set your shape variable:

```bash
SHAPE=BM.GPU.H100.8
```

Run the following to see how nodes are distributed across local blocks:

```bash
kubectl get nodes -l node.kubernetes.io/instance-type=$SHAPE -o json \
| jq -r '
  def block: (.metadata.labels["oci.oraclecloud.com/rdma.local_block_id"] // "Not Labeled");

  ["COUNT","RDMA_LOCAL_BLOCK_ID"],
  (
    .items
    | group_by(block)
    | map({id: (.[0] | block), count: length})
    | sort_by(.id)
    | .[]
    | [.count, .id]
  )
  | @tsv
'
```

**What this does:**
- Queries all nodes matching your GPU shape
- Groups them by the `oci.oraclecloud.com/rdma.local_block_id` label that OKE assigns
- Prints a count of nodes per local block

Example output:

```
COUNT   RDMA_LOCAL_BLOCK_ID
4       Not Labeled
14      aafs6jiyveq
19      nan6vvmjjya
16      vgxtxsxroqa
11      zixhxwr7inq
```

### What to look for

- **"Not Labeled" nodes** — These nodes are missing the `rdma.local_block_id` label, likely due to an IMDS issue where OKE couldn't retrieve the metadata. See [Fix unlabeled nodes](#fix-unlabeled-nodes) below before running NCCL tests.
- **Number of local blocks** — More blocks means the capacity team allocated nodes across multiple racks, which potentially increases network hops between nodes, especially for large jobs. In the example above, there are 4 local blocks.

### Fix unlabeled nodes

If any nodes show "Not Labeled" in the output above, the RDMA topology labels were not applied during node registration. This usually happens when OKE fails to reach the IMDS at boot time.

The manifest below deploys a DaemonSet that only targets nodes missing all four RDMA labels. On each unlabeled node, it fetches the RDMA topology data from IMDS and applies the correct labels using `kubectl label`. It then re-checks every 5 minutes to ensure the labels are still present.

Create the manifest file:

```bash
cat <<'EOF' > rdma-topology-labeler.yaml
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: rdma-topology-labeler
  namespace: kube-system
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: rdma-topology-labeler
rules:
  - apiGroups: [""]
    resources: ["nodes"]
    verbs: ["get", "patch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: rdma-topology-labeler
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: rdma-topology-labeler
subjects:
  - kind: ServiceAccount
    name: rdma-topology-labeler
    namespace: kube-system
---
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: rdma-topology-labeler
  namespace: kube-system
  labels:
    app: rdma-topology-labeler
spec:
  selector:
    matchLabels:
      app: rdma-topology-labeler
  template:
    metadata:
      labels:
        app: rdma-topology-labeler
    spec:
      serviceAccountName: rdma-topology-labeler
      hostNetwork: true
      tolerations:
        - operator: Exists
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
              - matchExpressions:
                  - key: oci.oraclecloud.com/rdma.hpc_island_id
                    operator: DoesNotExist
                  - key: oci.oraclecloud.com/rdma.host_id
                    operator: DoesNotExist
                  - key: oci.oraclecloud.com/rdma.local_block_id
                    operator: DoesNotExist
                  - key: oci.oraclecloud.com/rdma.network_block_id
                    operator: DoesNotExist
      containers:
        - name: labeler
          image: docker.io/alpine/k8s:1.34.5
          command: ["/bin/sh", "-c"]
          args:
            - |
              while true; do
                echo "$(date) - Checking RDMA topology labels on $NODE_NAME"

                IMDS="http://169.254.169.254/opc/v2/host/rdmaTopologyData"
                DATA=$(curl -sf -H "Authorization: Bearer Oracle" "$IMDS") || {
                  echo "Failed to fetch IMDS rdmaTopologyData - retrying in 300s"
                  sleep 300
                  continue
                }

                HPC_ISLAND_OCID=$(echo "$DATA"   | jq -r '.customerHPCIslandId')
                HOST_OCID=$(echo "$DATA"         | jq -r '.customerHostId')
                LOCAL_BLOCK_OCID=$(echo "$DATA"  | jq -r '.customerLocalBlock')
                NETWORK_BLOCK_OCID=$(echo "$DATA"| jq -r '.customerNetworkBlock')

                HPC_ISLAND_ID="${HPC_ISLAND_OCID: -11}"
                HOST_ID="${HOST_OCID: -11}"
                LOCAL_BLOCK_ID="${LOCAL_BLOCK_OCID: -11}"
                NETWORK_BLOCK_ID="${NETWORK_BLOCK_OCID: -11}"

                kubectl label node "$NODE_NAME" --overwrite \
                  "oci.oraclecloud.com/rdma.hpc_island_id=$HPC_ISLAND_ID" \
                  "oci.oraclecloud.com/rdma.host_id=$HOST_ID" \
                  "oci.oraclecloud.com/rdma.local_block_id=$LOCAL_BLOCK_ID" \
                  "oci.oraclecloud.com/rdma.network_block_id=$NETWORK_BLOCK_ID"

                echo "Labels applied to $NODE_NAME"
                sleep 300
              done
          env:
            - name: NODE_NAME
              valueFrom:
                fieldRef:
                  fieldPath: spec.nodeName
EOF
```

Apply the manifest:

```bash
kubectl apply -f rdma-topology-labeler.yaml
```

**What this does:**
- Creates a ServiceAccount with permissions to `get` and `patch` nodes
- Deploys a DaemonSet that only schedules on nodes missing all four RDMA topology labels (`DoesNotExist` affinity)
- Uses `hostNetwork` to reach the IMDS endpoint at `169.254.169.254`
- Fetches the RDMA topology data (HPC island, host, local block, network block) and extracts the last 11 characters from the full OCIDs (the same way OKE creates the labels)
- Applies the labels matching OKE's naming convention (`oci.oraclecloud.com/rdma.*`)
- Re-checks every 5 minutes to ensure labels remain applied
- If IMDS is unreachable (e.g., on a non-RDMA node), it retries on the next 5-minute cycle

Wait for the labeler pods to start:

```bash
kubectl get pods -n kube-system -l app=rdma-topology-labeler -o wide
```

All pods should show `Running`. Check the logs to confirm labels were applied:

```bash
for pod in $(kubectl get pods -n kube-system -l app=rdma-topology-labeler -o jsonpath='{.items[*].metadata.name}'); do
  echo "--- $pod ---"
  kubectl logs -n kube-system "$pod" --tail=5
done
```

Now re-run the [local block ID check](#check-rdma-local-block-ids-rails) to verify there are no more "Not Labeled" nodes.

### Clean up the labeler

Once all nodes are labeled, delete the labeler resources:

```bash
kubectl delete -f rdma-topology-labeler.yaml
```

### Deploy MPI Operator and Kueue

[Kueue](https://kueue.sigs.k8s.io/) is a Kubernetes job queueing system and [MPI Operator](https://github.com/kubeflow/mpi-operator) manages MPI jobs on Kubernetes. Both are required to run the NCCL/RCCL tests.

```bash
kubectl apply --server-side -f https://raw.githubusercontent.com/kubeflow/mpi-operator/v0.8.0/deploy/v2beta1/mpi-operator.yaml

helm install kueue oci://registry.k8s.io/kueue/charts/kueue --version="0.16.2" --create-namespace --namespace=kueue-system
```

Verify both are running:

```bash
kubectl get pods -n mpi-operator
kubectl get pods -n kueue-system
```

### Run the NCCL/RCCL test

> **Important:** NCCL/RCCL parameters vary by GPU shape. Also verify that the CUDA major version in the container image matches the CUDA major version installed on the node.

Each shape has a pre-configured manifest with the correct NCCL/RCCL parameters. The manifest URL follows a simple pattern based on your shape name:

For NVIDIA shapes (NCCL):

```bash
kubectl apply -f https://raw.githubusercontent.com/oracle-quickstart/oci-hpc-oke/main/manifests/nccl-tests/kueue/$SHAPE.yaml
```

For AMD shapes (RCCL):

```bash
kubectl apply -f https://raw.githubusercontent.com/oracle-quickstart/oci-hpc-oke/main/manifests/rccl-tests/kueue/$SHAPE.yaml
```

The `$SHAPE` variable you set earlier (e.g., `BM.GPU.H100.8`, `BM.GPU.MI300X.8`) is used directly in the URL. The full list of available manifests can be found in the [oci-hpc-oke repository](https://github.com/oracle-quickstart/oci-hpc-oke/tree/main/manifests).

### Check the NCCL/RCCL test results

The initial container image pull may take some time. Wait for the launcher pod to start:

```bash
kubectl get pods -l training.kubeflow.org/job-name=nccl-test -w
```

Once the launcher pod `nccl-test-launcher-XXXXX` shows `Running`, check the logs:

```bash
kubectl logs -f $(kubectl get pods -l training.kubeflow.org/job-role=launcher -o jsonpath='{.items[0].metadata.name}')
```

Example output for a successful 2-node test (BM.GPU.A100-v2.8):

```
#                                                              out-of-place                       in-place
#       size         count      type   redop    root     time   algbw   busbw #wrong     time   algbw   busbw #wrong
#        (B)    (elements)                               (us)  (GB/s)  (GB/s)            (us)  (GB/s)  (GB/s)
  1073741824     268435456     float     sum      -1    10776   99.64  186.83      0    10781   99.60  186.75      0
  2147483648     536870912     float     sum      -1    21287  100.88  189.15      0    21299  100.82  189.05      0
  4294967296    1073741824     float     sum      -1    42381  101.34  190.02      0    42364  101.38  190.09      0
# Out of bounds values : 0 OK
# Avg bus bandwidth    : 188.648
```

**What to look for:**
- **`busbw` (bus bandwidth)** — this is the effective bandwidth per GPU.
- **`#wrong` column** — should be `0` for all rows. Any non-zero value means data corruption occurred during the test
- **`Out of bounds values : 0 OK`** — confirms no data validation errors

### Clean up the NCCL/RCCL test

```bash
kubectl delete mpijob nccl-test
```

## Access Grafana and set up notifications

The monitoring stack (Prometheus, Grafana, DCGM/AMD exporters) is already deployed on the cluster. This section covers how to access Grafana and configure alert notifications.

### Access Grafana

Port-forward Grafana to your local machine:

```bash
kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80
```

Open http://localhost:3000 in your browser.

**Login credentials:**
- **Username**: `admin`
- **Password**: retrieve it from the Kubernetes secret:

```bash
kubectl get secret -n monitoring kube-prometheus-stack-grafana \
  -o jsonpath="{.data.admin-password}" | base64 --decode ; echo
```

### Verify dashboards are loaded

Once logged in, navigate to **Dashboards** in the left sidebar. You should see two folders:

- **Kubernetes** — API server, CoreDNS, Kubelet, Pods, PVs, Prometheus, Scheduling
- **GPU Nodes** — GPU health, GPU metrics, host metrics, Node Problem Detector, cluster overview

If dashboards are missing, check that the sidecar is picking them up:

```bash
kubectl logs -n monitoring statefulset/kube-prometheus-stack-grafana -c grafana-sc-dashboard
```

### Verify alert rules are loaded

In Grafana, navigate to **Alerting** -> **Alert rules**. You should see rules for GPU health (ECC, bus, Xid, row remap, PCIe), RDMA issues (link, flapping, RTTCC, WPA auth), and node problems (OCA version, CPU profile).

If alert rules are missing:

```bash
kubectl get configmaps -n monitoring -l grafana_alert=1
kubectl logs -n monitoring statefulset/kube-prometheus-stack-grafana -c grafana-sc-alerts
```

### Set up notifications with OCI Notifications Service

The cluster includes an OKE ONS Webhook that forwards Grafana alerts to [OCI Notifications Service (ONS)](https://docs.oracle.com/en-us/iaas/Content/Notification/home.htm), which can deliver them via email, SMS, Slack, or PagerDuty.

#### Verify the webhook is running

```bash
kubectl get pods -n monitoring -l app.kubernetes.io/name=oke-ons-webhook
```

#### Verify the contact point in Grafana

In Grafana, navigate to **Alerting** -> **Contact points**. You should see an `ons-webhook` contact point configured with:

- **Type**: Webhook
- **URL**: `http://oke-ons-webhook/grafana-webhook`
- **HTTP Method**: POST

If it doesn't exist, the alert rules ConfigMap may not have been loaded. Check the sidecar logs above.

#### Create ONS subscriptions

To receive notifications, you need to add subscriptions to the ONS topic in the OCI Console:

1. Navigate to **Developer Services** -> **Application Integration** -> **Notifications**
2. Find the ONS topic used by the cluster (check with your admin or Terraform outputs)
3. Click **Create Subscription** and choose the delivery method:
   - **For POCs** — Choose email. Enter the email address, then confirm the subscription from the email you receive
   - **For production clusters** — Choose Slack. Contact Sam Andaluri to get a Slack alerts channel created using an incoming webhook URL

#### Test the notification pipeline

Send a test alert through the webhook to verify end-to-end delivery:

1. In Grafana, go to **Alerting** -> **Contact points**
2. Click the **Test** button next to the `ons-webhook` contact point
3. Check that the notification arrives at your subscribed endpoint

You can also check the webhook logs to confirm it received and forwarded the alert:

```bash
kubectl logs -n monitoring -l app.kubernetes.io/name=oke-ons-webhook --tail=20
```
