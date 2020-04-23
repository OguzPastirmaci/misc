#1/bin/bash

COMPARTMENT_ID=ocid1.compartment.oc1..aaaaaaaargrd7zvh6emqhlpjtuk7izopszpxgvecyhohic2lpn7j7h3ok3oq
LSF_SLAVE_PREFIX="lsf-slave"

 oci compute instance list --compartment-id $COMPARTMENT_ID | jq -r '.data[] | select(."display-name" | contains("lsf-slave"))'
 
 oci compute instance list --compartment-id $COMPARTMENT_ID | jq -r '.data[] | select(."lifecycle-state" | contains("PROVISIONING"))'
