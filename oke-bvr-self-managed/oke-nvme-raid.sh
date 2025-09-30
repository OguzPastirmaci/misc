#!/usr/bin/env bash
# shellcheck disable=SC2086,SC2174
set -o errexit -o nounset -o pipefail -x
shopt -s nullglob

level="${1:-0}"
pattern="${2:-/dev/nvme*n1}"
mount_primary="${3:-/mnt/nvme}"
mount_extra=(/var/lib/{containers,kubelet,logs/pods})
md_device="/dev/md/0"

# Function to detect existing RAID arrays on devices
detect_existing_raid() {
    local devices=("$@")
    local existing_arrays=()
    
    for device in "${devices[@]}"; do
        # Check if device is part of an existing RAID array
        if mdadm --examine "$device" &>/dev/null; then
            local array_uuid=$(mdadm --examine "$device" 2>/dev/null | grep -i "array uuid" | awk '{print $NF}')
            if [[ -n "$array_uuid" ]]; then
                existing_arrays+=("$array_uuid")
            fi
        fi
    done
    
    # Remove duplicates and return unique array UUIDs
    printf '%s\n' "${existing_arrays[@]}" | sort -u
}

# Function to assemble existing RAID array
assemble_existing_raid() {
    local uuid="$1"
    echo "Attempting to assemble existing RAID array with UUID: $uuid" >&2
    
    # First check if the array is already assembled
    local already_assembled=""
    for md_dev in /dev/md*; do
        if [[ -e "$md_dev" ]] && mdadm --detail "$md_dev" 2>/dev/null | grep -q "$uuid"; then
            already_assembled="$md_dev"
            echo "RAID array already assembled as: $already_assembled" >&2
            break
        fi
    done
    
    # If already assembled, use that device
    if [[ -n "$already_assembled" ]]; then
        if [[ "$already_assembled" != "$md_device" ]]; then
            # Stop the existing array to reassemble with our preferred name
            echo "Stopping $already_assembled to reassemble as $md_device" >&2
            mdadm --stop "$already_assembled"
            already_assembled=""
        else
            echo "RAID array already assembled with correct name: $md_device" >&2
            return 0
        fi
    fi
    
    # Try different assembly methods
    local devices_for_uuid=()
    for device in "${devices[@]}"; do
        if mdadm --examine "$device" 2>/dev/null | grep -q "$uuid"; then
            devices_for_uuid+=("$device")
        fi
    done
    
    echo "Found ${#devices_for_uuid[@]} devices for UUID $uuid: ${devices_for_uuid[*]}" >&2
    
    # Method 1: Try to assemble with specific devices
    if mdadm --assemble "$md_device" "${devices_for_uuid[@]}" 2>/dev/null; then
        echo "Successfully assembled RAID array as $md_device" >&2
        return 0
    fi
    
    # Method 2: Try scan-based assembly
    if mdadm --assemble --scan --uuid="$uuid" 2>/dev/null; then
        # Find where it was assembled
        local assembled_device=""
        for md_dev in /dev/md*; do
            if [[ -e "$md_dev" ]] && mdadm --detail "$md_dev" 2>/dev/null | grep -q "$uuid"; then
                assembled_device="$md_dev"
                break
            fi
        done
        
        if [[ -n "$assembled_device" ]]; then
            echo "RAID array assembled as: $assembled_device" >&2
            
            # Create symlink to expected device name if different
            if [[ "$assembled_device" != "$md_device" ]]; then
                ln -sf "$assembled_device" "$md_device"
                echo "Created symlink: $md_device -> $assembled_device" >&2
            fi
            return 0
        fi
    fi
    
    # Method 3: Force assembly if possible
    echo "Trying force assembly..." >&2
    if mdadm --assemble --force "$md_device" "${devices_for_uuid[@]}" 2>/dev/null; then
        echo "Successfully force-assembled RAID array as $md_device" >&2
        return 0
    fi
    
    echo "Failed to assemble existing RAID array" >&2
    return 1
}

