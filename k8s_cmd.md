#### Get the serial number of a node
```
kubectl get node <NODE IP> -o json | jq -r '.metadata.labels."oci.oraclecloud.com/host.serial_number" | ascii_upcase'
```
