### Get the list of kernel indexes on your instance

```
sudo grubby --info=ALL | grep -E "^kernel|^index"
```

You will get something like

```
index=0
kernel="/boot/vmlinuz-5.15.0-100.96.32.el8uek.x86_64"
index=1
kernel="/boot/vmlinuz-4.18.0-425.19.2.el8_7.x86_64"
index=2
kernel="/boot/vmlinuz-0-rescue-654e1fff75c9d3782020393dffaf9380"
```

### Choose the RHCK kernel

In the above output,the entry that does not have `uek` in the name is usually the RHCK one. For example in the above output, it's the one with `index=1` which is `vmlinuz-4.18.0-425.19.2.el8_7.x86_64`.

### Set the RHCK kernel as the default kernel
Using the index from the previous step, run the below command for changing the default kernel to RHCK:

```
sudo grubby --set-default-index=1
```

### Reboot the node
To check that the instance boots without issues.

### Run the OCI image cleanup script
SSH into the instance again and clone the `oci-utils` repo:

```
sudo yum install -y git

git clone https://github.com/oracle/oci-utils.git
```

### Run the OCI cleanup script so SSH keys etc. are removed from the image

```
sudo ./oci-utils/libexec/oci-image-cleanup -f
```

### Save as a custom image
