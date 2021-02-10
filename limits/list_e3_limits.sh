#!/bin/bash

OCI_CONFIG_FILE=~/.oci/config
PROFILE=DEFAULT
REGION=$1

YELLOW="\033[93m"
RED="\033[91m"
NORMAL="\033[39m"

# Check if OCI CLI is installed
if ! [ -x "$(command -v oci)" ]; then
  echo 'Error: OCI CLI is not installed. Please follow the instructions in this link to install: https://docs.cloud.oracle.com/iaas/Content/API/SDKDocs/cliinstall.htm' >&2
  exit 1
fi

# Check if OCI config file exists
[ ! -f "$OCI_CONFIG_FILE" ] && echo -e "\nOCI config file does not exist in $OCI_CONFIG_FILE" && exit 1

TENANCY_ID=$(grep -E "^\[|ocid1.tenancy" $OCI_CONFIG_FILE|sed -n -e "/\[$PROFILE\]/,/tenancy/p"|tail -1| awk -F'=' '{ print $2 }' | sed 's/ //g')

list_limits()
{

local lregion=$1

ADS=$(oci --profile $PROFILE iam availability-domain list --region $lregion  | jq '.data[].name'|sed 's#"##g')

printf "\n${RED}E3 LIMITS FOR REGION: $lregion\n"

for AD in $ADS
do 
    printf "\n${YELLOW}E3 Compute Limits for AD: $AD\n\n${NORMAL}"
    oci --profile $PROFILE limits resource-availability get --limit-name standard-e3-core-ad-count --service-name compute --region $lregion --availability-domain $AD \
        --compartment-id $TENANCY_ID --output table
    printf "\n${YELLOW}E3 Memory Limits for AD: $AD\n\n${NORMAL}"
    oci --profile $PROFILE limits resource-availability get --limit-name standard-e3-memory-count --service-name compute --region $lregion --availability-domain $AD \
        --compartment-id $TENANCY_ID --output table
done
}

if [ "$1" == "--all" ]
then
  REGIONS_LIST=$(oci --profile $PROFILE iam region-subscription list --query "data [].{Region:\"region-name\"}" |jq -r '.[].Region')
  
  printf "${YELLOW}List of active regions in the tenancy:${NORMAL}\n\n"
  
  for region in $REGIONS_LIST; do echo $region; done

  for region in $REGIONS_LIST
  do
    list_limits $region 
  done
else
list_limits $REGION
fi
