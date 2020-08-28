1- You will need ```availability domain```, ```compartment ID```, and ```boot volume id```.

You can list the availability domains with the following command:

```sh
oci iam availability-domain list --region us-sanjose-1
```

The output will be similar to below. Please make sure you use the one in the `name` field in your output. Availability domain names change based on the tenancy.

```sh
oguz@cloudshell:~ (us-ashburn-1)$ oci iam availability-domain list --region us-sanjose-1
{
  "data": [
    {
      "compartment-id": "ocid1.tenancy.oc1..aaaaaaaaa",
      "id": "ocid1.availabilitydomain.oc1..aaayie6t5a",
      "name": "VXpT:US-SANJOSE-1-AD-1"
    }
  ]
}
```

2- You can get the compartment ID of the `network` compartment from the console.


3- You can run the following command to get the boot volume ID of an instance:

```sh
oci compute boot-volume-attachment list --availability-domain $AVAILABILITY_DOMAIN --compartment-id $COMPARTMENT_ID --instance-id $INSTANCE_ID
```

Output will be similar to below:

```sh
oguz@cloudshell:~ (us-ashburn-1)$ oci compute boot-volume-attachment list --availability-domain VXpT:US-ASHBURN-AD-1 --compartment-id ocid1.compartment.oc1..aaaaaaaamgpf7k52h2qbh4iytjvrsa --instance-id ocid1.instance.oc1.iad.anuwcyzqj3tun6n643oenrfa
{
  "data": [
    {
      "availability-domain": "VXpT:US-ASHBURN-AD-1",
      "boot-volume-id": "ocid1.bootvolume.oc1.iad.ab2o45cz6wmfd2tga",
      "compartment-id": "ocid1.compartment.oc1..aaaaaaqb4iytjvrsa",
      "display-name": "Remote boot attachment for instance",
      "id": "ocid1.instance.oc1.iad.anuwcl643oenrfa",
      "instance-id": "ocid1.instance.oc1.iad.anuwclun6n643oenrfa",
      "is-pv-encryption-in-transit-enabled": false,
      "lifecycle-state": "ATTACHED",
      "time-created": "2020-08-28T15:28:28.082000+00:00"
    }
  ]
}
```

You will need the `boot-volume-id` value in the output.

4- You can then change the boot volume performance to higher performance with the following command:

```sh
oci bv boot-volume update --boot-volume-id <boot-volume-id from the previous step> --vpus-per-gb 20
```


NOTE:

10: Represents Balanced option.

20: Represents Higher Performance option.
