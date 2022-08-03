#!/bin/bash

set -e

echo "Developed by Christopher M Johnston"
echo "Configures RHEL 7.x to be moved to OCI Bare Metal Infrastructure"

#ln -sf /lib/systemd/system/multi-user.target /etc/systemd/system/default.target
yum install dracut-network iscsi-initiator-utils -y
echo "Dependencies Installed"
echo 'add_dracutmodules+="iscsi"' >> /etc/dracut.conf.d/iscsi.conf
echo "ISCSI Modules Added to Dracut"
cat /etc/default/grub | grep -v 'GRUB_SERIAL_COMMAND\|GRUB_TERMINAL\|GRUB_CMDLINE_LINUX' > /tmp/grub
echo 'GRUB_TERMINAL="console"' >> /tmp/grub
echo 'GRUB_CMDLINE_LINUX="crashkernel=auto ip=dhcp LANG=en_US.UTF-8 console=tty0 console=ttyS0,9600 iommu=on systemd.log_level=debug systemd.log_target=kmsg log_buf_len=100M netroot=iscsi:@169.254.0.2::::iqn.2015-02.oracle.boot:uefi iscsi_initiator=iqn.2015-02.oracle.boot:instance"' >> /tmp/grub
cp /tmp/grub /etc/default/grub
grub2-mkconfig -o /etc/grub2-efi.cfg
echo "Grub Config Made"
#stty -F /dev/ttyS0 speed 9600
#dmesg | grep console
#systemctl enable getty@ttyS0
#systemctl start getty@ttyS0
echo "Executing Dracut"
for file in $(find /boot -name "vmlinuz-*" -and -not -name "vmlinuz-*rescue*") ; do
dracut --force --no-hostonly /boot/initramfs-${file:14}.img ${file:14} ; done
echo "Dracut Executed"
echo "Shutting Down"
shutdown now
