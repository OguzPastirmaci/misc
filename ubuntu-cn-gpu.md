### 1 - Create an instance configuration with the Ubuntu CN image

Create an Instance Configuration with the GPU shape.

https://docs.oracle.com/en-us/iaas/Content/Compute/Tasks/creatinginstanceconfig.htm#one

### 2 - Create a Cluster Network

Create a Cluster Network using the Instance Configuration that you created in the previous step.

https://docs.oracle.com/en-us/iaas/Content/Compute/Tasks/managingclusternetworks.htm#create

### 3 - Check the Mellanox config log

Wait for the instances to be up an running. Then, wait until you see `INFO - successfully completed setting parameters` as the last line in `/var/log/mlx-configure.log`

### 4 - Reboot the instance

There's a bug that causes interfaces to be renamed. we're tracking with Canonical. Rebooting the node fixes the issue. This reboot is needed only once.

### 5 - Check the Mellanox config log again

Check the `/var/log/mlx-configure.log` file again. You should see some `ADVANCED_PCI_SETTINGS already set to` messages and again `INFO - successfully completed setting parameters` as the last line.

### 6 - Install the v2.0.8  `oci-cn-auth` package

This step will not be needed in the next image build but necessary in this build 

```
wget https://objectstorage.us-ashburn-1.oraclecloud.com/p/3Kig7h-YO-PIlYMa-2jf6BuD6yRgISYPIi_Fy6FSBpbZiS3u08HACzN5VooXNB0W/n/hpc_limited_availability/b/share/o/oci-cn-auth_2.0.8-compute_all.deb

sudo dpkg -i oci-cn-auth_2.0.8-compute_all.deb
```

