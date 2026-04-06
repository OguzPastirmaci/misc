Prime client should be able SSH into all client nodes.

Client nodes should have the Spec directory in the same location (entered as `EXEC_PATH` in the sfs_rc file).

On the prime client with Oracle 8, install Python 3.8+

```
sudo dnf -y module install python39
python3.9 -m pip install pyyaml
```

Copy the sfs_rc file in the SPEC installation directory and edit it.

```
cp sfs_rc nfsha
python3.9 SM2020 -r nfsha -s swbuild
```

On the client nodes, run the following:

```
systemctl stop firewalld
systemctl disable firewalld
setenforce 0
sed -i s/^SELINUX=.*$/SELINUX=disabled/ /etc/selinux/config
```

Edit the `/etc/security/limits.conf` file and add the following lines to the end:

```
opc - nproc 10000
opc - nofile 10000
```

Edit the `/etc/sysctl.conf` file add the following lines to the end:

```
#
# Recommended client tunes for running SPECstorage Solution 2020
# sysctl settings are defined through files in
# /usr/lib/sysctl.d/, /run/sysctl.d/, and /etc/sysctl.d/.
#
# Vendors settings live in /usr/lib/sysctl.d/.
# To override a whole file, create a new file with the same in
# /etc/sysctl.d/ and put new settings there. To override
# only specific settings, add a file with a lexically later
# name in /etc/sysctl.d/ and put new settings there.
#
# For more information, see sysctl.conf(5) and sysctl.d(5).
# Network parameters. In unit of bytes
net.core.wmem_max = 16777216
net.core.wmem_default = 1048576
net.core.rmem_max = 16777216
net.core.rmem_default = 1048576
net.ipv4.tcp_rmem = 1048576 8388608 16777216
net.ipv4.tcp_wmem = 1048576 8388608 16777216
net.core.optmem_max = 2048000
net.core.somaxconn = 65535
#
# These settings are in 4 KiB size chunks, in bytes they are:
# Min = 16MiB, Def=350MiB, Max=16GiB
# In unit of 4k pages
net.ipv4.tcp_mem = 4096 89600 4194304
#
# Misc network options and flags
#
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_timestamps = 0
net.ipv4.tcp_sack = 1
net.ipv4.tcp_no_metrics_save = 1
net.ipv4.route.flush = 1
net.ipv4.tcp_low_latency = 1
net.ipv4.ip_local_port_range = 1024 65000
net.ipv4.tcp_slow_start_after_idle = 0
net.core.netdev_max_backlog = 300000
#
# Various filesystem / pagecache options
#
vm.dirty_expire_centisecs = 100
vm.dirty_writeback_centisecs = 100
vm.dirty_ratio = 20
vm.dirty_background_ratio = 5
#
# Recommended by: https://cromwell-intl.com/open-source/performance-tuning/tcp.html
#
net.ipv4.tcp_sack = 0
net.ipv4.tcp_dsack = 0
net.ipv4.tcp_fack = 0
```

Reload sysctl
```
sysctl --system
```


Run the test from the Prime

```
python3.9 SM2020 -r nfsha -s swbuild
```
