REGION=ap-sydney-1
COMPARTMENT_ID=ocid1.compartment.oc1..aaaaaaaan5ouwmczcchigfas4xuzw5mh5xpqhnymull6y4g7gxc73wmgammq
AD=ZHZP:AP-SYDNEY-1-AD-1
WORKER_SUBNET_ID=ocid1.subnet.oc1.ap-sydney-1.aaaaaaaapgst6odxn7pav4o3lai64js3fyb6dljhdzi5ffufygrhgpkjv5pq
WORKER_SUBNET_NSG_ID=ocid1.networksecuritygroup.oc1.ap-sydney-1.aaaaaaaanqxbsqv6itn4w4wusip4tow5kv2ltmo7lenpa2mrkqgmio6qgnaq
POD_SUBNET_ID=
POD_SUBNET_NSG_ID=
IMAGE_ID=ocid1.image.oc1.ap-sydney-1.aaaaaaaa24usi6houqzdjyp3eatz2sqx37vsmmjq5wdyq7z4rdxmkrmeos5a
BASE64_ENCODED_CLOUD_INIT=$(cat cloud-init.yml| base64 -b 0)

oci --region ${REGION} compute-management instance-configuration create --compartment-id ${COMPARTMENT_ID} --display-name gb200-oke --instance-details \
'{
  "instanceType": "compute",
  "launchDetails": {
    "availabilityDomain": "$AD",
    "compartmentId": "$COMPARTMENT_ID",
    "createVnicDetails": {
      "assignIpv6Ip": false,
      "assignPublicIp": false,
      "assignPrivateDnsRecord": true,
      "subnetId": "$SUBNET_ID",
      "nsgIds": [ "$SUBNET_NSG_ID" ]
    },
    "metadata": {
      "user_data": "$BASE64_ENCODED_CLOUD_INIT",
      "oke-native-pod-networking": "true", "oke-max-pods": "60",
      "pod-subnets": "ocid1.subnet.oc1.ap-sydney-1.aaaaaaaaphfdh4jq3oxgvqb7hf7ms4xi36jei7b77bj34mawhmfwnr5ypgvq",
      "pod-nsgids": "ocid1.networksecuritygroup.oc1.ap-sydney-1.aaaaaaaanqxbsqv6itn4w4wusip4tow5kv2ltmo7lenpa2mrkqgmio6qgnaq"
    },
    "displayName": "gb200-instance",
    "shape": "BM.GPU.GB200.4",
    "sourceDetails": {
      "sourceType": "image",
      "imageId": "$IMAGE_ID"
    },
    "agentConfig": {
      "isMonitoringDisabled": false,
      "isManagementDisabled": false,
      "pluginsConfig": [
        {
          "name": "WebLogic Management Service",
          "desiredState": "DISABLED"
        },
        {
          "name": "Vulnerability Scanning",
          "desiredState": "DISABLED"
        },
        {
          "name": "Oracle Java Management Service",
          "desiredState": "DISABLED"
        },
        {
          "name": "Oracle Autonomous Linux",
          "desiredState": "DISABLED"
        },
        {
          "name": "OS Management Service Agent",
          "desiredState": "DISABLED"
        },
        {
          "name": "OS Management Hub Agent",
          "desiredState": "DISABLED"
        },
        {
          "name": "Management Agent",
          "desiredState": "ENABLED"
        },
        {
          "name": "Custom Logs Monitoring",
          "desiredState": "ENABLED"
        },
        {
          "name": "Compute RDMA GPU Monitoring",
          "desiredState": "ENABLED"
        },
        {
          "name": "Compute Instance Run Command",
          "desiredState": "ENABLED"
        },
        {
          "name": "Compute Instance Monitoring",
          "desiredState": "ENABLED"
        },
        {
          "name": "Compute HPC RDMA Auto-Configuration",
          "desiredState": "ENABLED"
        },
        {
          "name": "Compute HPC RDMA Authentication",
          "desiredState": "ENABLED"
        },
        {
          "name": "Cloud Guard Workload Protection",
          "desiredState": "DISABLED"
        },
        {
          "name": "Block Volume Management",
          "desiredState": "DISABLED"
        },
        {
          "name": "Bastion",
          "desiredState": "DISABLED"
        }
      ]
    },
    "isPvEncryptionInTransitEnabled": false,
    "instanceOptions": {
      "areLegacyImdsEndpointsDisabled": false
    },
    "availabilityConfig": {
      "recoveryAction": "RESTORE_INSTANCE"
    }
  }
}'
