```sh
cat placement-configuration.json

{
  "availabilityDomain": "VXpT:AP-OSAKA-1-AD-1",
  "primarySubnetId": "ocid1.subnet.oc1.ap-osaka-1.aaaaaaaaywcwtep4wliwe2xptyziekapjsmfg4jlwrdoxppjyj2s2blqkubq"
}
```

```sh
cat instance-pools.json

[
  {
    "definedTags": {
      "tagNamespace1": {
        "tagKey1": "",
        "tagKey2": ""
      },
      "tagNamespace2": {
        "tagKey1": "",
        "tagKey2": ""
      }
    },
    "displayName": "UbuntuCN",
    "freeformTags": {
      "tagKey1": "",
      "tagKey2": ""
    },
    "instanceConfigurationId": "ocid1.instanceconfiguration.oc1.ap-osaka-1.aaaaaaaaa2u2w465nwe4es7lesfaol6366vsbxvaniyaxuhije7qals2slqq",
    "size": "2"
  }
]
```

```sh
COMPARTMENT_ID=
oci compute-management cluster-network create --compartment-id $COMPARTMENT_ID --instance-pools file://instance-pools.json --placement-configuration file://placement-configuration.json
```
