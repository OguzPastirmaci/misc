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

### 5 - Install the new 
