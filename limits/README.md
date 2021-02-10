[list_e3_limits.sh](./list_e3_limits.sh) is a simple Shell script that lists the E3 limits in your OCI tenancy.

It uses OCI CLI, so OCI CLI needs to be installed and configured. You can follow the instructions [in this link](https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/cliinstall.htm) to learn how to install and configure OCI CLI.

If your OCI CLI configuration file is not in the default location (`~/.oci/config`), change the `OCI_CONFIG_FILE` variable in the script.

The default OCI CLI profile in the script is `DEFAULT`. If you are using a different profile, change the `PROFILE` variable in the script.

#### Usage

To get the E3 limits for a single region (e.g. us-ashburn-1):

```shell
./list_e3_limits.sh us-ashburn-1
```

To get the E3 limits for all active regions in your tenancy:


```shell
./list_e3_limits.sh --all
```

#### Example output

```
$ ./list_e3_limits.sh us-ashburn-1

E3 LIMITS FOR REGION: us-ashburn-1

E3 Compute Limits for AD: VXpT:US-ASHBURN-AD-1

+-----------+------+
| available | used |
+-----------+------+
| 143       | 7    |
+-----------+------+

E3 Memory Limits for AD: VXpT:US-ASHBURN-AD-1

+-----------+------+
| available | used |
+-----------+------+
| 2296      | 104  |
+-----------+------+

E3 Compute Limits for AD: VXpT:US-ASHBURN-AD-2

+-----------+------+
| available | used |
+-----------+------+
| 149       | 1    |
+-----------+------+

E3 Memory Limits for AD: VXpT:US-ASHBURN-AD-2

+-----------+------+
| available | used |
+-----------+------+
| 2384      | 16   |
+-----------+------+

E3 Compute Limits for AD: VXpT:US-ASHBURN-AD-3

+-----------+------+
| available | used |
+-----------+------+
| 150       | 0    |
+-----------+------+

E3 Memory Limits for AD: VXpT:US-ASHBURN-AD-3

+-----------+------+
| available | used |
+-----------+------+
| 2400      | 0    |
+-----------+------+
```
