### Required policies
```
Allow group <group-name> to inspect compartments in <location>
Allow group <group-name> to manage cluster-family in <location>
Allow group <group-name> to manage instance-family in <location>
Allow group <group-name> to manage public-ips  in <location>
Allow group <group-name> to manage virtual-network-family in <location>
Allow group <group-name> to manage volume-family in <location>
Allow group <group-name> to use network-security-groups  in <location>
Allow group <group-name> to use private-ips  in <location>
Allow group <group-name> to use subnets in <location>
Allow group <group-name> to use vnics in <location>
ALLOW any-user to read instance-images in TENANCY where request.principal.type = 'cluster'
```

### Rebooting the nodes

#### Prepare the CR template YAML file

```yaml
apiVersion: oci.oraclecloud.com/v1beta1
kind: NodeOperationRule
metadata:
  name: nor-test-reboot ## you may choose your own name
spec:
  actions:
    - "reboot" ## this is used to perform the reboot action
  nodeSelector:
    matchTriggerLabel:
      oke.oraclecloud.com/node_operation: "okereboot" ## "oke.oraclecloud.com/node_operation" is required and fixed. you may choose your own label
    matchCustomLabels: ## you may choose your own label
      deployment: "green"
  maxParallelism: 2 ## you may choose any
  nodeEvictionSettings: ## same as eviction settings as existing one
    evictionGracePeriod: 10
    isForceActionAfterGraceDuration: true
```

```
kubectl apply -f <custom_resource_file>.yaml
```

#### Attach labels to the node(s) specifying the action you would like to take and the nodes you would like to take action on. For example this will take a reboot action on a node:

```
kubectl label node <your_node> oke.oraclecloud.com/node_operation=okereboot
kubectl label node <your_node> deployment=green
```

#### Track the status of the action

```
kubectl get nor
kubectl describe nor <nor_name>
```

Example output:

```
Name:         nor-test
Namespace:   
Labels:       <none>
Annotations:  <none>
API Version:  oci.oraclecloud.com/v1beta1
Kind:         NodeOperationRule
Metadata:
  Creation Timestamp:  2025-02-11T00:11:11Z
  Finalizers:
    nodeoperationrule.oci.oraclecloud.com/finalizers
  Generation:        1
  Resource Version:  244259806
  UID:               4f3c0c47-1520-484d-87d7-633adef87c40
Spec:
  Actions:
    replaceBootVolume
  Max Parallelism:  2
  Node Eviction Settings:
    Eviction Grace Period:                 10
    Is Force Action After Grace Duration:  true
  Node Selector:
    Match Trigger Label:
      oke.oraclecloud.com/node_operation:  oktest
Status:
  Back Off Nodes:
  Canceled Nodes:
    Node Name:        10.0.10.206
    Work Request Id:  ocid1.clustersworkrequest.oc1.phx.aaaaaaaaz4hid5jucunz5en4zrlmh6zlcube7g4k65i3hcxj7wxyl5zka3uq
  In Progress Nodes:
  Pending Nodes:
  Succeeded Nodes:
    Node Name:          10.0.10.105
    Success Timestamp:  2025-02-26T01:18:56Z
Events:
  Type    Reason                  Age   From               Message
  ----    ------                  ----  ----               -------
  Normal  StartedNodeOperation    38m   NodeOperationRule  Started node operation on node with work request ID: 10.0.10.105: ocid1.clustersworkrequest.oc1.phx.aaaaaaaahftpvvbush432tx67pvmpufj27i6bz3a2hhpnw5uhwapezujejda
  Normal  CompletedNodeOperation  32m   NodeOperationRule  Completed operation on node: 10.0.10.105
```
