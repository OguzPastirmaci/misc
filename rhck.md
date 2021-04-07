Here's the instructions to convert Oracle Linux 7.9 `3.10.0-1160.2.2.el7.x86_64` kernel to RHCK from UEK.

1- When launching an instance via Console, click on **Change Image**, then select Image Source as **Image OCID**, then enter the image OCIDs below:

```
ocid1.image.oc1.iad.aaaaaaaaf2wxqc6ee5axabpbandk6ji27oyxyicatqw5iwkrk76kecqrrdyq
```

2- After the instance is deployed, SSH into it and run the following commands:

```
sudo grub2-set-default 1

sudo grub2-mkconfig -o /etc/grub2-efi.cfg

sudo reboot

```

3- After the instance is rebooted, SSH into it again and check that you switched to RHCK from UEK:

```
uname -a
Linux instance-20210407-1305 3.10.0-1160.2.2.el7.x86_64 #1 SMP Thu Oct 22 09:10:02 PDT 2020 x86_64 x86_64 x86_64 GNU/Linux
```
