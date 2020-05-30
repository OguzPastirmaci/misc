#### List limits for a shape in compartment
oci limits value list --service-name compute --compartment-id $COMPARTMENT_ID --all | jq -r '.data[] | select(.name=="bm-hpc2-36-count")'

#### Get resource availability in compartment
oci limits resource-availability get --limit-name bm-hpc2-36-count --service-name compute --compartment-id $COMPARTMENT_ID --availability-domain $AD
