### Upgrade your cluster's control plane to a newer version
https://docs.oracle.com/en-us/iaas/Content/ContEng/Tasks/contengupgradingk8smasternode.htm

### Remove the node you're going to upgrade from your cluster
```
kubectl drain $NODE --ignore-daemonsets --delete-emptydir-data
kubectl delete node $NODE
```

### Use Boot Volume Replacement to change the OS image to a newer Kubernetes version

You can find the OKE images here: https://docs.oracle.com/en-us/iaas/images/

#### OCI CLI example

```
oci compute instance update --from-json file://boot-volume-replace.json --instance-id <INSTANCE_ID> --region <REGION>
```

boot-volume-replace.json
```
{
  "sourceDetails": {
    "sourceType": "image",
    "imageId": "<IMAGE_ID>",
    "isPreserveBootVolumeEnabled": true,
    "bootVolumeSizeInGBs": <change it to the size you want>
  }
}
```

#### Python example
```
image_id="<IMAGE_ID>"
instance_id="<INSTANCE_ID>"

import oci
signer = oci.auth.signers.InstancePrincipalsSecurityTokenSigner()
computeClient = oci.core.ComputeClient(config={}, signer=signer)

update_instance_source_details = oci.core.models.UpdateInstanceSourceViaImageDetails()
update_instance_source_details.image_id = image_id
update_instance_source_details.is_preserve_boot_volume_enabled = True
update_instance_source_details.is_force_stop_enabled = True
update_instance_source_details.boot_volume_size_in_gbs = 200
update_instance_details = oci.core.models.UpdateInstanceDetails()
update_instance_details.source_details = update_instance_source_details
update_instance_response = computeClient.update_instance(instance_id, update_instance_details)
```

#### Change the instance configuration of the Cluster Network
Update the instance configuration of your Cluster Network's underlying Instance Pool with the same image you used above. So that once you finished upgrading your nodes with Boot Volume Replacement, any new nodes you add to your cluster will have the correct image.

https://docs.oracle.com/en-us/iaas/Content/Compute/Tasks/update-cluster-network-instance-configuration.htm

