This guide uses Nvidia's DeepOps project to deploy a Kubernetes cluster on existing nodes using Ansible. Detailed info about DeepOps can be found in its repository at https://github.com/NVIDIA/deepops.


1 - Deploy bastion, Kubernetes management and worker nodes

Deploy the necessary nodes prior to following the steps in this guide. This guide is based on a single management node and 2 GPU worker nodes in a cluster network.

You can add/remove nodes after you create the cluster. As a minimum, you will need:

Minimum number of nodes:

- 1 bastion node
- 1 management node
- 1 worker node

Make sure the bastion node can SSH into the other nodes.

2 - Disable firewall on management and worker nodes & edit the VCN security list

This guides assumes you will allow all ports in the subnet's security list in the OCI VCN and disable iptables on all Kubernetes nodes. Please check [this link](https://github.com/NVIDIA/deepops/blob/master/docs/misc/firewall.md) for the required ports for Kubernetes.

You can disable iptables with the following commands:

```
sudo systemctl stop netfilter-persistent
sudo systemctl disable netfilter-persistent
sudo iptables -F
```

3 - Configure the Ubuntu GPU worker nodes by following the steps [in this link.](https://github.com/OguzPastirmaci/misc/blob/master/ubuntu-cn-gpu-Ubuntu-20-OFED-5.4-3.4.0.0-2022.07.15-0.md)

4 - SSH into the bastion, and clone the Deepops project.

```git clone https://github.com/NVIDIA/deepops.git```

5 - Set up your bastion machine.

   This will install Ansible and other software on the provisioning machine which will be used to deploy all other software to the cluster. For more information on Ansible and why we use it, consult the [Ansible Guide](../deepops/ansible.md).

   ```bash
   # Install software prerequisites and copy default configuration
   ./scripts/setup.sh
   ```
