# Resizing a GPU cluster on Oracle Cloud Infrastructure

Instead of destroying and applying each time that you need to change the number of nodes in a cluster, using the below commands is an easier way to manage the cluster from the bastion.

All of the following commands can be run from the **bastion** instance.

The name of the current cluster is `compute-1-hpc`. That cluster name is included in all below commands.

**NOTE:** The logs for adding or removing node/nodes will be available in `/opt/oci-hpc/logs` on the bastion after the command finishes running.


## Adding nodes to the cluster

The command automates the following steps for you:

- Add node (instance provisioning) to cluster (uses OCI Python SDK)
- Configure the nodes (uses Ansible)
  -  Configures newly added nodes to be ready to run the jobs
  -  Reconfigure services like Slurm to recognize new nodes on all nodes

```
/opt/oci-hpc/bin/resize.sh add <number of nodes to add> --cluster_name compute-1-hpc
```

Example:

```
/opt/oci-hpc/bin/resize.sh add 3 --cluster_name compute-1-hpc
```

## Removing nodes from the cluster

The command automates the following steps for you:

- Remove node/s (instance termination) from cluster (uses OCI Python SDK)
- Reconfigure rest of the nodes in the cluster  (uses Ansible)
  -  Remove reference to removed node/s on rest of the nodes (eg: update /etc/hosts, slurm configs, etc.)

### Removing a specific node

```
/opt/oci-hpc/bin/resize.sh remove_unreachable --cluster_name compute-1-hpc --nodes <node name>
```

Example: 
```
/opt/oci-hpc/bin/resize.sh remove_unreachable --cluster_name compute-1-hpc --nodes inst-wdwdu-compute-1-hpc
```

### Removing a list of nodes (space seperated):

```
/opt/oci-hpc/bin/resize.sh remove_unreachable --cluster_name compute-1-hpc --nodes <node names>
```

Example: 
```
/opt/oci-hpc/bin/resize.sh remove_unreachable --cluster_name compute-1-hpc --nodes inst-wdwdu-compute-1-hpc inst-lotc6-compute-1-hpc
```
