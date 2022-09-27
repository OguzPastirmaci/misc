1 - Create a sample Helm chart.
```
helm create helm-test-chart
```

2 - Package the Helm chart as tgz.

```
helm package helm-test-chart
```

3 - Login to the OCI Registry. You will need to create an Auth Token for the user that you want to login. You can find the steps [in this link](https://docs.oracle.com/en-us/iaas/Content/Registry/Tasks/registrygettingauthtoken.htm) for creating an auth token.

You can find the region codes under the Region Key column [in this page](https://docs.oracle.com/en-us/iaas/Content/General/Concepts/regions.htm#About).

```
helm registry login -u <tenancy_name/username> -p <auth_token> <region_code.ocir.io>
```

4 - Create a repository in a specific compartment in your tenancy.

```
oci artifacts container repository create --display-name helm/helm-test-chart --compartment-id <compartment_ocid> --region <region>
```

5 - Push the chart to helm/helm-test-chart repository in specific compartment with 0.1.0 as default tag.

```
helm push helm-test-chart-0.1.0.tgz oci://<regioncode.ocir.io>/<tenancy_namespace>/helm
```
