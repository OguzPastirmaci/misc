#!/usr/bin/env python3
"""
VF configuration script using PCI addresses (rootDevices).
More reliable than interface names as PCI addresses are hardware-defined.
"""

import os
import sys
import time
import subprocess
import urllib.request
from pathlib import Path

# Shape configurations from shapes.json
SHAPE_CONFIG = {
    # ConnectX-5 shapes (16 NICs, enp* naming, MTU 4220)
    "BM.GPU4.8": {
        "pci_addresses": [
            "0000:0c:00.0", "0000:0c:00.1", "0000:16:00.0", "0000:16:00.1",
            "0000:48:00.0", "0000:48:00.1", "0000:4c:00.0", "0000:4c:00.1",
            "0000:8a:00.0", "0000:8a:00.1", "0000:94:00.0", "0000:94:00.1",
            "0000:c3:00.0", "0000:c3:00.1", "0000:d1:00.0", "0000:d1:00.1",
        ],
        "mtu": 4220,
    },
    "BM.GPU.B4.8": {
        "pci_addresses": [
            "0000:0c:00.0", "0000:0c:00.1", "0000:16:00.0", "0000:16:00.1",
            "0000:47:00.0", "0000:47:00.1", "0000:4b:00.0", "0000:4b:00.1",
            "0000:89:00.0", "0000:89:00.1", "0000:93:00.0", "0000:93:00.1",
            "0000:c3:00.0", "0000:c3:00.1", "0000:d1:00.0", "0000:d1:00.1",
        ],
        "mtu": 4220,
    },
    "BM.GPU.A100-v2.8": {
        "pci_addresses": [
            "0000:0c:00.0", "0000:0c:00.1", "0000:16:00.0", "0000:16:00.1",
            "0000:47:00.0", "0000:47:00.1", "0000:4b:00.0", "0000:4b:00.1",
            "0000:89:00.0", "0000:89:00.1", "0000:93:00.0", "0000:93:00.1",
            "0000:c3:00.0", "0000:c3:00.1", "0000:d1:00.0", "0000:d1:00.1",
        ],
        "mtu": 4220,
    },
    "BM.GPU.GM4.8": {
        "pci_addresses": [
            "0000:0c:00.0", "0000:0c:00.1", "0000:16:00.0", "0000:16:00.1",
            "0000:47:00.0", "0000:47:00.1", "0000:4b:00.0", "0000:4b:00.1",
            "0000:89:00.0", "0000:89:00.1", "0000:93:00.0", "0000:93:00.1",
            "0000:c3:00.0", "0000:c3:00.1", "0000:d1:00.0", "0000:d1:00.1",
        ],
        "mtu": 4220,
    },
    # ConnectX-7 shapes (16 NICs, rdma*/eth* naming, MTU 4220)
    "BM.GPU.H100.8": {
        "pci_addresses": [
            "0000:0c:00.0", "0000:0c:00.1", "0000:2a:00.0", "0000:2a:00.1",
            "0000:41:00.0", "0000:41:00.1", "0000:58:00.0", "0000:58:00.1",
            "0000:86:00.0", "0000:86:00.1", "0000:a5:00.0", "0000:a5:00.1",
            "0000:bd:00.0", "0000:bd:00.1", "0000:d5:00.0", "0000:d5:00.1",
        ],
        "mtu": 4220,
    },
    "BM.GPU.H100T.8": {
        "pci_addresses": [
            "0000:0c:00.0", "0000:0c:00.1", "0000:2a:00.0", "0000:2a:00.1",
            "0000:41:00.0", "0000:41:00.1", "0000:58:00.0", "0000:58:00.1",
            "0000:86:00.0", "0000:86:00.1", "0000:a5:00.0", "0000:a5:00.1",
            "0000:bd:00.0", "0000:bd:00.1", "0000:d5:00.0", "0000:d5:00.1",
        ],
        "mtu": 4220,
    },
    # ConnectX-7 shapes (8 NICs, rdma* naming, MTU 4220)
    "BM.GPU.H200.8": {
        "pci_addresses": [
            "0000:0c:00.0", "0000:2a:00.0", "0000:41:00.0", "0000:58:00.0",
            "0000:86:00.0", "0000:a5:00.0", "0000:bd:00.0", "0000:d5:00.0",
        ],
        "mtu": 4220,
    },
    "BM.GPU.H200-NC.8": {
        "pci_addresses": [
            "0000:0c:00.0", "0000:2a:00.0", "0000:41:00.0", "0000:58:00.0",
            "0000:86:00.0", "0000:a5:00.0", "0000:bd:00.0", "0000:d5:00.0",
        ],
        "mtu": 4220,
    },
    "BM.GPU.B200.8": {
        "pci_addresses": [
            "0000:0c:00.0", "0000:2a:00.0", "0000:41:00.0", "0000:58:00.0",
            "0000:86:00.0", "0000:a5:00.0", "0000:bd:00.0", "0000:d5:00.0",
        ],
        "mtu": 4220,
    },
    # ConnectX-7 shapes (2 NICs, rdma* naming, MTU 4220)
    "BM.GPU.L40S.4": {
        "pci_addresses": ["0000:27:00.0", "0000:97:00.0"],
        "mtu": 4220,
    },
    "BM.GPU.L40S-NC.4": {
        "pci_addresses": ["0000:27:00.0", "0000:97:00.0"],
        "mtu": 4220,
    },
    # ConnectX-7 shapes (8 NICs, enp*np0 naming, MTU 4220)
    "BM.GPU.MI300X.8": {
        "pci_addresses": [
            "0000:0c:00.0", "0000:2a:00.0", "0000:41:00.0", "0000:58:00.0",
            "0000:86:00.0", "0000:a5:00.0", "0000:bd:00.0", "0000:d5:00.0",
        ],
        "mtu": 4220,
    },
    "BM.GPU.MI355X-v1.8": {
        "pci_addresses": [
            "0000:6d:00.0", "0000:05:00.0", "0000:55:00.0", "0000:1e:00.0",
            "0000:ec:00.0", "0000:86:00.0", "0000:d4:00.0", "0000:9f:00.0",
        ],
        "mtu": 4220,
    },
    # ConnectX-7 shapes (4 NICs, rdma* naming, MTU 4220)
    "BM.GPU.GB200.4": {
        "pci_addresses": [
            "0000:03:00.0", "0002:03:00.0", "0010:03:00.0", "0012:03:00.0",
        ],
        "mtu": 4220,
    },
    "BM.GPU.GB200-v2.4": {
        "pci_addresses": [
            "0000:03:00.0", "0002:03:00.0", "0010:03:00.0", "0012:03:00.0",
        ],
        "mtu": 4220,
    },
    # ConnectX-8 shapes (8 NICs, rdma* naming, MTU 9000)
    "BM.GPU.GB200-v3.4": {
        "pci_addresses": [
            "0000:03:00.0", "0000:03:00.1", "0002:03:00.0", "0002:03:00.1",
            "0010:03:00.0", "0010:03:00.1", "0012:03:00.0", "0012:03:00.1",
        ],
        "mtu": 9000,
    },
    "BM.GPU.GB300.4": {
        "pci_addresses": [
            "0000:03:00.0", "0000:03:00.1", "0002:03:00.0", "0002:03:00.1",
            "0010:03:00.0", "0010:03:00.1", "0012:03:00.0", "0012:03:00.1",
        ],
        "mtu": 9000,
    },
}


