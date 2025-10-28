# SR-IOV Network Operator: RDMA Mode Investigation & Configuration Guide

**Repository:** sriov-network-operator  
**Issue:** Understanding node reboots when configuring RDMA mode

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Key Finding: Unnecessary Reboots](#key-finding-unnecessary-reboots)
3. [How RDMA Mode is Configured](#how-rdma-mode-is-configured)
4. [Understanding TotalVfs vs NumVfs](#understanding-totalvfs-vs-numvfs)
5. [Configuration Methods](#configuration-methods)
6. [Ubuntu-Specific Considerations](#ubuntu-specific-considerations)
7. [TotalVfs Configuration](#totalvfs-configuration)
8. [Code References](#code-references)

---

## Executive Summary

### The Problem
When creating a `SriovNetworkPoolConfig` with RDMA mode set to "exclusive", nodes were rebooting even though the RDMA namespace mode was already set to exclusive.

### Root Cause
The SR-IOV Network Operator **does NOT check** the current RDMA mode before reconfiguring it. The `SetRDMASubsystem()` function blindly writes configuration files and updates kernel arguments every time, triggering unnecessary reboots.

### The Fix Needed
The operator should compare current vs desired RDMA mode before making changes.

---

## Key Finding: Unnecessary Reboots

### Current Behavior

The operator flow for RDMA mode configuration:

1. **Status Discovery** (`pkg/daemon/status.go:126`)
   ```go
   nodeState.Status.System.RdmaMode, err = dn.HostHelpers.DiscoverRDMASubsystem()
   ```
   ✅ **DOES** read current RDMA mode via netlink

2. **Configuration** (`pkg/plugins/generic/generic_plugin.go:449-466`)
   ```go
   func (p *GenericPlugin) configRdmaKernelArg(state *sriovnetworkv1.SriovNetworkNodeState) error {
       if state.Spec.System.RdmaMode == "exclusive" {
           p.enableDesiredKernelArgs(consts.KernelArgRdmaExclusive)
           p.disableDesiredKernelArgs(consts.KernelArgRdmaShared)
       }
       return p.helpers.SetRDMASubsystem(state.Spec.System.RdmaMode)
   }
   ```
   ❌ **DOES NOT** compare Spec vs Status before updating

3. **SetRDMASubsystem** (`pkg/host/internal/network/network.go:442-468`)
   ```go
   func (n *network) SetRDMASubsystem(mode string) error {
       // ❌ No check for current mode!
       path := "/host/etc/modprobe.d/sriov_network_operator_modules_config.conf"
       
       config := fmt.Sprintf("options ib_core netns_mode=%d\n", modeValue)
       err := os.WriteFile(path, []byte(config), 0644)
       // Always writes, even if unchanged!
   }
   ```

### The Problem

- The operator reads `Status.System.RdmaMode` correctly via netlink
- But `configRdmaKernelArg()` only looks at `Spec.System.RdmaMode`
- It never compares the two before calling `SetRDMASubsystem()`
- `SetRDMASubsystem()` always writes files and updates kernel args
- This triggers reboot logic even when no change is needed

### Proposed Fix

The `SetRDMASubsystem()` function should check current mode first:

```go
func (n *network) SetRDMASubsystem(mode string) error {
    log.Log.Info("SetRDMASubsystem(): Updating RDMA subsystem mode", "mode", mode)
    
    // Check current RDMA mode
    currentMode, err := n.DiscoverRDMASubsystem()
    if err != nil {
        log.Log.Error(err, "SetRDMASubsystem(): failed to discover current mode")
    } else if currentMode == mode {
        log.Log.Info("SetRDMASubsystem(): RDMA mode already correct, skipping", "mode", mode)
        return nil  // ✅ No change needed!
    }
    
    // ... rest of the configuration ...
}
```

---

## How RDMA Mode is Configured

### What is RDMA Mode?

RDMA (Remote Direct Memory Access) namespace mode controls how RDMA devices are shared:

- **Exclusive** (`netns_mode=0`): RDMA resources bound to single network namespace
- **Shared** (`netns_mode=1`): RDMA resources accessible from multiple namespaces

### How It's Read from the System

The operator uses **netlink** to query the live kernel state:

```go
// pkg/host/internal/network/network.go:431-440
func (n *network) DiscoverRDMASubsystem() (string, error) {
    subsystem, err := n.netlinkLib.RdmaSystemGetNetnsMode()
    return subsystem, nil
}
```

**Netlink** is a Linux kernel interface (socket-based protocol) that allows communication between kernel and userspace. The `RdmaSystemGetNetnsMode()` function:

1. Opens a netlink socket to the kernel's RDMA subsystem
2. Sends `RDMA_NL_GET_NETNS_MODE` request
3. Receives the current `ib_core.netns_mode` value
4. Returns "exclusive" or "shared"

This queries the **live kernel parameter**, NOT config files:
- ✅ `/sys/module/ib_core/parameters/netns_mode` (live)
- ❌ `/etc/modprobe.d/*.conf` (boot-time config)
- ❌ `/proc/cmdline` (boot parameters)

### Kernel Parameter Format

The `netns_mode` parameter is a **boolean**:

| Sysfs Display | Integer Value | Meaning | Mode |
|---------------|---------------|---------|------|
| `N` | 0 | false = don't share | **Exclusive** |
| `Y` | 1 | true = share | **Shared** |

Example:
```bash
$ cat /sys/module/ib_core/parameters/netns_mode
N  # This means exclusive mode (netns_mode=0)
```

### Kernel Arguments Used

```go
// pkg/consts/constants.go:148-149
KernelArgRdmaShared    = "ib_core.netns_mode=1"
KernelArgRdmaExclusive = "ib_core.netns_mode=0"
```

---

## Understanding TotalVfs vs NumVfs

### Why the Operator Uses TotalVfs for Reboot Decisions

**TotalVfs** (firmware-level) vs **NumVfs** (runtime-level):

#### TotalVfs - Firmware Parameter
- **What**: `NUM_OF_VFS` parameter in NIC's NVRAM
- **Scope**: Maximum VF capacity at hardware level
- **Changed via**: `mstconfig` (Mellanox firmware tool)
- **Requires**: Full node reboot
- **Persists**: Across reboots (stored in firmware)

```go
// pkg/vendors/mellanox/mellanox.go:45
TotalVfs = "NUM_OF_VFS"  // Firmware parameter name
```

#### NumVfs - Runtime Parameter
- **What**: Currently active VF count
- **Scope**: Runtime configuration
- **Changed via**: Writing to `/sys/class/net/<device>/device/sriov_numvfs`
- **Requires**: No reboot (hot-pluggable)
- **Persists**: Lost on reboot unless configured in firmware

### Why TotalVfs Determines Reboots

1. **Firmware changes require reboot**: Modifying TotalVfs writes to NIC NVRAM
2. **Dual-port NICs share TotalVfs**: Both ports use the MAX value needed
3. **NumVfs can't exceed TotalVfs**: Firmware sets the upper limit

Example for dual-port Mellanox NIC:
```go
// pkg/vendors/mellanox/mellanox.go:279-287
if isDualPort {
    otherPortPCIAddress := getOtherPortPCIAddress(ifaceSpec.PciAddress)
    otherIfaceSpec, ok := mellanoxNicsSpec[otherPortPCIAddress]
    if ok {
        if otherIfaceSpec.NumVfs > totalVfs {
            totalVfs = otherIfaceSpec.NumVfs  // Use the higher value
        }
    }
}
```

**Scenario:**
- Port 0 needs 10 VFs
- Port 1 needs 20 VFs
- Firmware TotalVfs must be set to **20** (the maximum)
- At runtime, each port creates its VFs independently (up to 20)

---

## Configuration Methods

### Method 1: Using SR-IOV Network Operator (Recommended)

Create a `SriovNetworkPoolConfig`:

```yaml
apiVersion: sriovnetwork.openshift.io/v1
kind: SriovNetworkPoolConfig
metadata:
  name: rdma-exclusive-pool
  namespace: nvidia-network-operator
spec:
  rdmaMode: exclusive  # or "shared"
  nodeSelector:
    matchLabels:
      feature.node.kubernetes.io/pci-15b3.present: "true"
  maxUnavailable: 1
```

**What happens:**
1. Operator writes `/host/etc/modprobe.d/sriov_network_operator_modules_config.conf`
2. Operator adds kernel boot parameter via grubby/rpm-ostree
3. Operator triggers node drain and reboot
4. After reboot, RDMA mode is active

### Method 2: Manual Configuration

#### On Ubuntu 22.04

```bash
# 1. Create modprobe config
sudo tee /etc/modprobe.d/ib_core.conf << EOF
options ib_core netns_mode=0
EOF

# 2. Update GRUB (optional but recommended)
sudo sed -i 's/GRUB_CMDLINE_LINUX="\(.*\)"/GRUB_CMDLINE_LINUX="\1 ib_core.netns_mode=0"/' /etc/default/grub

# 3. Apply changes
sudo update-initramfs -u
sudo update-grub

# 4. Reboot
sudo reboot
```

#### On RHEL/CentOS/Fedora

```bash
# 1. Create modprobe config
echo "options ib_core netns_mode=0" | sudo tee /etc/modprobe.d/ib_core.conf

# 2. Update kernel arguments
sudo grubby --update-kernel=ALL --args="ib_core.netns_mode=0"

# 3. Rebuild initramfs
sudo dracut -f

# 4. Reboot
sudo reboot
```

#### On OSTree-based Systems (CoreOS, RHCOS)

```bash
# Use rpm-ostree
sudo rpm-ostree kargs --append=ib_core.netns_mode=0

# Reboot to apply
sudo systemctl reboot
```

### Method 3: Runtime (Temporary)

Change at runtime (lost on reboot):

```bash
# For exclusive mode
echo 0 | sudo tee /sys/module/ib_core/parameters/netns_mode

# For shared mode
echo 1 | sudo tee /sys/module/ib_core/parameters/netns_mode
```

Or reload modules:
```bash
# Unload RDMA modules
for mod in ib_ipoib ib_umad rdma_ucm mlx5_ib ib_uverbs rdma_cm ib_core; do
  sudo modprobe -r $mod 2>/dev/null || true
done

# Reload with new parameter
sudo modprobe ib_core netns_mode=0
sudo modprobe mlx5_core
sudo modprobe mlx5_ib
```

**⚠️ WARNING**: This disrupts active RDMA connections!

### Verification

```bash
# Check live kernel parameter
cat /sys/module/ib_core/parameters/netns_mode
# N = exclusive (0), Y = shared (1)

# Check kernel command line
cat /proc/cmdline | grep -o "ib_core.netns_mode=[0-1]"

# Check modprobe config
cat /etc/modprobe.d/ib_core.conf

# Check via netlink (what the operator uses)
rdma system show netns
```

---

## Ubuntu-Specific Considerations

### Operator Behavior on Ubuntu

The SR-IOV operator **explicitly skips kernel argument configuration on Ubuntu**:

```bash
# bindata/scripts/kargs.sh:10-16
IS_OS_UBUNTU=true
[[ "$(chroot /host/ grep -i ubuntu /etc/os-release -c)" == "0" ]] && IS_OS_UBUNTU=false

# Kernel args configuration isn't supported for Ubuntu now
if ${IS_OS_UBUNTU} ; then
    echo $ret
    exit 0  # ❌ Exit early on Ubuntu!
fi
```

**What this means:**
- ✅ Operator **WILL** manage `/etc/modprobe.d/` config
- ❌ Operator **WILL NOT** use grubby to update kernel args
- ✅ Operator **WILL** still trigger reboots for RDMA mode changes

### Ubuntu Tools

Ubuntu uses different bootloader management tools:

| Tool | Ubuntu | RHEL/CentOS |
|------|--------|-------------|
| Update GRUB | `update-grub` | `grub2-mkconfig` |
| Kernel args | Manual edit `/etc/default/grub` | `grubby` |
| Initramfs | `update-initramfs` | `dracut` |

### Recommended Ubuntu Configuration

```bash
#!/bin/bash
# Ubuntu RDMA configuration script

MODE=${1:-exclusive}  # exclusive or shared
NETNS_MODE=$([ "$MODE" == "exclusive" ] && echo 0 || echo 1)

echo "Configuring RDMA mode to: $MODE (netns_mode=$NETNS_MODE)"

# Create modprobe config
echo "options ib_core netns_mode=$NETNS_MODE" | sudo tee /etc/modprobe.d/ib_core.conf

# Update GRUB
sudo sed -i "s/GRUB_CMDLINE_LINUX=\"\(.*\)\"/GRUB_CMDLINE_LINUX=\"\1 ib_core.netns_mode=$NETNS_MODE\"/" /etc/default/grub

# Apply changes
sudo update-initramfs -u
sudo update-grub

echo "Configuration complete. Reboot required."
```

---

## TotalVfs Configuration

### Cannot Be Set During Image Building

**TotalVfs is a firmware parameter** that requires:
1. ✅ Physical Mellanox NIC present
2. ✅ PCIe access to the device
3. ✅ `mstconfig` tool
4. ✅ Reboot to apply firmware changes

During image building, the hardware isn't present, so TotalVfs cannot be configured.

### Solution: First-Boot Configuration

#### Option 1: SR-IOV Network Operator (Easiest)

Deploy image, then apply policy:

```yaml
apiVersion: sriovnetwork.openshift.io/v1
kind: SriovNetworkNodePolicy
metadata:
  name: rdma-policy
  namespace: nvidia-network-operator
spec:
  nodeSelector:
    feature.node.kubernetes.io/pci-15b3.present: "true"
  nicSelector:
    vendor: "15b3"
    pfNames: ["rdma0", "rdma1", "rdma2"]  # List all interfaces
  numVfs: 1  # This sets TotalVfs=1 in firmware
  deviceType: netdevice
  isRdma: true
  resourceName: rdma_vfs
```

#### Option 2: First-Boot Systemd Service

Create during image build:

```bash
# Create configuration script
cat > /usr/local/bin/configure-mellanox-sriov.sh << 'EOF'
#!/bin/bash
set -e

MARKER_FILE="/var/lib/mellanox-sriov-configured"

if [ -f "$MARKER_FILE" ]; then
    exit 0  # Already configured
fi

sleep 30  # Wait for devices

# Find Mellanox devices
DEVICES=$(lspci -Dd 15b3: | awk '{print $1}')
[ -z "$DEVICES" ] && exit 0

# Configure firmware
mst start || true
for pci in $DEVICES; do
    mstconfig -y -d "$pci" set SRIOV_EN=1 NUM_OF_VFS=1
done

touch "$MARKER_FILE"
systemctl reboot
EOF
chmod +x /usr/local/bin/configure-mellanox-sriov.sh

# Create systemd service
cat > /etc/systemd/system/mellanox-sriov-firstboot.service << 'EOF'
[Unit]
Description=Configure Mellanox SR-IOV on First Boot
After=network.target
ConditionPathExists=!/var/lib/mellanox-sriov-configured

[Service]
Type=oneshot
ExecStart=/usr/local/bin/configure-mellanox-sriov.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

systemctl enable mellanox-sriov-firstboot.service
```

#### Option 3: Cloud-Init

```yaml
#cloud-config
packages:
  - mstflint

runcmd:
  - mst start
  - |
    for pci in $(lspci -Dd 15b3: | awk '{print $1}'); do
      mstconfig -y -d "$pci" set SRIOV_EN=1 NUM_OF_VFS=1
    done
  - reboot
```

### What CAN Be Pre-configured in Image

```bash
# Install tools
apt-get install -y mstflint rdma-core

# Set RDMA mode
echo "options ib_core netns_mode=0" > /etc/modprobe.d/ib_core.conf

# Configure kernel parameters
sed -i 's/GRUB_CMDLINE_LINUX="\(.*\)"/GRUB_CMDLINE_LINUX="\1 ib_core.netns_mode=0 intel_iommu=on iommu=pt pci=realloc"/' /etc/default/grub
update-grub
update-initramfs -u

# Install automation scripts (see Option 2 above)
```

---

## Code References

### Key Files

1. **RDMA Status Discovery**
   - `pkg/daemon/status.go:126` - Calls DiscoverRDMASubsystem()
   - `pkg/host/internal/network/network.go:431-440` - DiscoverRDMASubsystem implementation
   - `pkg/host/internal/lib/netlink/netlink.go:192-194` - Netlink wrapper

2. **RDMA Configuration**
   - `pkg/plugins/generic/generic_plugin.go:449-466` - configRdmaKernelArg()
   - `pkg/plugins/generic/generic_plugin.go:468-486` - needRebootNode()
   - `pkg/host/internal/network/network.go:442-468` - SetRDMASubsystem()

3. **Kernel Arguments**
   - `pkg/consts/constants.go:148-149` - Kernel arg constants
   - `pkg/plugins/generic/generic_plugin.go:317-349` - syncDesiredKernelArgs()
   - `bindata/scripts/kargs.sh` - Shell script that modifies kernel args

4. **Mellanox TotalVfs**
   - `pkg/vendors/mellanox/mellanox.go:274-314` - mstConfigSetTotalVfs()
   - `pkg/plugins/mellanox/mellanox_plugin.go:43-190` - OnNodeStateChange()

### Important Constants

```go
// pkg/consts/constants.go
RdmaSubsystemModeShared    = "shared"
RdmaSubsystemModeExclusive = "exclusive"
KernelArgRdmaShared        = "ib_core.netns_mode=1"
KernelArgRdmaExclusive     = "ib_core.netns_mode=0"
```

---

## Summary

### Main Takeaways

1. **The Bug**: Operator doesn't check current RDMA mode before reconfiguring, causing unnecessary reboots
2. **TotalVfs vs NumVfs**: TotalVfs is firmware-level (requires reboot), NumVfs is runtime (hot-pluggable)
3. **Netlink**: Used to query live kernel RDMA state, returns "shared" or "exclusive"
4. **Ubuntu**: Operator skips kernel arg management but still handles modprobe.d
5. **Image Building**: Cannot set TotalVfs without hardware; use first-boot scripts or operator
6. **Boolean Display**: `N` = exclusive (0), `Y` = shared (1) in sysfs

### Recommended Practices

1. Use SR-IOV Network Operator for automatic configuration
2. Pre-configure RDMA mode and tools during image build
3. Let first-boot scripts or operator handle TotalVfs after deployment
4. On Ubuntu, manually manage kernel args if needed
5. Always verify configuration with `cat /sys/module/ib_core/parameters/netns_mode`

---

## Related Documentation

- [SR-IOV Network Operator README](README.md)
- [Externally Managed PF Design](doc/design/externally-manage-pf.md)
- [Switchdev Refactoring](doc/design/switchdev-refactoring.md)
- [RDMA Mode Configuration](README.md#rdma-mode-configuration)

---

**Generated:** October 28, 2025  
**Investigation by:** AI Assistant analyzing sriov-network-operator codebase

