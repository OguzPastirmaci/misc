#!/usr/bin/env bash
# VF configuration script using PCI addresses (rootDevices)
# More reliable than interface names as PCI addresses are hardware-defined
set -e -o pipefail

num_vfs="${1:-1}"

# Get interface name from PCI address
get_interface_from_pci() {
    local pci_addr="$1"
    local net_path="/sys/bus/pci/devices/${pci_addr}/net"
    if [[ -d "$net_path" ]]; then
        ls "$net_path" 2>/dev/null | head -1
    else
        echo ""
    fi
}

# Detect shape from OCI metadata with retry
get_shape_with_retry() {
    local max_time=300  # 5 minutes
    local interval=15   # seconds between retries
    local start_time=$(date +%s)
    
    while true; do
        local shape
        shape=$(curl -s -H "Authorization: Bearer Oracle" -L http://169.254.169.254/opc/v2/instance/shape 2>/dev/null) || true
        
        if [[ -n "$shape" ]]; then
            echo "$shape"
            return 0
        fi
        
        local current_time=$(date +%s)
        local elapsed=$((current_time - start_time))
        
        if [[ $elapsed -ge $max_time ]]; then
            echo "Warning: Unable to detect shape after ${max_time}s, falling back to rdma* interface discovery" >&2
            return 1
        fi
        
        echo "Metadata service not responding, retrying in ${interval}s... (elapsed: ${elapsed}s/${max_time}s)" >&2
        sleep $interval
    done
}

SHAPE=$(get_shape_with_retry)

if [[ -z "$SHAPE" ]]; then
    find /sys/class/net -name "rdma*" | grep -v "v[0-9]*" | sort | \
        xargs -n1 basename | xargs -I{} oci-create-vfs {} "$num_vfs"
    exit 0
fi

echo "Detected shape: $SHAPE"

# Define RDMA PCI addresses per shape (from shapes.json)
get_rdma_pci_addresses() {
    local shape="$1"
    case "$shape" in
        BM.GPU4.8)
            echo "0000:0c:00.0 0000:0c:00.1 0000:16:00.0 0000:16:00.1 0000:48:00.0 0000:48:00.1 0000:4c:00.0 0000:4c:00.1 0000:8a:00.0 0000:8a:00.1 0000:94:00.0 0000:94:00.1 0000:c3:00.0 0000:c3:00.1 0000:d1:00.0 0000:d1:00.1"
            ;;
        BM.GPU.B4.8)
            echo "0000:0c:00.0 0000:0c:00.1 0000:16:00.0 0000:16:00.1 0000:47:00.0 0000:47:00.1 0000:4b:00.0 0000:4b:00.1 0000:89:00.0 0000:89:00.1 0000:93:00.0 0000:93:00.1 0000:c3:00.0 0000:c3:00.1 0000:d1:00.0 0000:d1:00.1"
            ;;
        BM.GPU.A100-v2.8)
            echo "0000:0c:00.0 0000:0c:00.1 0000:16:00.0 0000:16:00.1 0000:47:00.0 0000:47:00.1 0000:4b:00.0 0000:4b:00.1 0000:89:00.0 0000:89:00.1 0000:93:00.0 0000:93:00.1 0000:c3:00.0 0000:c3:00.1 0000:d1:00.0 0000:d1:00.1"
            ;;
        BM.GPU.GM4.8)
            echo "0000:0c:00.0 0000:0c:00.1 0000:16:00.0 0000:16:00.1 0000:47:00.0 0000:47:00.1 0000:4b:00.0 0000:4b:00.1 0000:89:00.0 0000:89:00.1 0000:93:00.0 0000:93:00.1 0000:c3:00.0 0000:c3:00.1 0000:d1:00.0 0000:d1:00.1"
            ;;
        BM.GPU.H100.8)
            echo "0000:0c:00.0 0000:0c:00.1 0000:2a:00.0 0000:2a:00.1 0000:41:00.0 0000:41:00.1 0000:58:00.0 0000:58:00.1 0000:86:00.0 0000:86:00.1 0000:a5:00.0 0000:a5:00.1 0000:bd:00.0 0000:bd:00.1 0000:d5:00.0 0000:d5:00.1"
            ;;
        BM.GPU.H100T.8)
            echo "0000:0c:00.0 0000:0c:00.1 0000:2a:00.0 0000:2a:00.1 0000:41:00.0 0000:41:00.1 0000:58:00.0 0000:58:00.1 0000:86:00.0 0000:86:00.1 0000:a5:00.0 0000:a5:00.1 0000:bd:00.0 0000:bd:00.1 0000:d5:00.0 0000:d5:00.1"
            ;;
        BM.GPU.H200.8|BM.GPU.H200-NC.8)
            echo "0000:0c:00.0 0000:2a:00.0 0000:41:00.0 0000:58:00.0 0000:86:00.0 0000:a5:00.0 0000:bd:00.0 0000:d5:00.0"
            ;;
        BM.GPU.B200.8)
            echo "0000:0c:00.0 0000:2a:00.0 0000:41:00.0 0000:58:00.0 0000:86:00.0 0000:a5:00.0 0000:bd:00.0 0000:d5:00.0"
            ;;
        BM.GPU.L40S.4|BM.GPU.L40S-NC.4)
            echo "0000:27:00.0 0000:97:00.0"
            ;;
        BM.GPU.MI300X.8)
            echo "0000:0c:00.0 0000:2a:00.0 0000:41:00.0 0000:58:00.0 0000:86:00.0 0000:a5:00.0 0000:bd:00.0 0000:d5:00.0"
            ;;
        BM.GPU.MI355X-v1.8)
            echo "0000:6d:00.0 0000:05:00.0 0000:55:00.0 0000:1e:00.0 0000:ec:00.0 0000:86:00.0 0000:d4:00.0 0000:9f:00.0"
            ;;
        BM.GPU.GB200.4)
            echo "0000:03:00.0 0002:03:00.0 0010:03:00.0 0012:03:00.0"
            ;;
        BM.GPU.GB200-v2.4)
            echo "0000:03:00.0 0002:03:00.0 0010:03:00.0 0012:03:00.0"
            ;;
        BM.GPU.GB200-v3.4)
            echo "0000:03:00.0 0000:03:00.1 0002:03:00.0 0002:03:00.1 0010:03:00.0 0010:03:00.1 0012:03:00.0 0012:03:00.1"
            ;;
        BM.GPU.GB300.4)
            echo "0000:03:00.0 0000:03:00.1 0002:03:00.0 0002:03:00.1 0010:03:00.0 0010:03:00.1 0012:03:00.0 0012:03:00.1"
            ;;
        *)
            echo ""
            ;;
    esac
}

