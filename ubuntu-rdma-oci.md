This guide uses Nvidia's DeepOps project to deploy a Kubernetes cluster on existing nodes using Ansible. Detailed info about DeepOps can be found in its repository at https://github.com/NVIDIA/deepops.


1 - Deploy bastion, Kubernetes management and worker nodes

Deploy the necessary nodes prior to following the steps in this guide. This guide is based on a single management node and 2 GPU worker nodes in a cluster network.

You can add/remove nodes after you create the cluster. As a minimum, you will need:

Minimum number of nodes:

- 1 bastion/provisioning node
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

4 - SSH into the bastion, and clone the DeepOps repository.

```git clone https://github.com/NVIDIA/deepops.git```

5 - Set up your bastion machine.

   This will install Ansible and other software on the provisioning machine which will be used to deploy all other software to the cluster. For more information on Ansible and why we use it, consult the [Ansible Guide](../deepops/ansible.md).

   ```bash
   # Install software prerequisites and copy default configuration
   ./scripts/setup.sh
   ```
6 -  Create and edit the Ansible inventory.

Ansible uses an inventory which outlines the servers in your cluster. The setup script from the previous step will copy an example inventory configuration to the `config` directory.

Edit the inventory file in `config/inventory`. An example inventory file with the Kubernetes related parts:

```
#
# Server Inventory File
#
# Uncomment and change the IP addresses in this file to match your environment
# Define per-group or per-host configuration in group_vars/*.yml

######
# ALL NODES
# NOTE: Use existing hostnames here, DeepOps will configure server hostnames to match these values
######
[all]
mgmt01     ansible_host=10.0.0.76
#mgmt02     ansible_host=10.0.0.2
#mgmt03     ansible_host=10.0.0.3
#login01    ansible_host=10.0.1.1
gpu01      ansible_host=10.0.0.201
gpu02      ansible_host=10.0.0.189

######
# KUBERNETES
######
[kube-master]
mgmt01
#mgmt02
#mgmt03

# Odd number of nodes required
[etcd]
mgmt01
#mgmt02
#mgmt03

# Also add mgmt/master nodes here if they will run non-control plane jobs
[kube-node]
gpu01
gpu02

[k8s-cluster:children]
kube-master
kube-node
```

7 -  Verify the configuration

```bash
ansible all -m raw -a "hostname"
```

8 - Install Kubernetes using Ansible and Kubespray.

```
ansible-playbook -l k8s-cluster playbooks/k8s-cluster.yml
```

9 - Verify that the Kubernetes cluster is running.

```
(env) ubuntu@deepops-bastion:~$ kubectl get nodes

NAME     STATUS   ROLES                  AGE    VERSION
gpu01    Ready    <none>                 122m   v1.23.7
gpu02    Ready    <none>                 122m   v1.23.7
mgmt01   Ready    control-plane,master   132m   v1.23.7
```

10 - Label your nodes that has RDMA NICs.

The Mellanox Kubernetes RDMA Shared Device Plugin uses NFD (Node Feature Discovery) for labeling the nodes automatically. If you used the Ubuntu OFED image for your management nodes, your nodes will be labeled as RDMA capable. We don't want that. So label your worker nodes with another label like `oci-rdma-capable`. Do this for all of your worker nodes.

```
kubectl label node gpu01 oci-rdma-capable=true
```

11 - Deploy the config map for Mellanox RDMA Shared Device Plugin

Save the following file as `configmap.yaml` and deploy it using `kubectl apply -f configmap.yaml`.

```yaml
apiVersion: v1
data:
  config.json: |
      {
      "periodicUpdateInterval": 300,
      "configList": [{
      "resourceName": "oci-roce",
      "rdmaHcaMax": 10,
      "selectors": {
      "drivers": ["mlx5_core"]
      }
      }
      ]
      }
kind: ConfigMap
metadata:
  name: rdma-devices
  namespace: kube-system
```

12 - Deploy the Mellanox RDMA Shared Device Plugin

Save the following file as `rdma-ds.yaml` and deploy it using `kubectl apply -f rdma-ds.yaml`.

```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: rdma-shared-dp-ds
  namespace: kube-system
spec:
  selector:
    matchLabels:
      name: rdma-shared-dp-ds
  template:
    metadata:
      labels:
        name: rdma-shared-dp-ds
    spec:
      hostNetwork: true
      priorityClassName: system-node-critical
      nodeSelector:
        rdma: "true"
      containers:
      - image: mellanox/k8s-rdma-shared-dev-plugin
        name: k8s-rdma-shared-dp-ds
        imagePullPolicy: IfNotPresent
        securityContext:
          privileged: true
        volumeMounts:
          - name: device-plugin
            mountPath: /var/lib/kubelet/
          - name: config
            mountPath: /k8s-rdma-shared-dev-plugin
          - name: devs
            mountPath: /dev/
      volumes:
        - name: device-plugin
          hostPath:
            path: /var/lib/kubelet/
        - name: config
          configMap:
            name: rdma-devices
            items:
            - key: config.json
              path: config.json
        - name: devs
          hostPath:
            path: /dev/
```