# Function to stop any existing arrays that might conflict
stop_conflicting_arrays() {
    echo "Checking for conflicting RAID arrays..." >&2
    
    # First, scan for all existing arrays
    for md_dev in /dev/md[0-9]* /dev/md/*; do
        if [[ -e "$md_dev" ]] && [[ -b "$md_dev" ]] && mdadm --detail "$md_dev" &>/dev/null; then
            echo "Found active RAID array: $md_dev" >&2
            mdadm --detail "$md_dev" | head -10 >&2
        fi
    done
    
    # Stop any arrays that might be using our target device name
    if [[ -e "$md_device" ]] && [[ -b "$md_device" ]] && mdadm --detail "$md_device" &>/dev/null; then
        echo "Stopping existing array at $md_device" >&2
        mdadm --stop "$md_device" || true
    fi
    
    # Also check for automatically numbered arrays that might be our devices
    for device in "${devices[@]}"; do
        local using_arrays=$(grep "$device" /proc/mdstat 2>/dev/null | awk '{print $1}' || true)
        for array in $using_arrays; do
            if [[ -n "$array" ]]; then
                echo "Device $device is in use by array $array, stopping it..." >&2
                mdadm --stop "/dev/$array" || true
            fi
        done
    done
}

# Enumerate NVMe devices, exit if absent
devices=($pattern)
if [ ${#devices[@]} -eq 0 ]; then
  echo "No NVMe devices" >&2
  exit 0
fi

echo "Found ${#devices[@]} NVMe devices: ${devices[*]}" >&2

# Check for existing RAID configuration
existing_uuids=($(detect_existing_raid "${devices[@]}"))

if [[ ${#existing_uuids[@]} -gt 0 ]]; then
    echo "Found existing RAID configuration(s)" >&2
    
    # Stop any conflicting arrays first
    stop_conflicting_arrays
    
    # Try to assemble the first (and hopefully only) existing array
    if assemble_existing_raid "${existing_uuids[0]}"; then
        echo "Successfully restored existing RAID array" >&2
        # Check if the array is degraded and needs rebuilding
        if mdadm --detail "$md_device" | grep -q "State.*degraded"; then
            echo "WARNING: RAID array is in degraded state" >&2
            mdadm --detail "$md_device" >&2
        fi
    else
        echo "Failed to restore existing RAID array" >&2
        echo "You may need to manually assemble the array or check for missing devices" >&2
        echo "Try: mdadm --assemble $md_device ${devices[*]}" >&2
        echo "Or: mdadm --assemble --scan" >&2
        exit 1
    fi
fi

# If no existing RAID was found or restoration failed, create new array
if [[ ${#existing_uuids[@]} -eq 0 ]]; then
    # Determine config for detected device count and RAID level
    count=${#devices[@]}; bs=4; chunk=256
    stride=$((chunk/bs)) # chunk size / block size
    eff_count=$count # $level == 0
    if [[ $level == 10 ]]; then eff_count=$((count/2)); fi
    if [[ $level == 5 ]]; then eff_count=$((count-1)); fi
    if [[ $level == 6 ]]; then eff_count=$((count-2)); fi
    stripe=$((eff_count*stride)) # number of data disks * stride

    echo -e "Creating RAID${level} filesystem mounted under ${mount_primary} with $count devices:\n  ${devices[*]}" >&2
    echo -e "Filesystem options:\n  eff_count=$eff_count; chunk=${chunk}K; bs=${bs}K; stride=$stride; stripe-width=${stripe}" >&2
    
    # Stop any existing array at target device
    if [[ -e "$md_device" ]] && mdadm --detail "$md_device" &>/dev/null; then
        mdadm --stop "$md_device"
    fi
    
    echo "y" | mdadm --create "$md_device" --level="$level" --chunk=$chunk --force --raid-devices="$count" "${devices[@]}"
    dd if=/dev/zero of="$md_device" bs=${bs}K count=128
    
    echo "Formatting '$md_device'" >&2
    mkfs.ext4 -I 512 -b $((bs*1024)) -E stride=${stride},stripe-width=${stripe} -O dir_index -m 1 -F "$md_device"
fi

# Check if filesystem exists and is valid
if ! tune2fs -l "$md_device" &>/dev/null; then
    echo "No valid filesystem found on $md_device, formatting..." >&2
    # Determine filesystem parameters for existing array
    count=$(mdadm --detail "$md_device" | grep "Raid Devices" | awk '{print $4}')
    chunk=$(mdadm --detail "$md_device" | grep "Chunk Size" | awk '{print $4}' | sed 's/K//')
    level=$(mdadm --detail "$md_device" | grep "Raid Level" | awk '{print $4}' | sed 's/raid//')
    
    bs=4
    stride=$((chunk/bs))
    eff_count=$count
    if [[ $level == 10 ]]; then eff_count=$((count/2)); fi
    if [[ $level == 5 ]]; then eff_count=$((count-1)); fi
    if [[ $level == 6 ]]; then eff_count=$((count-2)); fi
    stripe=$((eff_count*stride))
    
    mkfs.ext4 -I 512 -b $((bs*1024)) -E stride=${stride},stripe-width=${stripe} -O dir_index -m 1 -F "$md_device"
else
    echo "$md_device already has a valid filesystem" >&2
fi

# Create mount directories
mkdir -m 0755 -p "$mount_primary" "${mount_extra[@]}"

# Setup systemd mount for the primary RAID device
dev_uuid=$(blkid -s UUID -o value "${md_device}")
mount_unit_name="$(systemd-escape --path --suffix=mount "${mount_primary}")"
cat > "/etc/systemd/system/${mount_unit_name}" << EOF
    [Unit]
    Description=Mount local NVMe RAID for OKE
    [Mount]
    What=UUID=${dev_uuid}
    Where=${mount_primary}
    Type=ext4
    Options=defaults,noatime
    [Install]
    WantedBy=multi-user.target
EOF
systemd-analyze verify "${mount_unit_name}"
systemctl enable "${mount_unit_name}" --now

# Setup bind mounts for additional directories
for mount in "${mount_extra[@]}"; do
  name=$(basename "$mount")
  array_mount_point_name="$mount_primary/$name"
  mkdir -m 0755 -p "$mount_primary/$name"
  mount_unit_name="$(systemd-escape --path --suffix=mount "${mount}")"
  cat > "/etc/systemd/system/${mount_unit_name}" << EOF
      [Unit]
      Description=Mount ${name} on OKE NVMe RAID
      [Mount]
      What=${array_mount_point_name}
      Where=${mount}
      Type=none
      Options=bind
      [Install]
      WantedBy=multi-user.target
EOF
  systemd-analyze verify "${mount_unit_name}"
  systemctl enable "${mount_unit_name}" --now  
done

# Update mdadm configuration
mdadm --detail --scan --verbose >> /etc/mdadm/mdadm.conf

# Update initramfs to include RAID configuration
update-initramfs -u

echo "RAID setup completed successfully!" >&2
