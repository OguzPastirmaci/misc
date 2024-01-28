#### Get the serial number of a node
```
kubectl get node <NODE IP> -o json | jq -r '.metadata.labels."oci.oraclecloud.com/host.serial_number" | ascii_upcase'
```

#### Map all the pods by job name to node IP + OCID + block ID for a job

```
kubectl get pod -l app=ace-eldeib-local-megazord -o custom-columns="NAME:.metadata.name,NODE:.spec.nodeName" | tail -n +2 | tr -s ' ' | cut -d' ' -f2 | xargs -I{} bash -c 'kubectl get node -o custom-columns="NAME:.metadata.name,BLOCK:.metadata.labels.oci\.oraclecloud\.com/host\.network_block_id,OCID:.spec.providerID" {} | tail -n +2'; kubectl get pod -l job-name=ace-eldeib-local-megazord-worker -o custom-columns="NAME:.metadata.name,NODE:.spec.nodeName" | tail -n +2 | tr -s ' ' | cut -d' ' -f2 | xargs -I{} bash -c 'kubectl get node -o custom-columns="NAME:.metadata.name,BLOCK:.metadata.labels.oci\.oraclecloud\.com/host\.network_block_id,OCID:.spec.providerID" {} | tail -n +2'
```
