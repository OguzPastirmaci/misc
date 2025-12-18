## Deploy OKE cluster
https://github.com/oracle-quickstart/oci-hpc-oke

## Create a Compute Cluster
https://docs.oracle.com/en-us/iaas/Content/Compute/Tasks/create-compute-cluster.htm

## Create cloud-init
Make sure you change the API server IP etc.

```
cat > cloud-init.yaml << 'EOF'
#cloud-config
apt:
  sources:
    oke-node:
      source: "deb [trusted=yes] https://objectstorage.us-sanjose-1.oraclecloud.com/p/_Zaa2khW3lPESEbqZ2JB3FijAd0HeKmiP-KA2eOMuWwro85dcG2WAqua2o_a-PlZ/n/odx-oke/b/okn-repositories-private/o/prod/ubuntu-jammy/kubernetes-1.34 stable main"

packages:
  - oci-oke-node-all-1.34.1

write_files:
  - path: /etc/oke/oke-apiserver
    permissions: "0644"
    content: 10.140.0.4

  - encoding: b64
    path: /etc/kubernetes/ca.crt
    permissions: "0644"
    content: |
      LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSURpRENDQW5DZ0F3SUJBZ0lRQm1QMUs0YmFkSnRWd1hoTmo5N3RuekFOQmdrcWhraUc5dzBCQVFzRkFEQmUK
      TVE4d0RRWURWUVFEREFaTE9ITWdRMEV4Q3pBSkJnTlZCQVlUQWxWVE1ROHdEUVlEVlFRSERBWkJkWE4wYVc0eApE
      ekFOQmdOVkJBb01Cazl5WVdOc1pURU1NQW9HQTFVRUN3d0RUMk5wTVE0d0RBWURWUVFJREFWVVpYaGhjekFlCkZ3
      MHlOVEV4TVRneU16RXpNREJhRncwek1ERXhNVGd5TXpFek1EQmFNRjR4RHpBTkJnTlZCQU1NQmtzNGN5QkQK
      UVRFTE1Ba0dBMVVFQmhNQ1ZWTXhEekFOQmdOVkJBY01Ca0YxYzNScGJqRVBNQTBHQTFVRUNnd0dUM0poWTJ4bA==

runcmd:
  - >
    oke bootstrap
    --apiserver-host 10.140.0.4
    --ca LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCg==

ssh_authorized_keys:
  - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDIwZXnHrnvtAvP8wfgQBLZ9tGnBKCGxd0beP3POUhWER+jXE/N/nfMeg8arLITO6ravSCS18TUgZbcYQHSFBFjppzvPb7dcG0S1asoYI5WDDtjeL7BAYC6E/zw49o4qmJpLmp7ZjBT5/AHmk2NE1yIy2dz6y1HnHeW68Ah2o41sZuBeHsFF3+sMh0d2Mrlm88kG/3jUoZAi5loio/exMzJjN0RbE0V5KM6PJbdwspbSO0BS3cONZjAayP0dCf0YiymgsSj3Wrwx6y/b9V2tD5xBs0irjKbOwRW41DmHZxp55KjHjvhnoydMJ3dmfIvKJRxG61WkV28mzN/fhRHTPC/ opastirm@opastirm-mac
EOF
```

## Encode cloud-init
USER_DATA=$(base64 -b 0 cloud-init.yaml)


## Create node pool

Change the params accordingly.

```
oci ce node-pool create \
  --region us-ashburn-1 \
  --cluster-id ocid1.cluster.oc1.iad.aaaaaaaalhpyuljjbdnkylzc436b3lblcw34z4wv7fwzl3tpzceqbvdssfca \
  --compartment-id ocid1.compartment.oc1..aaaaaaaa3p3kstuy3pkr4kj4ehgadfcnw3ivqz53xzd6i7r3hkkkddzd7u3a \
  --name "nodepool-with-compute-cluster-3" \
  --kubernetes-version "v1.34.1" \
  --node-shape "BM.Optimized3.36" \
  --node-image-id "ocid1.image.oc1.iad.aaaaaaaaohoijtxdzyuwvywnkz4gyjusapzay2fsnwsh5ttqxbv5yt5pgxga" \
  --placement-configs '[
    {
      "availabilityDomain": "jLaG:US-ASHBURN-AD-1",
      "subnetId": "ocid1.subnet.oc1.iad.aaaaaaaa3ru6bumepgutfjbypeijwbynoiyxur7dpvd3p7p2krrtq5sro6zq",
      "nsgIds": [
        "ocid1.networksecuritygroup.oc1.iad.aaaaaaaaokvnzspj5h4ugpexeluff57o4rv4nbgl2hcy4w4vrm4e2ambhx5a"
      ]
    }
  ]' \
  --size 2 \
  --pod-subnet-ids '[
    "ocid1.subnet.oc1.iad.aaaaaaaas7ecbxulj4gpk47yprnhjycemyputgjqlchoferup5x7wj7gl2ka"
  ]' \
  --nsg-ids '[
    "ocid1.networksecuritygroup.oc1.iad.aaaaaaaaq6lpzjularvqlvmdmysna7keltkzgpsodkcvtga5fjlcewxp2tsq"
  ]' \
  --node-metadata "{
    \"areLegacyImdsEndpointsDisabled\": \"true\",
    \"compute_cluster\": \"ocid1.computecluster.oc1.iad.anuwcljr2bemolacsrxh4vovqiaro4ktxdyvcdz5qhfev7sgmbtro6va6x3q\",
    \"user_data\": \"${USER_DATA}\"
  }"
```
