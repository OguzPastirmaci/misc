#!/usr/bin/env python3
"""
Improved VF creation script with better error handling and logging.
"""

import os
import sys
import time
import subprocess
from datetime import datetime
from pathlib import Path


def log(message: str):
    """Print timestamped log message."""
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    print(f"[{timestamp}] {message}", file=sys.stderr)


def get_numvfs_path(interface: str) -> Path:
    """Get path to sriov_numvfs for an interface."""
    return Path(f"/sys/class/net/{interface}/device/sriov_numvfs")


def get_totalvfs(interface: str) -> int:
    """Get total number of VFs supported by an interface."""
    totalvfs_path = Path(f"/sys/class/net/{interface}/device/sriov_totalvfs")
    if totalvfs_path.exists():
        return int(totalvfs_path.read_text().strip())
    return 0


def get_vf_dev_name(interface: str, vf_idx: int) -> str | None:
    """Get VF device name for a given interface and VF index."""
    vf_net_path = Path(f"/sys/class/net/{interface}/device/virtfn{vf_idx}/net")
    if vf_net_path.is_dir():
        devices = list(vf_net_path.iterdir())
        if devices:
            return devices[0].name
    return None


def get_eff_mac_addr(interface: str, vf_idx: int) -> str | None:
    """Get effective MAC address for a VF."""
    vf_dev_name = get_vf_dev_name(interface, vf_idx)
    if vf_dev_name:
        addr_path = Path(
            f"/sys/class/net/{interface}/device/virtfn{vf_idx}/net/{vf_dev_name}/address"
        )
        if addr_path.exists():
            return addr_path.read_text().strip()
    return None


def get_vf_pci_addr(interface: str, vf_idx: int) -> str | None:
    """Get PCI address for a VF."""
    vf_dev_name = get_vf_dev_name(interface, vf_idx)
    if vf_dev_name:
        uevent_path = Path(f"/sys/class/net/{vf_dev_name}/device/uevent")
        if uevent_path.exists():
            for line in uevent_path.read_text().splitlines():
                if line.startswith("PCI_SLOT_NAME="):
                    return line.split("=", 1)[1]
    return None


def wait_for_vf(interface: str, vf_idx: int, max_wait: int = 10) -> bool:
    """Wait for a VF to appear."""
    for _ in range(max_wait):
        if get_vf_dev_name(interface, vf_idx):
            return True
        time.sleep(1)
    return False


def write_sysfs(path: Path, value: str) -> bool:
    """Write a value to a sysfs file."""
    try:
        path.write_text(value)
        return True
    except OSError as e:
        log(f"ERROR: Failed to write {value} to {path}: {e}")
        return False


def run_ip_link(args: list[str]) -> bool:
    """Run ip link command."""
    try:
        subprocess.run(["ip", "link"] + args, check=True, capture_output=True)
        return True
    except subprocess.CalledProcessError as e:
        log(f"WARNING: ip link {' '.join(args)} failed: {e}")
        return False


def bind_driver(pci_addr: str, driver: str = "mlx5_core") -> bool:
    """Bind a PCI device to a driver."""
    bind_path = Path(f"/sys/bus/pci/drivers/{driver}/bind")
    try:
        bind_path.write_text(pci_addr)
        return True
    except OSError:
        return False


def unbind_driver(pci_addr: str, driver: str = "mlx5_core") -> bool:
    """Unbind a PCI device from a driver."""
    unbind_path = Path(f"/sys/bus/pci/drivers/{driver}/unbind")
    try:
        unbind_path.write_text(pci_addr)
        return True
    except OSError:
        return False


def create_vfs(interface: str, num_vfs: int) -> bool:
    """Create and configure VFs for an interface."""
    log(f"Creating {num_vfs} VFs for {interface}")
    
    # Validate interface exists
    if not Path(f"/sys/class/net/{interface}").is_dir():
        log(f"ERROR: Interface {interface} does not exist")
        return False
    
    numvfs_path = get_numvfs_path(interface)
    
    if not numvfs_path.exists():
        log(f"ERROR: SRIOV not supported for interface {interface} "
            f"({numvfs_path} not found)")
        return False
    
    # Check max VFs supported
    total_vfs = get_totalvfs(interface)
    if num_vfs > total_vfs:
        log(f"ERROR: Requested {num_vfs} VFs but interface {interface} "
            f"only supports {total_vfs}")
        return False
    
    # Get current number of VFs
    current_num_vfs = int(numvfs_path.read_text().strip())
    
    if current_num_vfs != num_vfs:
        log(f"Creating VFs for {interface} (current: {current_num_vfs}, target: {num_vfs})")
        
        # Reset VFs to 0 first if needed
        if current_num_vfs != 0:
            log("Resetting VFs to 0 first")
            if not write_sysfs(numvfs_path, "0"):
                log(f"ERROR: Failed to reset VFs for {interface}")
                return False
            time.sleep(2)
        
        # Create VFs
        if not write_sysfs(numvfs_path, str(num_vfs)):
            log(f"ERROR: Failed to create {num_vfs} VFs for {interface}")
            return False
        
        # Wait for VFs to be created
        time.sleep(3)
    else:
        log(f"{num_vfs} VFs already created for {interface}")
    
    # Configure the VFs
    for i in range(num_vfs):
        log(f"Configuring VF {i} for {interface}")
        
        # Wait for VF to appear
        if not wait_for_vf(interface, i, max_wait=10):
            log(f"ERROR: VF {i} did not appear for {interface}")
            continue
        
        # Get MAC address
        mac = get_eff_mac_addr(interface, i)
        if not mac:
            log(f"WARNING: Could not get MAC address for VF {i}")
            continue
        
        vf_dev_name = get_vf_dev_name(interface, i)
        log(f"Setting {interface} VF {i} ({vf_dev_name}) MAC to {mac}")
        
        # Set MAC address
        run_ip_link(["set", "dev", interface, "vf", str(i), "mac", mac])
        
        # Rebind VF
        vf_pci_addr = get_vf_pci_addr(interface, i)
        if vf_pci_addr:
            log(f"Rebinding VF {i} PCI device {vf_pci_addr}")
            unbind_driver(vf_pci_addr)
            time.sleep(1)
            bind_driver(vf_pci_addr)
    
    log(f"Successfully configured {num_vfs} VFs for {interface}")
    return True


def main():
    if len(sys.argv) < 2:
        print(f"Usage: {sys.argv[0]} <interface> [num_vfs]", file=sys.stderr)
        sys.exit(1)
    
    interface = sys.argv[1]
    num_vfs = int(sys.argv[2]) if len(sys.argv) > 2 else 1
    
    success = create_vfs(interface, num_vfs)
    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()

