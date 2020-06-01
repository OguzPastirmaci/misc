# OCI Easy HPC deployment tool - ocihpc

`ocihpc` is a tool for simplifying deployments of HPC applications in Oracle Cloud Infrastructure (OCI).

## Prerequisites

### Software needed
The tool needs `oci` CLI, `unzip`, and `jq` to run. You will receive an error message if they are not installed.

To install and configure OCI CLI, please follow the steps in [this link](https://docs.cloud.oracle.com/en-us/iaas/Content/API/SDKDocs/cliinstall.htm).

The OCI user account you use in OCI CLI should have the necessary policies configured for OCI Resource Manager. Please check [this link](https://docs.cloud.oracle.com/en-us/iaas/Content/Identity/Tasks/managingstacksandjobs.htm) for information on required policies.

`Unzip` and `jq` come installed in many linux distributions. If you need to install them, please check the tools' websites for installation.

### PATH settings
You need to set the `ocihpc` tool as an executable and add the tool directory to your path.

Clone the repository:
```sh
$ git clone https://github.com/oracle-quickstart/oci-ocihpc.git
```

Set the tool as an executable:
```
$ cd oci-ocihpc
$ chmod +x ocihpc
```

Add the tool directory to your path:
```sh
$ export PATH=$PATH:<the path where you cloned the repository into>
```

### 1 - Deploy
Before deploying, you need to change the values in `config.json` file. The variables depend on the package you deploy. An example `config.json` for Cluster Network would look like this:

```json
{
  "variables": {
    "region": "us-phoenix-1",
    "tenancy_ocid": "ocid1.tenancy.oc1.....utinobtayaykdasoygtnpko7buq",
    "compartment_ocid": "ocid1.compartment.oc1..hnus3q",
    "ad": "kWVD:PHX-AD-1",
    "bastion_ad": "kWVD:PHX-AD-2",
    "node_count": "2",
    "ssh_key": "ssh-rsa AAAAB3NzaC1yc2EAAAA......W6 opastirm@opastirm-mac"
  }
}
```

After you change the values in `config.json`, you can deploy the package with `ocihpc deploy <package name>`. This command will create a Stack on Oracle Cloud Resource Manager and deploy the package using it.

For supported packages, you can set the number of nodes you want to deploy by adding it to the `ocihpc deploy` command. If the package does not support it or if you don't provide a value, the tool will deploy with the default numbers. 

For example, the following command will deploy a Cluster Network with 5 nodes:

```
$ ocihpc deploy ClusterNetwork 5
```

INFO: The tool will generate a deployment name that consists of `<package name>-<current directory>-<random-number>`.

Example:

```
$ ocihpc deploy ClusterNetwork

Starting deployment...

Deploying ClusterNetwork-ocihpc-test-7355 [0min 0sec]
Deploying ClusterNetwork-ocihpc-test-7355 [0min 17sec]
Deploying ClusterNetwork-ocihpc-test-7355 [0min 35sec]
...
```

TIP: When running the `ocihpc deploy <package name>` command, your shell might autocomplete it to the name of the zip file in the folder. This is fine. The tool will correct it, you don't need to delete the .zip extension from the command.

For example, `ocihpc deploy ClusterNetwork` and `ocihpc deploy ClusterNetwork.zip` are both valid commands.


### 2 - Connect
When deployment is completed, you will see the the bastion/headnode IP that you can connect to:

```
Successfully deployed ClusterNetwork-ocihpc-test-7355

You can connect to your head node using the command: ssh opc@$123.221.10.8 -i <location of the private key you used>

You can also find the IP address of the bastion/headnode in ClusterNetwork-ocihpc-test-7355_access.info file
```

### 3 - Delete
When you are done with your deployment, you can delete it by changing to the package folder and running `ocihpc delete <package name>`.

Example:
```
$ ocihpc delete ClusterNetwork

Deleting ClusterNetwork-ocihpc-test-7355 [0min 0sec]
Deleting ClusterNetwork-ocihpc-test-7355 [0min 17sec]
Deleting ClusterNetwork-ocihpc-test-7355 [0min 35sec]
...

Succesfully deleted ClusterNetwork-ocihpc-test-7355
```

