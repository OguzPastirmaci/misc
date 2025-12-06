#!/usr/bin/env bash
# Improved VF creation script with better error handling and logging
set -e -o pipefail

function log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >&2
}

function numvfs_path_for_interface() {
    echo "/sys/class/net/${1}/device/sriov_numvfs"
}

function get_totalvfs() {
    local interface="${1}"
    local totalvfs_path="/sys/class/net/${interface}/device/sriov_totalvfs"
    if [[ -f "$totalvfs_path" ]]; then
        cat "$totalvfs_path"
    else
        echo "0"
    fi
}

function get_vf_dev_name() {
    local interface="${1}" vf_idx="${2}"
    local vf_net_path="/sys/class/net/${interface}/device/virtfn${vf_idx}/net"
    if [[ -d "$vf_net_path" ]]; then
        ls "$vf_net_path" 2>/dev/null | head -1
    else
        echo ""
    fi
}

function get_eff_mac_addr() {
    local interface="${1}" vf_idx="${2}"
    local vf_dev_name
    vf_dev_name=$(get_vf_dev_name "$interface" "$vf_idx")
    if [[ -n "$vf_dev_name" ]]; then
        cat "/sys/class/net/${interface}/device/virtfn${vf_idx}/net/$vf_dev_name/address" 2>/dev/null || echo ""
    else
        echo ""
    fi
}

function get_vf_pci_addr() {
    local interface="${1}" vf_idx="${2}"
    local vf_dev_name
    vf_dev_name=$(get_vf_dev_name "$interface" "$vf_idx")
    if [[ -n "$vf_dev_name" ]]; then
        grep PCI_SLOT_NAME "/sys/class/net/${vf_dev_name}/device/uevent" 2>/dev/null | cut -d "=" -f 2
    else
        echo ""
    fi
}

function wait_for_vf() {
    local interface="${1}" vf_idx="${2}" max_wait="${3:-10}"
    local waited=0
    while [[ $waited -lt $max_wait ]]; do
        local vf_dev_name
        vf_dev_name=$(get_vf_dev_name "$interface" "$vf_idx")
        if [[ -n "$vf_dev_name" ]]; then
            return 0
        fi
        sleep 1
        ((waited++))
    done
    return 1
}

function create_vfs() {
    local interface="${1}" num_vfs="${2}"
    
    log "Creating ${num_vfs} VFs for ${interface}"
    
    # Validate interface exists
    if [[ ! -d "/sys/class/net/${interface}" ]]; then
        log "ERROR: Interface ${interface} does not exist"
        return 1
    fi
    
    local numvfs_path
    numvfs_path=$(numvfs_path_for_interface "${interface}")
    
    if [[ ! -f "${numvfs_path}" ]]; then
        log "ERROR: SRIOV not supported for interface ${interface} (${numvfs_path} not found)"
        return 1
    fi
    
    # Check max VFs supported
    local total_vfs
    total_vfs=$(get_totalvfs "${interface}")
    if [[ "$num_vfs" -gt "$total_vfs" ]]; then
        log "ERROR: Requested ${num_vfs} VFs but interface ${interface} only supports ${total_vfs}"
        return 1
    fi
    
    # Create the SRIOV virtual functions
    local current_num_of_vfs
    current_num_of_vfs=$(cat "${numvfs_path}")
    
    if [[ "${current_num_of_vfs}" != "${num_vfs}" ]]; then
        log "Creating VFs for ${interface} (current: ${current_num_of_vfs}, target: ${num_vfs})"
        
        if [[ "${current_num_of_vfs}" != "0" ]]; then
            log "Resetting VFs to 0 first"
            echo "0" | tee "${numvfs_path}" > /dev/null 2>&1 || {
                log "ERROR: Failed to reset VFs for ${interface}"
                return 1
            }
            sleep 2
        fi
        
        echo "${num_vfs}" | tee "${numvfs_path}" > /dev/null 2>&1 || {
            log "ERROR: Failed to create ${num_vfs} VFs for ${interface}"
            return 1
        }
        
        # Wait for VFs to be created
        sleep 3
    else
        log "${num_vfs} VFs already created for ${interface}"
    fi
    
    # Configure the SRIOV virtual functions with the effective MAC address
    for (( i=0; i<num_vfs; i++ )); do
        log "Configuring VF ${i} for ${interface}"
        
        # Wait for VF to appear
        if ! wait_for_vf "${interface}" ${i} 10; then
            log "ERROR: VF ${i} did not appear for ${interface}"
            continue
        fi
        
        local mac
        mac=$(get_eff_mac_addr "${interface}" ${i})
        if [[ -z "$mac" ]]; then
            log "WARNING: Could not get MAC address for VF ${i}"
            continue
        fi
        
        local vf_dev_name
        vf_dev_name=$(get_vf_dev_name "$interface" $i)
        log "Setting ${interface} VF ${i} (${vf_dev_name}) MAC to ${mac}"
        
        ip link set dev "$interface" vf ${i} mac "$mac" || {
            log "WARNING: Failed to set MAC for VF ${i}"
        }
        
        local vf_pci_addr
        vf_pci_addr=$(get_vf_pci_addr "$interface" ${i})
        if [[ -n "$vf_pci_addr" ]]; then
            log "Rebinding VF ${i} PCI device ${vf_pci_addr}"
            echo "$vf_pci_addr" > /sys/bus/pci/drivers/mlx5_core/unbind 2>/dev/null || true
            sleep 1
            echo "$vf_pci_addr" > /sys/bus/pci/drivers/mlx5_core/bind 2>/dev/null || {
                log "WARNING: Failed to rebind VF ${i}"
            }
        fi
    done
    
    log "Successfully configured ${num_vfs} VFs for ${interface}"
}

# Main
interface="${1}"
num_vfs="${2:-1}"

if [[ -z "$interface" ]]; then
    echo "Usage: $0 <interface> [num_vfs]" >&2
    exit 1
fi

create_vfs "${interface}" "${num_vfs}"

