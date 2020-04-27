#1/bin/bash

COMPARTMENT_ID=ocid1.compartment.oc1..aaaaaaaargrd7zvh6emqhlpjtuk7izopszpxgvecyhohic2lpn7j7h3ok3oq
LSF_SLAVE_PREFIX="lsf-slave-"
IMAGE_ID=ocid1.image.oc1.iad.aaaaaaaa4mvgqqlhwcmwpyegvwrt3ds4hxicksfrcob2m36gdvy5pvap2zbq
SUBNET_ID=ocid1.subnet.oc1.iad.aaaaaaaa2cmsa2cunzta2v7wj37emfpaqsi3ee5ukhvupnkrlpv3wgpmt46q
AD=oVTC:US-ASHBURN-AD-3
SHAPE=BM.HPC2.36
RANDOM_NUMBER=$(( RANDOM % 10000 ))
INSTANCE_NAME=$LSF_SLAVE_PREFIX$RANDOM_NUMBER
SUBNET_DOMAIN_NAME=$(oci network subnet get --subnet-id $SUBNET_ID --query data.\"subnet-domain-name\"  --raw-output)

# Get the number of running instances
# I have a very basic logic here, you can build a different/better one based on your needs
# 1 - List all instances in the compartment
# 2 - Show the name and status of them
# 3 - Filter the instances that have the pre-defined prefix in their name (in our case, lsf-slave)
# 4 - Count the number of results
NUMBER_OF_RUNNING_INSTANCES=$(oci compute instance list --compartment-id $COMPARTMENT_ID  --output table --query "data [*].{Name:\"display-name\", STATE:\"lifecycle-state\"}" | grep $LSF_SLAVE_PREFIX | grep RUNNING | wc -l)

# Then you can create a new instance from the custom image and get its ID
# This example randomly generates a number after "lsf-slave" but you can decide how to do it
CREATED_INSTANCE_ID=$(oci compute instance launch --compartment-id $COMPARTMENT_ID --hostname-label $INSTANCE_NAME --availability-domain $AD --subnet-id $SUBNET_ID --image-id $IMAGE_ID --shape $SHAPE --display-name $INSTANCE_NAME --query 'data.id' --raw-output)

# Get the status of the newly created instance. You can create a loop that waits until the state becomes RUNNING and then check if it started responding with for example SSH
CREATED_INSTANCE_STATE=$(oci compute instance get --instance-id $CREATED_INSTANCE_ID --query data.\"lifecycle-state\" --raw-output)

# You can get the private IP or the FQDN of the newly created instance
CREATED_INSTANCE_IP=$(oci compute instance list-vnics --instance-id $CREATED_INSTANCE_ID --compartment-id $COMPARTMENT_ID | jq -r '.data[]."private-ip"')
CREATED_INSTANCE_FQDN=$INSTANCE_NAME.$SUBNET_DOMAIN_NAME

# Deleting an instance
oci compute instance terminate --instance-id $CREATED_INSTANCE_ID --force
