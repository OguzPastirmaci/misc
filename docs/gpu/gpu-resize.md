# Resizing a GPU cluster on Oracle Cloud Infrastructure

Instead of destroying and applying each time that you need to change the number of nodes in a cluster, using the below commands is an easier way to manage the cluster from the bastion.

All of the following commands can be run from the **bastion** instance.

**NOTE:** The logs for adding or removing node/nodes will be available in `/opt/oci-hpc/logs` on the bastion after the command finishes running.

## Listing the current nodes running in the cluster

```
/opt/oci-hpc/bin/resize.sh list --cluster_name a100
```

Example output:

```
[opc@stirring-asp-bastion ~]$ /opt/oci-hpc/bin/resize.sh list --cluster_name a100

Cluster is in state:RUNNING
inst-jkdoa-stirring-asp 172.16.5.47 ocid1.instance.oc1.eu-frankfurt-1.antheljtpwneysachkkqbeuq5lwfmvntdcif3ylebqwqzeq
inst-q59gt-stirring-asp 172.16.4.123 ocid1.instance.oc1.eu-frankfurt-1.antheljtpwneysachlen56dtlandejcke4x4seg3gg4irq
```

## Adding nodes to the cluster

The command automates the following steps for you:

- Add node (instance provisioning) to cluster (uses OCI Python SDK)
- Configure the nodes (uses Ansible)
  -  Configures newly added nodes to be ready to run the jobs
  -  Reconfigure services like Slurm to recognize new nodes on all nodes

```
/opt/oci-hpc/bin/resize.sh add <number of nodes to add> --cluster_name a100
```

Example:

```
/opt/oci-hpc/bin/resize.sh add 3 --cluster_name a100
```

## Removing nodes from the cluster

The command automates the following steps for you:

- Remove node/s (instance termination) from cluster (uses OCI Python SDK)
- Reconfigure rest of the nodes in the cluster  (uses Ansible)
  -  Remove reference to removed node/s on rest of the nodes (eg: update /etc/hosts, slurm configs, etc.)

### Removing a specific node

```
/opt/oci-hpc/bin/resize.sh remove_unreachable --nodes <node name> --cluster_name a100
```

Example: 
```
/opt/oci-hpc/bin/resize.sh remove_unreachable --nodes inst-wdwdu-compute-1-hpc --cluster_name a100
```

### Removing a list of nodes (space seperated):

```
/opt/oci-hpc/bin/resize.sh remove_unreachable --nodes <node names> --cluster_name a100
```

Example: 
```
/opt/oci-hpc/bin/resize.sh remove_unreachable --nodes inst-wdwdu-compute-1-hpc inst-lotc6-compute-1-hpc --cluster_name a100
```