def get_interface_from_pci(pci_addr: str) -> str | None:
    """Get network interface name from PCI address."""
    net_path = Path(f"/sys/bus/pci/devices/{pci_addr}/net")
    if net_path.is_dir():
        interfaces = list(net_path.iterdir())
        if interfaces:
            return interfaces[0].name
    return None


def get_shape_with_retry(max_time: int = 300, interval: int = 15) -> str | None:
    """Detect shape from OCI metadata with retry."""
    start_time = time.time()
    
    while True:
        try:
            req = urllib.request.Request(
                "http://169.254.169.254/opc/v2/instance/shape",
                headers={"Authorization": "Bearer Oracle"}
            )
            with urllib.request.urlopen(req, timeout=10) as response:
                shape = response.read().decode().strip()
                if shape:
                    return shape
        except Exception:
            pass
        
        elapsed = time.time() - start_time
        if elapsed >= max_time:
            print(f"Warning: Unable to detect shape after {max_time}s", file=sys.stderr)
            return None
        
        print(f"Metadata service not responding, retrying in {interval}s... "
              f"(elapsed: {int(elapsed)}s/{max_time}s)", file=sys.stderr)
        time.sleep(interval)


def discover_rdma_interfaces() -> list[str]:
    """Discover rdma* interfaces as fallback."""
    interfaces = []
    net_path = Path("/sys/class/net")
    for iface in sorted(net_path.iterdir()):
        name = iface.name
        if name.startswith("rdma") and "v" not in name:
            interfaces.append(name)
    return interfaces


