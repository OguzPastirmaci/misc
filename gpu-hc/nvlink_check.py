#!/usr/bin/env python3

import subprocess
import logging

logging.basicConfig(level=logging.DEBUG)

def check_nvlink_status():
    # Check if nvlink is enabled
    num_gpus = int(subprocess.check_output(['nvidia-smi', '--list-gpus']).count(b'\n'))

    try:
        nvlink_status = subprocess.check_output(['nvidia-smi', 'nvlink', '--status'], universal_newlines=True)
    except subprocess.CalledProcessError as e:
        logging.error(f"Failed to get NVLINK status with error code {e.returncode}")
        return

    if not nvlink_status:
        logging.info("NVLINK is not enabled")
        return

    for i in range(num_gpus):
        gpu_id = i
        # Run nvlink command
        try:
            nvlink_output = subprocess.check_output(['nvidia-smi', 'nvlink', '-s', '-i', str(gpu_id)], universal_newlines=True)
        except subprocess.CalledProcessError as e:
            logging.error(f"Failed to get NVLINK status with error code {e.returncode}")
            return

        # Check for inactive links
        if "inactive" in nvlink_output:
            # Extract and display the information about inactive links
            inactive_links = "\n".join([line.replace("<inactive>", "Inactive") for line in nvlink_output.split("\n") if "Link" in line and "<inactive>" in line])
            logging.error(f"GPU {gpu_id} has nvlinks inactive: {inactive_links}")
        else:
            logging.debug(f"GPU {gpu_id} has all nvlinks active.")

if __name__ == "__main__":
    check_nvlink_status()
