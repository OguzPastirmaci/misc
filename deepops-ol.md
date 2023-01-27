**Image used:** OracleLinux-7-RHCK-3.10.0-OFED-5.4-3.6.8.1-GPU-510-2022.12.16-0

---

#### Install python3-libselinux (start with the mgmt node only, if that doesn't fix it, install it on all nodes)

```
sudo yum install -y python3-libselinux 
```

#### Add the EPEL repo to all nodes

`/etc/yum.repos.d/epel-yum-ol7.repo`

```
[ol7_epel]
name=Oracle Linux $releasever EPEL ($basearch)
baseurl=http://yum.oracle.com/repo/OracleLinux/OL7/developer_EPEL/$basearch/
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-oracle
gpgcheck=1
enabled=1
```

#### Change the driver version to match what you have installed on the host (e.g. 510.108.03)

`gpu_operator_driver_version` in `roles/nvidia-gpu-operator/defaults/main.yml`

`nvidia_driver_branch` in `roles/galaxy/nvidia.nvidia_driver/defaults/main.yml`

#### Change the command for installing the gpu-operator Helm chart

- Get the latest, non rc version for `centos7` from https://catalog.ngc.nvidia.com/orgs/nvidia/teams/k8s/containers/container-toolkit/tags

- Add the variable `gpu_operator_toolkit_version: "Get the version from above link"` to `roles/nvidia-gpu-operator/defaults/main.yml`.

- Add `--set toolkit.version="{{ gpu_operator_toolkit_version }}"` to the helm install command in the `install nvidia gpu operator` task in `nvidia-gpu-operator/tasks/k8s.yml`

#### Edit scripts/k8s/install_helm.sh to add ol

Add `ol` to the below block to `scripts/k8s/install_helm.sh` so it doesn't error out.

```
case "$ID" in
    rhel*|centos*|ol*)
        if ! type curl >/dev/null 2>&1 ; then
            sudo yum -y install curl
        fi
```

#### If you get an error in runc os_tree task, add the following to roles/container-engine/runc/tasks/main.yml

https://github.com/kubernetes-sigs/kubespray/pull/9321/commits/b528772dfdfbaa4287c42287bd183e8a1317f1dc

```
- name: runc | check if fedora coreos
  stat:
    path: /run/ostree-booted
    get_attributes: no
    get_checksum: no
    get_mime: no
  register: ostree

- name: runc | set is_ostree
  set_fact:
    is_ostree: "{{ ostree.stat.exists }}"
```
