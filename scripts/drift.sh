#!/bin/bash

set -e

STACK_ID=""

# Initiate drift detection and get the works request ID
CREATED_DRIFT_DETECTION_WORK_REQUEST_ID=$(oci resource-manager stack detect-drift --stack-id $STACK_ID --raw-output --query '"opc-work-request-id"')

# Wait until drift detection finishes running
while ! [[ $WORK_REQUEST_STATUS =~ ^(SUCCEEDED|FAILED) ]]
do
    echo -e "Waiting for the drift detection job to finish"
    WORK_REQUEST_STATUS=$(oci resource-manager work-request get --work-request-id $CREATED_DRIFT_DETECTION_WORK_REQUEST_ID --raw-output --query 'data.status')
    sleep 10
done

# Get drift detection status and show a message depending on the status
DRIFT_STATUS=$(oci resource-manager stack list-resource-drift-details --stack-id $STACK_ID --raw-output --query 'data.items[]."resource-drift-status"' | awk -F '"' '{print $2}' | xargs)

if [[ $DRIFT_STATUS =~ ^(MODIFIED|DELETED) ]]
then
    echo -e "Drift detected"
else
    echo -e "Drift not detected"
fi
