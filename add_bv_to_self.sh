AD=$(curl -s -H "Authorization: Bearer Oracle" -L http://169.254.169.254/opc/v2/instance/ | jq -r '.availabilityDomain')
COMPARTMENT_ID=$(curl -s -H "Authorization: Bearer Oracle" -L http://169.254.169.254/opc/v2/instance/ | jq -r '.compartmentId')
INSTANCE_ID=$(curl -s -H "Authorization: Bearer Oracle" -L http://169.254.169.254/opc/v2/instance/ | jq -r '.id')
CREATED_VOLUME_ID=$(oci bv volume create --availability-domain $AD --compartment-id $COMPARTMENT_ID --display-name $(hostname) --size-in-gbs 100 --auth instance_principal | jq -r '.data | .id')

# Wait until block volume status becomes available before trying to attach
until [ oci bv volume get --volume-id $CREATED_VOLUME_ID --auth instance_principal | jq -r '.data."lifecycle-state"') == "AVAILABLE" ]; do
sleep 10
done

oci compute volume-attachment attach-paravirtualized-volume --instance-id $INSTANCE_ID --volume-id $CREATED_VOLUME_ID --auth instance_principal