# Get MTU for shape
get_mtu_for_shape() {
    local shape="$1"
    case "$shape" in
        BM.GPU.GB200-v3.4|BM.GPU.GB300.4)
            echo "9000"
            ;;
        *)
            echo "4220"
            ;;
    esac
}

# Get expected interface count for validation
get_expected_count() {
    local shape="$1"
    case "$shape" in
        BM.GPU4.8|BM.GPU.B4.8|BM.GPU.A100-v2.8|BM.GPU.GM4.8|BM.GPU.H100.8|BM.GPU.H100T.8)
            echo "16"
            ;;
        BM.GPU.H200.8|BM.GPU.H200-NC.8|BM.GPU.B200.8|BM.GPU.MI300X.8|BM.GPU.MI355X-v1.8|BM.GPU.GB200-v3.4|BM.GPU.GB300.4)
            echo "8"
            ;;
        BM.GPU.GB200.4|BM.GPU.GB200-v2.4)
            echo "4"
            ;;
        BM.GPU.L40S.4|BM.GPU.L40S-NC.4)
            echo "2"
            ;;
        *)
            echo "0"
            ;;
    esac
}

pci_addresses=$(get_rdma_pci_addresses "$SHAPE")
mtu=$(get_mtu_for_shape "$SHAPE")
expected_count=$(get_expected_count "$SHAPE")

if [[ -z "$pci_addresses" ]]; then
    echo "Unknown shape '$SHAPE', falling back to rdma* interface discovery" >&2
    find /sys/class/net -name "rdma*" | grep -v "v[0-9]*" | sort | \
        xargs -n1 basename | xargs -I{} oci-create-vfs {} "$num_vfs"
    exit 0
fi

echo "Configuring RDMA interfaces for $SHAPE using PCI addresses (MTU: $mtu, expected: $expected_count interfaces)"

configured=0
for pci_addr in $pci_addresses; do
    iface=$(get_interface_from_pci "$pci_addr")
    if [[ -n "$iface" ]]; then
        echo "PCI $pci_addr -> interface $iface"
        oci-create-vfs "$iface" "$num_vfs"
        # Set MTU
        ip link set dev "$iface" mtu "$mtu" 2>/dev/null || echo "Warning: Failed to set MTU for $iface"
        ((configured++)) || true
    else
        echo "Warning: No interface found for PCI address $pci_addr" >&2
    fi
done

echo "Configured $configured/$expected_count RDMA interfaces"

if [[ "$configured" -ne "$expected_count" && "$expected_count" -ne "0" ]]; then
    echo "Warning: Expected $expected_count interfaces but only found $configured" >&2
fi

