# misc

Personal scratch repo for OCI/OKE scripts, configs, and docs related to GPU and RDMA workloads.

## Structure

```
misc/
├── docs/          # Standalone documentation
│   ├── gpu/       # GPU hardware, RDMA, cluster networks
│   ├── oke/       # OKE operations and configuration
│   ├── oci/       # OCI CLI, instance management
│   └── benchmarks/# Benchmark setup guides (HPL, SPEC)
├── scripts/       # Standalone shell scripts
├── configs/       # Loose config and YAML files
│   ├── gpu-operator/   # NVIDIA GPU Operator Helm values
│   ├── monitoring/     # kube-prometheus-stack, exporters
│   ├── networking/     # Network attachment defs, VF topology
│   └── samples/        # Sample Kubernetes manifests
└── [topic dirs]   # Each topic has its own directory (see below)
```

---

## OKE — Core & Operations

| Directory | Description |
|-----------|-------------|
| [`oke/`](oke/) | Core OKE Terraform configs for RDMA and non-RDMA node pools |
| [`oke-cloud-init/`](oke-cloud-init/) | Cloud-init scripts for OKE node provisioning (Ubuntu 24.04, OL, with image short-name support) |
| [`oke-nvme-provisioner/`](oke-nvme-provisioner/) | NVMe local storage provisioner with RAID, BVR integration, and cloud-init hooks |
| [`oke-extend-boot-volume/`](oke-extend-boot-volume/) | DaemonSet + script to extend OKE node boot volumes at runtime |
| [`oke-self-managed-update/`](oke-self-managed-update/) | Steps for upgrading self-managed OKE node versions |
| [`oke-bvr-self-managed/`](oke-bvr-self-managed/) | Python script for Block Volume Replica management on self-managed OKE clusters |
| [`oke-reboot-bvr/`](oke-reboot-bvr/) | BVR-aware node reboot utilities |
| [`oke-compute-cluster/`](oke-compute-cluster/) | Pointer to the `oci-hpc-oke` Terraform quickstart for deploying OKE clusters |
| [`oke-image-import-temp/`](oke-image-import-temp/) | Terraform for importing custom OCI images |
| [`oke-lazy-image-pull/`](oke-lazy-image-pull/) | Enable lazy (on-demand) container image pulling in OKE to reduce pod startup time |
| [`oke-dind-gpu/`](oke-dind-gpu/) | Docker-in-Docker with GPU support on OKE |
| [`packer/`](packer/) | Packer template for building custom OCI images |

## GPU & RDMA

| Directory | Description |
|-----------|-------------|
| [`oke-gb200/`](oke-gb200/) | GB200 GPU cluster setup on OKE: DRA configuration, NCCL/NVBandwidth test jobs, IMEX channel injection, cloud-init |
| [`gpu-hc/`](gpu-hc/) | GPU health check suite: bandwidth testing, RDMA link flapping detection, Xid error monitoring, NVLink checks |
| [`amd-gpu-operator/`](amd-gpu-operator/) | AMD GPU Operator Helm values and device config for MI300X GPUs on OKE |
| [`oke-gpu-memory-utils/`](oke-gpu-memory-utils/) | Scripts to map GPU cliques and memory hierarchy using OCI instance principal auth |
| [`oke-nccl-scout/`](oke-nccl-scout/) | NCCL communication pattern profiler — runs sequential allreduce tests across hosts to identify slow links |
| [`oke-active-health-checks/`](oke-active-health-checks/) | Active health check framework using NCCL tests as liveness probes |
| [`oke-mps/`](oke-mps/) | GPU Multi-Process Service (MPS) configuration for OKE on Oracle Linux |
| [`oke-multiple-device-plugins/`](oke-multiple-device-plugins/) | Deploy multiple NVIDIA device plugin instances on the same node to expose GPU subsets as separate Kubernetes resources (with time-slicing) |
| [`oke-topology-aware/`](oke-topology-aware/) | Network locality scheduling using RDMA topology labels (Local Block, Network Block, HPC Island). Includes Kueue and Volcano configs |
| [`fw_update/`](fw_update/) | Mellanox/ConnectX firmware update scripts, RoCE TX window configuration, OCI CN auth package installer |
| [`Dockerfile/`](Dockerfile/) | Dockerfiles: RCCL tests (Ubuntu 22.04 + ROCm + OFED variants), Lemur |

