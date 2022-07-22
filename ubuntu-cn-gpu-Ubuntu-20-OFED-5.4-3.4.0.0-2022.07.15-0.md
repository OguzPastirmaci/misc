## NOTE: Below instructions are valid for the image `Ubuntu-20-OFED-5.4-3.4.0.0-2022.07.15-0`.



### 1 - Create an instance configuration with the Ubuntu CN image

Create an Instance Configuration with the GPU shape. Use the `Ubuntu-20-OFED-*` image as the image when creating the instance configuration.

https://docs.oracle.com/en-us/iaas/Content/Compute/Tasks/creatinginstanceconfig.htm#one

### 2 - Create a Cluster Network

Create a Cluster Network using the Instance Configuration that you created in the previous step.

https://docs.oracle.com/en-us/iaas/Content/Compute/Tasks/managingclusternetworks.htm#create

### 3 - Check the Mellanox config log

Wait for the instances to be up an running. Then, wait until you see `INFO - successfully completed setting parameters` as the last line in `/var/log/mlx-configure.log`

### 4 - Edit `/etc/oci-hpc/rdma-network.conf`

Edit the `/etc/oci-hpc/rdma-network.conf` file and add the following block:

```
[subnet]
modify_arp=true
override_netconfig_netmask=255.255.0.0
```

So that the content of the file looks like below:

```
[default]
rdma_network=192.168.0.0/255.255.0.0
overwrite_config_files=true
[subnet]
modify_arp=true
override_netconfig_netmask=255.255.0.0
```

### 5 - Run the RDMA configuration tool to setup RDMA interfaces

Run `sudo /sbin/oci-rdma-configure` to setup RDMA interfaces. This step might take a couple of minutes.

### 6 - Check that the interfaces have 192.168.x.x IPs

Check that the interfaces have 192.x IPs assigned.

```
ubuntu@inst-qua9x-ubuntu-cn-public:~$ ip ad
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host
       valid_lft forever preferred_lft forever
2: enp72s0f0np0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 4220 qdisc mq state UP group default qlen 20000
    link/ether 04:3f:72:f9:30:7a brd ff:ff:ff:ff:ff:ff
    inet 192.168.0.157/16 brd 192.168.255.255 scope global enp72s0f0np0
       valid_lft forever preferred_lft forever
    inet6 fe80::63f:72ff:fef9:307a/64 scope link
       valid_lft forever preferred_lft forever
3: enp72s0f1np1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 4220 qdisc mq state UP group default qlen 20000
    link/ether 04:3f:72:f9:30:7b brd ff:ff:ff:ff:ff:ff
    inet 192.168.8.157/16 brd 192.168.255.255 scope global enp72s0f1np1
       valid_lft forever preferred_lft forever
    inet6 fe80::63f:72ff:fef9:307b/64 scope link
       valid_lft forever preferred_lft forever
4: enp76s0f0np0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 4220 qdisc mq state UP group default qlen 20000
    link/ether 04:3f:72:f9:28:f2 brd ff:ff:ff:ff:ff:ff
    inet 192.168.1.157/16 brd 192.168.255.255 scope global enp76s0f0np0
       valid_lft forever preferred_lft forever
    inet6 fe80::63f:72ff:fef9:28f2/64 scope link
       valid_lft forever preferred_lft forever
5: enp76s0f1np1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 4220 qdisc mq state UP group default qlen 20000
    link/ether 04:3f:72:f9:28:f3 brd ff:ff:ff:ff:ff:ff
    inet 192.168.9.157/16 brd 192.168.255.255 scope global enp76s0f1np1
       valid_lft forever preferred_lft forever
    inet6 fe80::63f:72ff:fef9:28f3/64 scope link
       valid_lft forever preferred_lft forever
       
...
```

### 7 - Test pinging another instance in the cluster network to check connectivity

```
ubuntu@inst-qua9x-ubuntu-cn-public:~$ ping -I enp148s0f1np1 192.168.14.193
PING 192.168.14.193 (192.168.14.193) from 192.168.15.157 enp148s0f1np1: 56(84) bytes of data.
64 bytes from 192.168.14.193: icmp_seq=1 ttl=64 time=0.103 ms
64 bytes from 192.168.14.193: icmp_seq=2 ttl=64 time=0.044 ms
64 bytes from 192.168.14.193: icmp_seq=3 ttl=64 time=0.034 ms
...
```
