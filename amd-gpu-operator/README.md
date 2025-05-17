1. Disable OKE AMD device plugin
```
kubectl get nodes -l node.kubernetes.io/instance-type=BM.GPU.MI300X.8 -o name \
| xargs -I {} kubectl label {} oci.oraclecloud.com/disable-gpu-device-plugin=true --overwrite
```

2. Delete the current AMD device plugin daemonset

```
kubectl delete ds amdgpu-device-plugin-daemonset -n kube-system
```

3. Install Cert-Manager
```
helm repo add jetstack https://charts.jetstack.io --force-update

helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version v1.15.1 \
  --set crds.enabled=true
```

4. Install AMD GPU Operator

```
helm repo add rocm https://rocm.github.io/gpu-operator
helm repo update

helm install amd-gpu-operator rocm/gpu-operator-charts \
  --namespace amd-gpu-operator \
  --create-namespace \
  --version=v1.2.2 \
  -f https://raw.githubusercontent.com/OguzPastirmaci/misc/refs/heads/master/amd-gpu-operator/values.yaml

```

5. Create the device config for BM.GPU.MI300X.8.

```
kubectl apply -f https://raw.githubusercontent.com/OguzPastirmaci/misc/refs/heads/master/amd-gpu-operator/BM.GPU.MI300X.8-device-config.yaml
```   

6.  Patch the CRs to add tolerations.

```
kubectl patch deviceconfig bm.gpu.mi300x.8 -n amd-gpu-operator --type merge -p '
spec:
  devicePlugin:
    devicePluginTolerations:
      - key: "amd.com/gpu"
        operator: "Equal"
        value: "present"
        effect: "NoSchedule"
    nodeLabellerTolerations:
      - key: "amd.com/gpu"
        operator: "Equal"
        value: "present"
        effect: "NoSchedule"
  testRunner:
    tolerations:
      - key: "amd.com/gpu"
        operator: "Equal"
        value: "present"
        effect: "NoSchedule"
  metricsExporter:
    tolerations:
      - key: "amd.com/gpu"
        operator: "Equal"
        value: "present"
        effect: "NoSchedule"
'
```
