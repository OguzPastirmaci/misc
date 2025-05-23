REGION=ap-sydney-1
COMPARTMENT_ID=ocid1.compartment.oc1..aaaaaaaan5ouwmczcchigfas4xuzw5mh5xpqhnymull6y4g7gxc73wmgammq
AD=ZHZP:AP-SYDNEY-1-AD-1
SUBNET_ID=ocid1.subnet.oc1.ap-sydney-1.aaaaaaaapgst6odxn7pav4o3lai64js3fyb6dljhdzi5ffufygrhgpkjv5pq
SUBNET_NSG_ID=ocid1.networksecuritygroup.oc1.ap-sydney-1.aaaaaaaanqxbsqv6itn4w4wusip4tow5kv2ltmo7lenpa2mrkqgmio6qgnaq
IMAGE_ID=ocid1.image.oc1.ap-sydney-1.aaaaaaaa24usi6houqzdjyp3eatz2sqx37vsmmjq5wdyq7z4rdxmkrmeos5a
BASE64_ENCODED_CLOUD_INIT=$(cat cloud-init.yml| base64 -b 0)

oci --region ${REGION} compute-management instance-configuration create --compartment-id ${COMPARTMENT_ID} --display-name gb200-oke --instance-details \
'{
  "instanceType": "compute",
  "launchDetails": {
    "availabilityDomain": "ZHZP:AP-SYDNEY-1-AD-1",
    "compartmentId": "ocid1.compartment.oc1..aaaaaaaan5ouwmczcchigfas4xuzw5mh5xpqhnymull6y4g7gxc73wmgammq",
    "createVnicDetails": {
      "assignIpv6Ip": false,
      "assignPublicIp": false,
      "assignPrivateDnsRecord": true,
      "subnetId": "ocid1.subnet.oc1.ap-sydney-1.aaaaaaaapgst6odxn7pav4o3lai64js3fyb6dljhdzi5ffufygrhgpkjv5pq",
      "nsgIds": [ "ocid1.networksecuritygroup.oc1.ap-sydney-1.aaaaaaaanqxbsqv6itn4w4wusip4tow5kv2ltmo7lenpa2mrkqgmio6qgnaq" ]
    },
    "metadata": {
      "user_data": "I2Nsb3VkLWNvbmZpZwphcHQ6CiAgc291cmNlczoKICAgIG9rZS1ub2RlOiB7c291cmNlOiAnZGViIFt0cnVzdGVkPXllc10gaHR0cHM6Ly9vYmplY3RzdG9yYWdlLnVzLXNhbmpvc2UtMS5vcmFjbGVjbG91ZC5jb20vcC80NWVPZUVyRURacVBHaXltWFp3cGVlYkNOYjVsbnd6a2NRSWh0VmY2aU9GNDRlZXRfZWZkZVBhRjdUOGFnTllxL24vb2R4LW9rZS9iL29rbi1yZXBvc2l0b3JpZXMtcHJpdmF0ZS9vL3Byb2QvdWJ1bnR1LWphbW15L2t1YmVybmV0ZXMtMS4zMiBzdGFibGUgbWFpbid9CnBhY2thZ2VzOgogIC0gb2NpLW9rZS1ub2RlLWFsbC0xLjMyLjEKd3JpdGVfZmlsZXM6CiAgLSBwYXRoOiAvZXRjL29rZS9va2UtYXBpc2VydmVyCiAgICBwZXJtaXNzaW9uczogJzA2NDQnCiAgICBjb250ZW50OiAxMC4xNDAuMC4xMAogIC0gZW5jb2Rpbmc6IGI2NAogICAgcGF0aDogL2V0Yy9rdWJlcm5ldGVzL2NhLmNydAogICAgcGVybWlzc2lvbnM6ICcwNjQ0JwogICAgY29udGVudDogTFMwdExTMUNSVWRKVGlCRFJWSlVTVVpKUTBGVVJTMHRMUzB0Q2sxSlNVUnBWRU5EUVc1SFowRjNTVUpCWjBsU1FVNWxZMVZIUm14c2J6WmtSV05JU0UxUGRIbHZUbXQzUkZGWlNrdHZXa2xvZG1OT1FWRkZURUpSUVhjS1dHcEZVRTFCTUVkQk1WVkZRWGQzUjFONmFIcEpSVTVDVFZGemQwTlJXVVJXVVZGSFJYZEtWbFY2UlZCTlFUQkhRVEZWUlVKM2QwZFJXRlo2WkVkc2RRcE5VVGgzUkZGWlJGWlJVVXRFUVZwUVkyMUdhbUpIVlhoRVJFRkxRbWRPVmtKQmMwMUJNRGxxWVZSRlQwMUJkMGRCTVZWRlEwRjNSbFpIVmpSWldFMTNDa2hvWTA1TmFsVjNUbFJKZVUxcVFYbE5ha1Y0VjJoalRrMTZRWGRPVkVsNVRXcEJlVTFxUlhoWGFrSmxUVkU0ZDBSUldVUldVVkZFUkVGYVRFOUlUV2NLVVRCRmVFTjZRVXBDWjA1V1FrRlpWRUZzVmxSTlVUaDNSRkZaUkZaUlVVaEVRVnBDWkZoT01HRlhOSGhFZWtGT1FtZE9Wa0pCYjAxQ2F6bDVXVmRPY3dwYVZFVk5UVUZ2UjBFeFZVVkRkM2RFVkRKT2NFMVJOSGRFUVZsRVZsRlJTVVJCVmxWYVdHaG9ZM3BEUTBGVFNYZEVVVmxLUzI5YVNXaDJZMDVCVVVWQ0NrSlJRVVJuWjBWUVFVUkRRMEZSYjBOblowVkNRVTB5Umt0QmRYRnVOMlIxVTBSWFREUjJVVVkzZVZoM2JrNXllbEpCZGxoVWVIUTFWVGxRUVV3MGFsb0thamh2YmpWa1FXSllZWGROVDBOVlltcENXRkpSTlc1NVZHRmlPVVZwY1VOSk1IWTVXSFptWTNsVmJ5ODVSWFJEVEUxUlRISTBOR3RxWWxsRlowTkVZd3BpTUc1WVFtMU5jRzVHYUc1d0wxSmFNQ3RLZDA1TlpucDJSbGxMUVZsaE1tTnBiVmRYZEZoUk5FNDBOVVZQVW5WbllUSkhVV1JSUTBGRlYyMVZRWE13Q2pSeldHZ3ZTelp2SzJ4Q1dUaFdaM1ppYm1kS1V6WXJWbmRxYnpsdFRTc3JjbkZRWmpWSGFFNTZVbkk1UzFSTU1rTjVTWE5pYlVjd2VsTTBURUpHUkc0S1NFUm1hRGRMYVVWaE5qZGxURGR6ZDA1SFQwdFFRakJ2UzBsR2R6aERVak4wWkdkR1FtRnVObUpaY3psT05uZHVNWHBEYTNGYVoyOVpVVE1yU21WbmRRbzJRVmd2UjFaaFMwdFVjM28yZURWalZVTkNja0ozYUVSTk5VdHVXVVZMS3prclluQTBSRGsyUWxWRlEwRjNSVUZCWVU1RFRVVkJkMFIzV1VSV1VqQlVDa0ZSU0M5Q1FWVjNRWGRGUWk5NlFVOUNaMDVXU0ZFNFFrRm1PRVZDUVUxRFFWRlpkMGhSV1VSV1VqQlBRa0paUlVaTWNVZzBhVlp0UVRsUGFHZEdVWGNLV1ZNd1psWlpkREJKZFROcFRVRXdSME5UY1VkVFNXSXpSRkZGUWtOM1ZVRkJORWxDUVZGQ1dDdG5VRkZpTjJWdWJqZFdhQ3RuUjFOdU1EVk9Wems1Y1FvemRGbFNhMnMxYlhSR2MxWk9TVFJWV2tsSllVaGxXbVpzVVVkVWJEZ3pjVzVzZDNoNFprVk9SV3BoZUhOVlRWQTJaVXBTTm1wdFl6QnNZMjFhTjJ0cUNrMXpWa1ZJWmxwaVF5OUdibEpDZDJ0aVpFUkhibEpYUzB3M1ZuTXZiVVZ0VWxaWWIzVjZUbUpGVWt4eGNFdHRkMFJZZW5OWWRVbFJWVGRYYmpKMU4xTUthR295T1ZsYU1qQjRkSFp0UVdaUVEwRTRRalZ2UzFGbFNsaEZWR1kyTTJwc1FsZE1RVmg0YXpSSFduaHZWRVIwV0V3MmNFNXJLMU5SUzFvM2JEbEJRd295YVdwNlVXY3djUzlSWVc0d1NHRTJSVFZ5Y25jMEsxcGxja1J5UWtGMmIzZFRTMjB5U2xSM01sZEhTMDFDVGt4SWVHY3ZVMXBWUmxGdlQyaG1XRVpxQ2t4YVlXcE1iSFZaUzFvNWNIVndSMnRVTml0cFZscGhaVE51YUd0aWNteFNiRXRxZEZJdlptODBlWFJ5WmtzclkzbE1XbFZHVkc1MlZHczVaUW90TFMwdExVVk9SQ0JEUlZKVVNVWkpRMEZVUlMwdExTMHRDZz09CnJ1bmNtZDoKICAtIG9rZSBib290c3RyYXAgLS1hcGlzZXJ2ZXItaG9zdCAxMC4xNDAuMC4xMCAtLWNhICJMUzB0TFMxQ1JVZEpUaUJEUlZKVVNVWkpRMEZVUlMwdExTMHRDazFKU1VScFZFTkRRVzVIWjBGM1NVSkJaMGxTUVU1bFkxVkhSbXhzYnpaa1JXTklTRTFQZEhsdlRtdDNSRkZaU2t0dldrbG9kbU5PUVZGRlRFSlJRWGNLV0dwRlVFMUJNRWRCTVZWRlFYZDNSMU42YUhwSlJVNUNUVkZ6ZDBOUldVUldVVkZIUlhkS1ZsVjZSVkJOUVRCSFFURlZSVUozZDBkUldGWjZaRWRzZFFwTlVUaDNSRkZaUkZaUlVVdEVRVnBRWTIxR2FtSkhWWGhFUkVGTFFtZE9Wa0pCYzAxQk1EbHFZVlJGVDAxQmQwZEJNVlZGUTBGM1JsWkhWalJaV0UxM0NraG9ZMDVOYWxWM1RsUkplVTFxUVhsTmFrVjRWMmhqVGsxNlFYZE9WRWw1VFdwQmVVMXFSWGhYYWtKbFRWRTRkMFJSV1VSV1VWRkVSRUZhVEU5SVRXY0tVVEJGZUVONlFVcENaMDVXUWtGWlZFRnNWbFJOVVRoM1JGRlpSRlpSVVVoRVFWcENaRmhPTUdGWE5IaEVla0ZPUW1kT1ZrSkJiMDFDYXpsNVdWZE9jd3BhVkVWTlRVRnZSMEV4VlVWRGQzZEVWREpPY0UxUk5IZEVRVmxFVmxGUlNVUkJWbFZhV0dob1kzcERRMEZUU1hkRVVWbEtTMjlhU1doMlkwNUJVVVZDQ2tKUlFVUm5aMFZRUVVSRFEwRlJiME5uWjBWQ1FVMHlSa3RCZFhGdU4yUjFVMFJYVERSMlVVWTNlVmgzYms1eWVsSkJkbGhVZUhRMVZUbFFRVXcwYWxvS2FqaHZialZrUVdKWVlYZE5UME5WWW1wQ1dGSlJOVzU1VkdGaU9VVnBjVU5KTUhZNVdIWm1ZM2xWYnk4NVJYUkRURTFSVEhJME5HdHFZbGxGWjBORVl3cGlNRzVZUW0xTmNHNUdhRzV3TDFKYU1DdEtkMDVOWm5wMlJsbExRVmxoTW1OcGJWZFhkRmhSTkU0ME5VVlBVblZuWVRKSFVXUlJRMEZGVjIxVlFYTXdDalJ6V0dndlN6WnZLMnhDV1RoV1ozWmlibWRLVXpZclZuZHFiemx0VFNzcmNuRlFaalZIYUU1NlVuSTVTMVJNTWtONVNYTmliVWN3ZWxNMFRFSkdSRzRLU0VSbWFEZExhVVZoTmpkbFREZHpkMDVIVDB0UVFqQnZTMGxHZHpoRFVqTjBaR2RHUW1GdU5tSlpjemxPTm5kdU1YcERhM0ZhWjI5WlVUTXJTbVZuZFFvMlFWZ3ZSMVpoUzB0VWMzbzJlRFZqVlVOQ2NrSjNhRVJOTlV0dVdVVkxLemtyWW5BMFJEazJRbFZGUTBGM1JVRkJZVTVEVFVWQmQwUjNXVVJXVWpCVUNrRlJTQzlDUVZWM1FYZEZRaTk2UVU5Q1owNVdTRkU0UWtGbU9FVkNRVTFEUVZGWmQwaFJXVVJXVWpCUFFrSlpSVVpNY1VnMGFWWnRRVGxQYUdkR1VYY0tXVk13WmxaWmREQkpkVE5wVFVFd1IwTlRjVWRUU1dJelJGRkZRa04zVlVGQk5FbENRVkZDV0N0blVGRmlOMlZ1YmpkV2FDdG5SMU51TURWT1Z6azVjUW96ZEZsU2EyczFiWFJHYzFaT1NUUlZXa2xKWVVobFdtWnNVVWRVYkRnemNXNXNkM2g0WmtWT1JXcGhlSE5WVFZBMlpVcFNObXB0WXpCc1kyMWFOMnRxQ2sxelZrVklabHBpUXk5R2JsSkNkMnRpWkVSSGJsSlhTMHczVm5NdmJVVnRVbFpZYjNWNlRtSkZVa3h4Y0V0dGQwUlllbk5ZZFVsUlZUZFhiakoxTjFNS2FHb3lPVmxhTWpCNGRIWnRRV1pRUTBFNFFqVnZTMUZsU2xoRlZHWTJNMnBzUWxkTVFWaDRhelJIV25odlZFUjBXRXcyY0U1cksxTlJTMW8zYkRsQlF3b3lhV3A2VVdjd2NTOVJZVzR3U0dFMlJUVnljbmMwSzFwbGNrUnlRa0YyYjNkVFMyMHlTbFIzTWxkSFMwMUNUa3hJZUdjdlUxcFZSbEZ2VDJobVdFWnFDa3hhWVdwTWJIVlpTMW81Y0hWd1IydFVOaXRwVmxwaFpUTnVhR3RpY214U2JFdHFkRkl2Wm04MGVYUnlaa3NyWTNsTVdsVkdWRzUyVkdzNVpRb3RMUzB0TFVWT1JDQkRSVkpVU1VaSlEwRlVSUzB0TFMwdENnPT0iIC0ta3ViZWxldC1leHRyYS1hcmdzICItLWZlYXR1cmUtZ2F0ZXM9RHluYW1pY1Jlc291cmNlQWxsb2NhdGlvbj10cnVlIgpzc2hfYXV0aG9yaXplZF9rZXlzOgogIC0gc3NoLXJzYSBBQUFBQjNOemFDMXljMkVBQUFBREFRQUJBQUFCQVFDcWZ0eE45aittTjc1SktSNXNPVWZjNmszWVpiVTlmKzNUVUQ3T2RCSlkwM1Q1UERGYlF4bjBtMkJiY3lGaWcxcGlrc09HRnhpaHExQWZKSDNBTnZZWVRPVjE0cVVQbzNmbkJkeFljZWxrQUJBL1FNSXFjVTVib3JvRzk3R2g1WG16RVdnYTVFbUdtUDhJVGpXU3pCSnZleVhYTjY0cklCdGRQL3VvbXZLQlJjSzE4TVo4dHhTaVFWYkhLWVoybDZkdm8wOTlBb1ZldE4vQTE4Sy9WK05QUXZyK29HbXE1NVhUaXcwazJCbFRUN29KbmRycDh1QlFpa1FGNVJqUEI1cUUzSG5jTXp6V0VvSmg4V1BXdStPTFpVVHVoeUxRUVljZFFkWkphRXFpbndRVVhIUUY1ODFtZ0lTQytXSERjUWlNdHpsVHdXY214UUM5cC9kcW5yd1ggYWZyb2lkbW9AYWZyb2lkbW8tbWFjCiAgLSBzc2gtcnNhIEFBQUFCM056YUMxeWMyRUFBQUFEQVFBQkFBQUJBUURJd1pYbkhybnZ0QXZQOHdmZ1FCTFo5dEduQktDR3hkMGJlUDNQT1VoV0VSK2pYRS9OL25mTWVnOGFyTElUTzZyYXZTQ1MxOFRVZ1piY1lRSFNGQkZqcHB6dlBiN2RjRzBTMWFzb1lJNVdERHRqZUw3QkFZQzZFL3p3NDlvNHFtSnBMbXA3WmpCVDUvQUhtazJORTF5SXkyZHo2eTFIbkhlVzY4QWgybzQxc1p1QmVIc0ZGMytzTWgwZDJNcmxtODhrRy8zalVvWkFpNWxvaW8vZXhNekpqTjBSYkUwVjVLTTZQSmJkd3NwYlNPMEJTM2NPTlpqQWF5UDBkQ2YwWWl5bWdzU2ozV3J3eDZ5L2I5VjJ0RDV4QnMwaXJqS2JPd1JXNDFEbUhaeHA1NUtqSGp2aG5veWRNSjNkbWZJdktKUnhHNjFXa1YyOG16Ti9maFJIVFBDLyBvcGFzdGlybUBvcGFzdGlybS1tYWM=",
      "oke-native-pod-networking": "true", "oke-max-pods": "60",
      "pod-subnets": "ocid1.subnet.oc1.ap-sydney-1.aaaaaaaaphfdh4jq3oxgvqb7hf7ms4xi36jei7b77bj34mawhmfwnr5ypgvq",
      "pod-nsgids": "ocid1.networksecuritygroup.oc1.ap-sydney-1.aaaaaaaanqxbsqv6itn4w4wusip4tow5kv2ltmo7lenpa2mrkqgmio6qgnaq"
    },
    "displayName": "gb200-instance",
    "shape": "BM.GPU.GB200.4",
    "sourceDetails": {
      "sourceType": "image",
      "imageId": "ocid1.image.oc1.ap-sydney-1.aaaaaaaa24usi6houqzdjyp3eatz2sqx37vsmmjq5wdyq7z4rdxmkrmeos5a"
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
