### Unmount /nfs/scratch from all nodes

**Run from bastion**

```
sudo sed -e '/scratch/ s/^#*/#/' -i /etc/fstab

sudo mount -a

parallel-ssh -h /etc/opt/oci-hpc/hostfile.tcp "sudo sed -e '/scratch/ s/^#*/#/' -i /etc/fstab"

parallel-ssh -h /etc/opt/oci-hpc/hostfile.tcp "sudo mount -a"
```

### Remove localdisk from exports

```
parallel-ssh -h /etc/opt/oci-hpc/hostfile.tcp "sudo sed -e '/localdisk/ s/^#*/#/' -i /etc/exports.d/scratch.exports"

parallel-ssh -h /etc/opt/oci-hpc/hostfile.tcp "sudo systemctl restart nfs-server"

parallel-ssh -h /etc/opt/oci-hpc/hostfile.tcp "sudo umount /mnt/localdisk"
```

**Run from worker nodes**

### Delete the existing partition

```
(echo p; echo d; echo w) | fdisk /dev/nvme0n1
```

### Create RAID 0 array

```
mdadm --create /dev/md0 --raid-devices=4 --level=0 /dev/nvme0n1 /dev/nvme1n1 /dev/nvme2n1 /dev/nvme3n1

mdadm --detail --scan | sudo tee -a /etc/mdadm.conf >> /dev/null
```

### Create FS

```
parted /dev/md0 mklabel gpt

parted -a opt /dev/md0 mkpart primary ext4 0% 100%

mkfs.ext4 -L datapartition /dev/md0

mkdir -p /mnt/localdisk

echo "/dev/md0 /mnt/localdisk ext4 defaults,noatime 0 0" | tee -a /etc/fstab

mount -a

chmod -R 777 /mnt/localdisk
```
