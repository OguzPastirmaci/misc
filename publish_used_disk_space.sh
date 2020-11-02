# OCI CLI binary location
# Default installation location for Oracle Linux 7 is /home/opc/bin/oci
# Default installation location for Ubuntu 18.04 and Ubuntu 16.04 is /home/ubuntu/bin/oci
cliLocation="/home/opc/bin/oci"

# Check if OCI CLI and curl is installed
if ! [ -x "$(command -v $cliLocation)" ]; then
  echo 'Error: OCI CLI is not installed. Please follow the instructions in this link: https://docs.cloud.oracle.com/iaas/Content/API/SDKDocs/cliinstall.htm' >&2
  exit 1
fi

if ! [ -x "$(command -v curl)" ]; then
  echo 'Error: curl is not installed.' >&2
  exit 1
fi

compartmentId=$(curl -H "Authorization: Bearer Oracle" -s -L http://169.254.169.254/opc/v1/instance/ | jq -r '.compartmentId')
metricNamespace="disk_monitoring"
metricResourceGroup="disk_monitoring_rg"
instanceName=$(curl -H "Authorization: Bearer Oracle" -s -L http://169.254.169.254/opc/v1/instance/ | jq -r '.displayName')
instanceId=$(curl -H "Authorization: Bearer Oracle" -s -L http://169.254.169.254/opc/v1/instance/ | jq -r '.id')
endpointRegion=$(curl -H "Authorization: Bearer Oracle" -s -L http://169.254.169.254/opc/v1/instance/ | jq -r '.canonicalRegionName')

# Example for /dev/sda3
diskUsage=$(df | awk '/\/dev\/sda3/{sub( "%", "", $5); print $5 }')
timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

metricsJson=$(cat << EOF > /tmp/metrics.json
[

{
      "namespace":"$metricNamespace",
      "compartmentId":"$compartmentId",
      "resourceGroup":"$metricResourceGroup",
      "name":"sda3DiskUtilization",
      "dimensions":{
         "resourceId":"$instanceId",
         "instanceName":"$instanceName"
      },
      "metadata":{
         "unit":"percent",
         "displayName":"Disk Space Utilization"
      },
      "datapoints":[
         {
            "timestamp":"$timestamp",
            "value":$diskUsage
         }
      ]
   }
]
EOF
)

$cliLocation monitoring metric-data post --metric-data file:///tmp/metrics.json --endpoint https://telemetry-ingestion.$endpointRegion.oraclecloud.com
