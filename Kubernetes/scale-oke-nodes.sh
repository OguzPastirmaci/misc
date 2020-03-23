
# ADD NODE
SIZE=$(oci ce node-pool get --node-pool-id $NODE_POOL_ID --region $REGION | jq -r '.data | ."node-config-details" | .size')

if [ "$SIZE" -ge "$SCALING_MAX" ]
then
	echo "Skipping because of node pool sizing rules"
elif [ $(( $(date +%s) - $(date +%s -r $SCALE_LOG) )) -le "$SCALING_FREQUENCY" ]
then
	echo "Last scaling operation happened in the last $SCALING_FREQUENCY seconds, skipping"
else
	((SIZE++))
	oci ce node-pool update --node-pool-id $NODE_POOL_ID --region $REGION --size $SIZE --force
    echo "Scaled at $(date)" > $SCALE_LOG
fi


# REMOVE NODE
SIZE=$(oci ce node-pool get --node-pool-id $NODE_POOL_ID --region $REGION | jq -r '.data | ."node-config-details" | .size')

if [ "$SIZE" -le "$SCALING_MIN" ]
then
	echo "Skipping because of node pool sizing rules"
elif [ $(( $(date +%s) - $(date +%s -r $SCALE_LOG) )) -le "$SCALING_FREQUENCY" ]
then
	echo "Last scaling operation happened in the last $SCALING_FREQUENCY seconds, skipping"
else
	((SIZE--))
	oci ce node-pool update --node-pool-id $NODE_POOL_ID --region $REGION --size $SIZE --force
    echo "Scaled at $(date)" > $SCALE_LOG
fi

