#1/bin/bash

COMPARTMENT_ID=ocid1.compartment.oc1..aaaaaaaargrd7zvh6emqhlpjtuk7izopszpxgvecyhohic2lpn7j7h3ok3oq
LSF_SLAVE_PREFIX="lsf-slave-"
IMAGE_ID=ocid1.image.oc1.iad.aaaaaaaa4mvgqqlhwcmwpyegvwrt3ds4hxicksfrcob2m36gdvy5pvap2zbq
SUBNET_ID=ocid1.subnet.oc1.iad.aaaaaaaa2cmsa2cunzta2v7wj37emfpaqsi3ee5ukhvupnkrlpv3wgpmt46q
AD=oVTC:US-ASHBURN-AD-3
SHAPE=BM.HPC2.36
RANDOM_NUMBER=$(( RANDOM % 100 ))

oci compute instance list --compartment-id $COMPARTMENT_ID | jq -r '.data[] | select(."display-name" | contains("lsf-slave"))'
 
oci compute instance list --compartment-id $COMPARTMENT_ID | jq -r '.data[] | select(."lifecycle-state" | contains("PROVISIONING"))'

oci compute instance launch --availability-domain $AD --subnet-id $SUBNET_ID --image-id $IMAGE_ID" --shape $SHAPE --display-name $LSF_SLAVE_PREFIX$RANDOM_NUMBER --wait-for-state RUNNING > /dev/null


oci compute instance list --compartment-id $COMPARTMENT_ID  --output table --query "data [*].{Name:\"display-name\", STATE:\"lifecycle-state\"}" | grep $LSF_SLAVE_PREFIX