def create_vfs(interface: str, num_vfs: int) -> bool:
    """Create VFs for an interface using oci-create-vfs."""
    # Try multiple possible locations for the script
    possible_paths = [
        Path(__file__).parent / "oci-create-vfs.py",  # Same directory
        Path("/tmp/oci-create-vfs.py"),                # When running in chroot
        Path("/scripts/oci-create-vfs.py"),            # ConfigMap mount
    ]
    
    for script_path in possible_paths:
        if script_path.exists():
            cmd = [sys.executable, str(script_path), interface, str(num_vfs)]
            break
    else:
        # Fallback to PATH
        cmd = ["oci-create-vfs", interface, str(num_vfs)]
    
    try:
        subprocess.run(cmd, check=True)
        return True
    except subprocess.CalledProcessError as e:
        print(f"Error creating VFs for {interface}: {e}", file=sys.stderr)
        return False


def set_mtu(interface: str, mtu: int) -> bool:
    """Set MTU for an interface."""
    try:
        subprocess.run(
            ["ip", "link", "set", "dev", interface, "mtu", str(mtu)],
            check=True, capture_output=True
        )
        return True
    except subprocess.CalledProcessError:
        print(f"Warning: Failed to set MTU for {interface}", file=sys.stderr)
        return False


def main():
    num_vfs = int(sys.argv[1]) if len(sys.argv) > 1 else 1
    
    # Try to get shape from environment (e.g., from Kubernetes node label)
    shape = os.environ.get("NODE_SHAPE")
    
    if not shape:
        shape = get_shape_with_retry()
    
    if not shape:
        print("Falling back to rdma* interface discovery", file=sys.stderr)
        interfaces = discover_rdma_interfaces()
        for iface in interfaces:
            create_vfs(iface, num_vfs)
        return
    
    print(f"Detected shape: {shape}")
    
    config = SHAPE_CONFIG.get(shape)
    if not config:
        print(f"Unknown shape '{shape}', falling back to rdma* interface discovery", 
              file=sys.stderr)
        interfaces = discover_rdma_interfaces()
        for iface in interfaces:
            create_vfs(iface, num_vfs)
        return
    
    pci_addresses = config["pci_addresses"]
    mtu = config["mtu"]
    expected_count = len(pci_addresses)
    
    print(f"Configuring RDMA interfaces for {shape} using PCI addresses "
          f"(MTU: {mtu}, expected: {expected_count} interfaces)")
    
    configured = 0
    for pci_addr in pci_addresses:
        iface = get_interface_from_pci(pci_addr)
        if iface:
            print(f"PCI {pci_addr} -> interface {iface}")
            if create_vfs(iface, num_vfs):
                set_mtu(iface, mtu)
                configured += 1
        else:
            print(f"Warning: No interface found for PCI address {pci_addr}", 
                  file=sys.stderr)
    
    print(f"Configured {configured}/{expected_count} RDMA interfaces")
    
    if configured != expected_count:
        print(f"Warning: Expected {expected_count} interfaces but only found {configured}",
              file=sys.stderr)


if __name__ == "__main__":
    main()