## Networking (SR-IOV / VFs)

| Directory | Description |
|-----------|-------------|
| [`network-operator-vf/`](network-operator-vf/) | SR-IOV virtual function setup with NVIDIA Network Operator — host-device and SR-IOV network operator configs, NV-IPAM and Whereabouts IPAM, vf-config scripts (Python + shell) |
| [`sriov-network-operator/`](sriov-network-operator/) | Standalone SR-IOV Network Operator Helm values and SR-IOV policies for BM.GPU.B4.8 and BM.Optimized3.36 |

## Node Management & Problem Detection

| Directory | Description |
|-----------|-------------|
| [`node-role-labeler/`](node-role-labeler/) | DaemonSet + RBAC to apply GPU topology labels to OKE nodes |
| [`npd/`](npd/) | Node Problem Detector Helm values (including AMD GPU variant) and Prometheus alerting rules |
| [`oke-npd/`](oke-npd/) | NPD configuration and deployment manifests for OKE |
| [`npd-cordon/`](npd-cordon/) | NPD extension: automatically cordon nodes when problems are detected |
| [`npd-label-taint/`](npd-label-taint/) | NPD extension: apply labels and taints based on detected node problems |
| [`npd-dr-hpc-v2/`](npd-dr-hpc-v2/) | NPD values tuned for HPC/GPU node recovery workflows |
| [`update-oca/`](update-oca/) | DaemonSet to keep Oracle Cloud Agent up to date across all nodes |
| [`kubectl-plugin/`](kubectl-plugin/) | Custom `kubectl` plugin (Go) that checks node health: GPU status, RDMA state, OCA version |

## Storage

| Directory | Description |
|-----------|-------------|
| [`aistore/`](aistore/) | AIStore distributed object caching setup notes |
| [`aistore-on-oke/`](aistore-on-oke/) | AIStore on OKE with BM.DenseIO.E5.128 NVMe-backed storage |

## HPC Schedulers

| Directory | Description |
|-----------|-------------|
| [`slinky-on-oke/`](slinky-on-oke/) | Slurm on Kubernetes (Slinky) RDMA quickstart — custom Dockerfiles for `slurmctld` and `slurmd` with PMIx and RDMA support |
| [`soperator-on-oke/`](soperator-on-oke/) | Soperator (Slurm operator) on OKE with SR-IOV RDMA |

## Benchmarks & HPC Applications

| Directory | Description |
|-----------|-------------|
| [`openfoam/`](openfoam/) | OpenFOAM CFD installation scripts (Scotch partitioner + OpenFOAM 2.2.2) |
| [`docs/benchmarks/`](docs/benchmarks/) | Setup guides: HPL/Linpack, SPEC CPU 2017, SPEC Storage 2020 |
| [`configs/samples/`](configs/samples/) | Sample Kubernetes manifests: HPL job, parallel job, guestbook |

## Kubernetes Utilities

| Directory | Description |
|-----------|-------------|
| [`Kubernetes/`](Kubernetes/) | Kubectl node scaling scripts, OCI Monitoring integration for autoscaling |
| [`checklimits/`](checklimits/) | Check OCI service limits across regions/ADs |
| [`limits/`](limits/) | Script to list E3 compute and memory limits by region and AD |

## Monitoring

| Directory | Description |
|-----------|-------------|
| [`configs/monitoring/`](configs/monitoring/) | kube-prometheus-stack Helm values, Prometheus exporter test archives |

## Scripts

