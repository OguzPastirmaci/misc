[checklimits.sh](./checklimits.sh) is a simple Shell script that lists the limits for a compute service in your OCI tenancy.

It uses OCI CLI, so OCI CLI needs to be installed and configured. You can follow the instructions [in this link](https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/cliinstall.htm) to learn how to install and configure OCI CLI.

Edit the script to your put your Tenancy ID to the variable `TENANCY_ID`.

If your OCI CLI configuration file is not in the default location (`~/.oci/config`), change the `OCI_CONFIG_FILE` variable in the script.

The default OCI CLI profile in the script is `DEFAULT`. If you are using a different profile, change the `PROFILE` variable in the script.

#### Usage

To get the limit of a shape for a single region (e.g. us-ashburn-1):

```shell
sh checklimits.sh us-ashburn-1 <COMPARTMENT ID> <NAME OF THE LIMIT>
```

To get the limits of a shape for all active regions in your tenancy:


```shell
sh checklimits.sh --all <COMPARTMENT ID> <NAME OF THE LIMIT>
```

#### Example output

```
$ sh checklimits.sh us-ashburn-1 ocid1.compartment.oc1..aaaaaaaajhzmya

standard-e3-core-ad-count LIMITS FOR REGION: us-ashburn-1

standard-e3-core-ad-count limits for AD: VXpT:US-ASHBURN-AD-1

+-----------+------+
| available | used |
+-----------+------+
| 96        | 0    |
+-----------+------+

standard-e3-core-ad-count limits for AD: VXpT:US-ASHBURN-AD-2

+-----------+------+
| available | used |
+-----------+------+
| 82        | 0    |
+-----------+------+

standard-e3-core-ad-count limits for AD: VXpT:US-ASHBURN-AD-3

+-----------+------+
| available | used |
+-----------+------+
| 150       | 0    |
+-----------+------+
```
