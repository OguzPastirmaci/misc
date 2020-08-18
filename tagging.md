There 2 easy ways to add custom data to an instance running on OCI:

1- Adding a tag to an instance

2- Updating the extended metadata

Adding a tag is easier especially when using the OCI Console (GUI).


# Adding a tag to an instance

Below steps are for adding a tag to an instance when creating it, but it's also possible to add tags to an instance after it's deployed. More info about resource tagging is available [in this link.](https://docs.cloud.oracle.com/en-us/iaas/Content/General/Concepts/resourcetags.htm)


1- When creating an instance in the console, scroll all the way down and click on **Show Advanced Options**.

2- In the **Show Advanced Options** menu, add a new **Tag Key** and **Tag Value**. You can choose anything for both fields. You can also choose between **Free-form tags** and **Defined Tags**. The difference is that Defined Tags can only be created by tag administrators, whereas Free Form tags can be created by any user. Choose **Free-form tags** for now.

![Adding tag to instance](./images/instance_tag.png)

3- SSH into the instance and curl to the OCI Instance Metadata service. You can find more information about OCI Instance Metadata [in this link.](https://docs.cloud.oracle.com/en-us/iaas/Content/Compute/Tasks/gettingmetadata.htm)
