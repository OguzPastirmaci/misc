1- Create the following script in `/var/tmp/nvme.sh`

```sh
#!/bin/bash

set -x

# Prepare local NVME
if mount -l | grep -q "/dev/nvme0n1p1 on /nvme type ext4"; then
   echo "$(date) Partition exists, skipping" >> /var/tmp/nvme.log
else
   echo "$(date) Partition doesn't exist, creating" >> /var/tmp/nvme.log
   parted /dev/nvme0n1 mklabel gpt
   sleep 3
   parted -a opt /dev/nvme0n1 mkpart primary ext4 0% 100%
   sleep 3
   mkfs.ext4 -L datapartition /dev/nvme0n1p1
   sleep 3
   mkdir -p /nvme
   sed -i '/nvme0n1p1/s/^#//g' /etc/fstab
   mount -a
   mkdir -p /nvme/sge/spool
   mkdir -p /nvme/tmp
   chown -R sgeadmin:sgegroup /nvme
fi

# Disable hyperthreading
for i in {36..71}; do
   echo "Disabling logical HT core $i."
   echo 0 | tee /sys/devices/system/cpu/cpu${i}/online;
done
```
2- Add execute permission to the script

`chmod +x /var/tmp/nvme.sh`

3- Create a new service unit file at `/etc/systemd/system/nvme.service` with the following content

```sh
[Unit]
Description=Service to check if NVME is configured
After=network.target

[Service]
Type=simple
ExecStart=/var/tmp/nvme.sh
TimeoutStartSec=0

[Install]
WantedBy=default.target
```

4- Then enable the service

`systemctl daemon-reload`

`systemctl enable nvme.service`

`systemctl start nvme.service`
