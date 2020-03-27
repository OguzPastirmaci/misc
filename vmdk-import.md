Your VM was probably running on VMware the VMware drivers were loaded instead of the virtio* drivers needed by OCI.

Because of that, the current initramfs that will be used on OCI does not have included the virtio drivers.

 Before following the below steps, here's a couple of other things to check.

## Checking virtio drivers

1. Please check the kernel version. It should be **3.4** and above.

```sh
uname -a
```

The output should look similar to this:

```sh
Linux ip_bash 4.14.35-1818.2.1.el7uek.x86_64 #2 SMP Mon Aug 27 21:16:31 PDT 2018 x86_64 x86_64 x86_64 GNU/Linux
```

2. You should be seeing no virtio drivers on current initramfs. Please check the output is similar when you run the following command in your RHEL image VM.

```sh
[root@localhost ~]# lsinitrd /boot/initramfs-$(uname -r).img | grep -i virtio
[root@localhost ~]
```

3. You probably have Vmware drivers loaded instead. Please check the output is similar when you run the following 2 commands in your RHEL image VM.

```sh
[root@localhost ~]# lsmod | grep virtio
[root@localhost ~]#
```

```sh
[root@localhost ~]# lsmod | grep vm
vmw_vsock_vmci_transport 30577 2
vsock 36452 4 vmw_vsock_vmci_transport,vsock_diag
vmw_balloon 18190 0
vmw_vmci 67081 1 vmw_vsock_vmci_transport
vmwgfx 271734 3
drm_kms_helper 176920 1 vmwgfx
ttm 99555 1 vmwgfx
drm 397988 6 ttm,drm_kms_helper,vmwgfx
[root@localhost ~]#
```

## Possible solution

1. Rebuild the initramfs with the Virtio Drivers.

NOTE: Please make a Copy of the initramfs image prior to rebuild as the below command will over-write it.

```sh
dracut -v -f --add-drivers "virtio virtio_pci virtio_scsi virtio_ring" /boot/initramfs-$(uname -r).img $(uname -r)
```

2. Verify Virtio Drivers are included on new initramfs for current kernel.

```sh
[root@localhost ~]# lsinitrd /boot/initramfs-$(uname -r).img | grep -i virtio
Arguments: -v -f --add-drivers 'virtio virtio_pci virtio_scsi virtio_ring'
-rw-r--r-- 1 root root 8168 Apr 11 2018 usr/lib/modules/3.10.0-862.el7.x86_64/kernel/drivers/scsi/virtio_scsi.ko.xz
drwxr-xr-x 2 root root 0 Feb 20 12:34 usr/lib/modules/3.10.0-862.el7.x86_64/kernel/drivers/virtio
-rw-r--r-- 1 root root 4540 Apr 11 2018 usr/lib/modules/3.10.0-862.el7.x86_64/kernel/drivers/virtio/virtio.ko.xz
-rw-r--r-- 1 root root 9652 Apr 11 2018 usr/lib/modules/3.10.0-862.el7.x86_64/kernel/drivers/virtio/virtio_pci.ko.xz
-rw-r--r-- 1 root root 8264 Apr 11 2018 usr/lib/modules/3.10.0-862.el7.x86_64/kernel/drivers/virtio/virtio_ring.ko.xz
[root@localhost ~]#
```

3. Create the image file by cloning the source volume, not by creating a snapshot. Please also make sure that the VM in vCenter is setup for BIOS boot and **not** EFI/UEFI boot.

4. Reupload the image to the VM (IP of the VM changed). The SSH private key is the same. You can create a directory under `/mnt/image` and put the image there.

```sh
ssh opc@129.146.53.151 -i <private key we shared in the email earlier>
```

