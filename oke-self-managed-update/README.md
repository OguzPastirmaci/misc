## 1. Drain the node and delete it from the clustr
```
kubectl drain <NODE> --ignore-daemonsets
kubectl delete <NODE>
```

## 2. Use boot volume replacement to update the image of the node
You can use the web console, OCI CLI or OCI SDKs.

### Using the web console
You can follow the instructions [in this link](https://docs.oracle.com/en-us/iaas/Content/Compute/Tasks/replacingbootvolume.htm).

### Using OCI CLI
Create a json file with the new image ID.

`boot-volume-replace.json`
```json
{
  "sourceDetails": {
    "sourceType": "image",
    "imageId": "<IMAGE_ID>",
    "isPreserveBootVolumeEnabled": true,
    "bootVolumeSizeInGBs": "<change it to the size you want>"
  }
}
```

Run the following OCI CLI command:
```
oci compute instance update --from-json file://boot-volume-replace.json --instance-id <INSTANCE_ID> --region <REGION>
```
### Using Python
```python

image_id="<IMAGE_ID>"
instance_id="<INSTANCE_ID>"

import oci
update_instance_source_details = oci.core.models.UpdateInstanceSourceViaImageDetails()
update_instance_source_details.image_id = image_ocid
update_instance_source_details.is_preserve_boot_volume_enabled = False
update_instance_source_details.is_force_stop_enabled = True
update_instance_details = oci.core.models.UpdateInstanceDetails()
update_instance_details.source_details = update_instance_source_details
ComputeClientCompositeOperations.update_instance_and_wait_for_state(node.ocid, update_instance_details,wait_for_states=["STOPPING","STOPPED","STARTING","RUNNING"])
```


