```sh
cat placement-configuration.json

{
  "availabilityDomain": "VXpT:AP-OSAKA-1-AD-1",
  "primarySubnetId": "ocid1.subnet.oc1.ap-osaka-1.aaaaaaaaywcwtep4wliwe2xptyziekapjsmfg4jlwrdoxppjyj2s2blqkubq"
}
```

```sh
cat placement-configuration.json

{
  "availabilityDomain": "VXpT:AP-OSAKA-1-AD-1",
  "primarySubnetId": "ocid1.subnet.oc1.ap-osaka-1.aaaaaaaaywcwtep4wliwe2xptyziekapjsmfg4jlwrdoxppjyj2s2blqkubq"
}
```

```sh
oci compute-management cluster-network create --compartment-id $COMPARTMENT_ID --instance-pools file://instance-pools.json --placement-configuration file://placement-configuration.json
```