| Script | Description |
|--------|-------------|
| [`scripts/add_bv_to_self.sh`](scripts/add_bv_to_self.sh) | Attach a block volume to the current instance using instance principal auth |
| [`scripts/add_vnic_to_nodepool.sh`](scripts/add_vnic_to_nodepool.sh) | Add secondary vNICs to an OKE node pool |
| [`scripts/bm_configure_secondary_vnic.sh`](scripts/bm_configure_secondary_vnic.sh) | Configure secondary vNICs on bare metal instances |
| [`scripts/drift.sh`](scripts/drift.sh) | Detect configuration drift on instances |
| [`scripts/instance_pool_scale.sh`](scripts/instance_pool_scale.sh) | Scale an OCI instance pool |
| [`scripts/instance_scale.sh`](scripts/instance_scale.sh) | Scale individual OCI compute instances |
| [`scripts/jq.sh`](scripts/jq.sh) | jq query helpers for OCI JSON responses |
| [`scripts/namd_run.sh`](scripts/namd_run.sh) | Run NAMD molecular dynamics simulation with performance tracking |
| [`scripts/oci_rhel.sh`](scripts/oci_rhel.sh) | Configure RHEL instances on OCI |
| [`scripts/oke-hostname-override.sh`](scripts/oke-hostname-override.sh) | Override hostnames on OKE nodes |
| [`scripts/publish_used_disk_space.sh`](scripts/publish_used_disk_space.sh) | Publish disk usage as an OCI custom metric |
| [`scripts/slurm_nccl.sh`](scripts/slurm_nccl.sh) | SLURM batch script to run NCCL allreduce tests |
| [`scripts/install_gpu_drivers_on_windows.ps1`](scripts/install_gpu_drivers_on_windows.ps1) | Install NVIDIA GPU drivers on Windows instances |

## Documentation

### GPU / RDMA
| File | Description |
|------|-------------|
| [`docs/gpu/BM.GPU.B4.8-CN.md`](docs/gpu/BM.GPU.B4.8-CN.md) | Cluster Network setup for BM.GPU.B4.8 |
| [`docs/gpu/gpu-resize.md`](docs/gpu/gpu-resize.md) | GPU instance resize procedures |
| [`docs/gpu/ib_send_bw.md`](docs/gpu/ib_send_bw.md) | InfiniBand `ib_send_bw` benchmarking |
| [`docs/gpu/nvme_ht.md`](docs/gpu/nvme_ht.md) | NVMe and hyperthreading configuration |
| [`docs/gpu/deepops-ol.md`](docs/gpu/deepops-ol.md) | NVIDIA DeepOps on Oracle Linux |
| [`docs/gpu/ubuntu-cn-gpu.md`](docs/gpu/ubuntu-cn-gpu.md) | Ubuntu cluster network GPU setup |
| [`docs/gpu/ubuntu-nccl_run_allreduce.md`](docs/gpu/ubuntu-nccl_run_allreduce.md) | NCCL allreduce test on Ubuntu bare metal |

