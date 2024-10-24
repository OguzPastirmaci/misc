#### Stop Flannel
```
oci ce cluster disable-addon --addon-name Flannel --cluster-id $CLUSTER_ID --is-remove-existing-add-on true --force
```

#### Install Cilium CLI
https://docs.cilium.io/en/stable/gettingstarted/k8s-install-default/#install-the-cilium-cli

#### Create values override file
Change `k8sServiceHost` IP to your cluster's private API endpoint IP.

```yaml
cluster:
  name: "cluster1"
  id: 1

clustermesh:
  useAPIServer: true
  kvstoremesh:
    enabled: false

externalWorkloads:
  enabled: false

hubble:
  relay:
    enabled: true
  ui:
    enabled: true

ipam:
  mode: "kubernetes"

kubeProxyReplacement: "true"
k8sServiceHost: "<PRIVATE ENDPOINT IP>"
k8sServicePort: "6443"

operator:
  replicas: 1
```

#### Deploy Cilium
```
cilium install -f values-override.yaml
```
