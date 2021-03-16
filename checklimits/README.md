[checklimits.sh](./checklimits.sh) is a simple Shell script that lists the limits for a compute service in your OCI tenancy.

It uses OCI CLI, so OCI CLI needs to be installed and configured. You can follow the instructions [in this link](https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/cliinstall.htm) to learn how to install and configure OCI CLI.

Edit the script to your put your Tenancy ID to the variable `TENANCY_ID`.

If your OCI CLI configuration file is not in the default location (`~/.oci/config`), change the `OCI_CONFIG_FILE` variable in the script.

The default OCI CLI profile in the script is `DEFAULT`. If you are using a different profile, change the `PROFILE` variable in the script.

#### Usage

1. Get the list of services with the following command:

```
oci limits service list --output table --compartment-id <TENANCY ID>
```

Example output:

```
+------------------------------------+---------------------------+
| description                        | name                      |
+------------------------------------+---------------------------+
| Analytics                          | analytics                 |
| API Gateway                        | api-gateway               |
| Application Performance Monitoring | apm                       |
| Auto Scaling                       | auto-scaling              |
| Big Data                           | big-data                  |
| Block Volume                       | block-storage             |
| Blockchain                         | blockchain                |
| Cloud Shell                        | cloud-shell               |
| Cloud Guard                        | cloudguard                |
| Compartments                       | compartments              |
| Compute                            | compute                   |
| Compute Management                 | compute-management        |
| Container Engine                   | container-engine          |
| Data Catalog                       | data-catalog              |
| Data Flow                          | data-flow                 |
| Data Science                       | data-science              |
| Data Transfer                      | data-transfer             |
| Database                           | database                  |
| Digital Assistant                  | digital-assistant         |
| DNS                                | dns                       |
| Email Delivery                     | email-delivery            |
| Events                             | events                    |
| Functions                          | faas                      |
| Fast Connect                       | fast-connect              |
| File Storage                       | filesystem                |
| Health Check                       | health-checks             |
| Integration                        | integration               |
| Key Management                     | kms                       |
| LbaaS                              | load-balancer             |
| Logging                            | logging                   |
| Logging Analytics                  | logging-analytics         |
| Management Agent                   | management-agent          |
| Management Dashboard               | management-dashboard      |
| MySQL                              | mysql                     |
| Network Load Balancer              | network-load-balancer-api |
| NoSQL                              | nosql                     |
| Notifications                      | notifications             |
| Object Storage                     | object-storage            |
| VMware Solution                    | ocvp                      |
| Regions                            | regions                   |
| Resource Manager                   | resource-manager          |
| Service Connector Hub              | service-connector-hub     |
| Streaming                          | streaming                 |
| Virtual Cloud Network              | vcn                       |
| IP Management                      | vcnip                     |
| VPN                                | vpn                       |
| Vulnerability Scanning             | vulnerability-scanning    |
| WaaS                               | waas                      |
+------------------------------------+---------------------------+
```

2. You will need the name of the limit you want to check (example: `vm-gpu3-1-count`). To list the names of the compute limits, you can use the following command (if you need to list the names of other services, change `--service-name` parameter with the service from the previous step.):

```
oci limits value list --service-name=compute --all --compartment-id <TENANCY ID>
```


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
$ sh checklimits.sh us-ashburn-1 ocid1.compartment.oc1..aaaaaaaajhzmya vm-gpu3-1-count

vm-gpu3-1-count LIMITS FOR REGION: us-ashburn-1

vm-gpu3-1-count limits for AD: VXpT:US-ASHBURN-AD-1

+-----------+------+
| available | used |
+-----------+------+
| 0         | 0    |
+-----------+------+

vm-gpu3-1-count limits for AD: VXpT:US-ASHBURN-AD-2

+-----------+------+
| available | used |
+-----------+------+
| 10000     | 0    |
+-----------+------+

vm-gpu3-1-count limits for AD: VXpT:US-ASHBURN-AD-3

+-----------+------+
| available | used |
+-----------+------+
| 132       | 0    |
+-----------+------+
```