### OKE Operations
| File | Description |
|------|-------------|
| [`docs/oke/k8s.md`](docs/oke/k8s.md) | Kubernetes basics and cluster access |
| [`docs/oke/k8s_cmd.md`](docs/oke/k8s_cmd.md) | Kubernetes command reference |
| [`docs/oke/k8s-ubuntu-rdma-oci.md`](docs/oke/k8s-ubuntu-rdma-oci.md) | RDMA setup on Ubuntu OKE nodes |
| [`docs/oke/cluster-resize.md`](docs/oke/cluster-resize.md) | Resize OKE cluster node pools |
| [`docs/oke/boot-volume-higher-performance.md`](docs/oke/boot-volume-higher-performance.md) | Tune boot volume performance |
| [`docs/oke/oke-boot-volume-resize.md`](docs/oke/oke-boot-volume-resize.md) | Resize OKE node boot volumes |
| [`docs/oke/oke-lustre.md`](docs/oke/oke-lustre.md) | Lustre CSI driver on OKE |
| [`docs/oke/oke-fss-skopeo.md`](docs/oke/oke-fss-skopeo.md) | Oracle File Storage Service with Skopeo image mirroring |
| [`docs/oke/oke-replace-flannel-with-cilium.md`](docs/oke/oke-replace-flannel-with-cilium.md) | Replace Flannel CNI with Cilium |
| [`docs/oke/oke-mps-ol.md`](docs/oke/oke-mps-ol.md) | GPU MPS on Oracle Linux OKE nodes |
| [`docs/oke/oke-ib-write-bw.md`](docs/oke/oke-ib-write-bw.md) | InfiniBand write bandwidth test on OKE |
| [`docs/oke/rhck.md`](docs/oke/rhck.md) | Switch OKE nodes to Red Hat Compatible Kernel |
| [`docs/oke/change-ol-kernel-to-rhck.md`](docs/oke/change-ol-kernel-to-rhck.md) | Step-by-step RHCK migration |
| [`docs/oke/update-self-managed-version.md`](docs/oke/update-self-managed-version.md) | Upgrade self-managed Kubernetes node version |
| [`docs/oke/use-all-nvmes.md`](docs/oke/use-all-nvmes.md) | Configure all NVMe devices on a node |
| [`docs/oke/bvr-self-managed-oke.md`](docs/oke/bvr-self-managed-oke.md) | Block Volume Replica on self-managed OKE |

### OCI
| File | Description |
|------|-------------|
| [`docs/oci/oci.md`](docs/oci/oci.md) | General OCI operations reference |
| [`docs/oci/cmd.md`](docs/oci/cmd.md) | OCI CLI commands for GPU instances, cluster networks, volumes |
| [`docs/oci/ocir-helm.md`](docs/oci/ocir-helm.md) | Push and pull Helm charts from Oracle Container Registry |
| [`docs/oci/tagging.md`](docs/oci/tagging.md) | OCI resource tagging strategy |
| [`docs/oci/reboot-instances-in-cn.md`](docs/oci/reboot-instances-in-cn.md) | Reboot instances within a cluster network |
| [`docs/oci/vmdk-import.md`](docs/oci/vmdk-import.md) | Import a VMDK image into OCI |

### Benchmarks
| File | Description |
|------|-------------|
| [`docs/benchmarks/linpack.md`](docs/benchmarks/linpack.md) | HPL/Linpack benchmark setup and run |
| [`docs/benchmarks/speccpu2017.md`](docs/benchmarks/speccpu2017.md) | SPEC CPU 2017 setup |
| [`docs/benchmarks/spec-storage-2020.md`](docs/benchmarks/spec-storage-2020.md) | SPEC Storage 2020 setup |

## Configs

| File | Description |
|------|-------------|
| [`configs/gpu-operator/values.yaml`](configs/gpu-operator/values.yaml) | NVIDIA GPU Operator Helm values |
| [`configs/gpu-operator/23.9.1-to-24.9.20-values.yaml`](configs/gpu-operator/23.9.1-to-24.9.20-values.yaml) | GPU Operator values diff for version migration |
| [`configs/networking/net-attach-def.yaml`](configs/networking/net-attach-def.yaml) | Kubernetes NetworkAttachmentDefinition for multi-NIC pods |
| [`configs/networking/h100-vf-topo.yaml`](configs/networking/h100-vf-topo.yaml) | H100 virtual function topology configuration |
| [`configs/samples/hpl.yaml`](configs/samples/hpl.yaml) | HPL benchmark Kubernetes Job |
| [`configs/samples/hpl-ds.yaml`](configs/samples/hpl-ds.yaml) | HPL benchmark as a DaemonSet |
| [`configs/samples/parallel-job.yaml`](configs/samples/parallel-job.yaml) | Generic parallel Kubernetes Job template |
| [`configs/shapes.json`](configs/shapes.json) | OCI instance shape definitions |
| [`configs/agent-config.json`](configs/agent-config.json) | Oracle Cloud Agent configuration |
| [`configs/stackQuery.json`](configs/stackQuery.json) | OCI Monitoring stack query |
| [`configs/uge.conf`](configs/uge.conf) | Univa Grid Engine configuration |
