1. Install AMD GPU Operator

```
helm install amd-gpu-operator rocm/gpu-operator-charts   --namespace amd-gpu-operator   --create-namespace   -f https://raw.githubusercontent.com/OguzPastirmaci/misc/refs/heads/master/amd-gpu-operator/values.yaml
```

2. Create the device config for BM.GPU.MI300X.8.

```
kubectl apply -f https://raw.githubusercontent.com/OguzPastirmaci/misc/refs/heads/master/amd-gpu-operator/BM.GPU.MI300X.8-device-config.yaml
```   

3.  Patch `devicePlugin` to add the tolerations.

```
kubectl patch deviceconfig luma-test-deviceconfig \
  -n amd-gpu-operator \
  --type merge \
  -p '
spec:
  devicePlugin:
    devicePluginTolerations:
      - key: "amd.com/gpu"
        operator: "Equal"
        value: "present"
        effect: "NoSchedule"
'
```

4. Patch `testRunner` to add the tolerations.

```
kubectl patch deviceconfig luma-test-deviceconfig \
  -n amd-gpu-operator \
  --type merge \
  -p '
spec:
  testRunner:
    tolerations:
      - key: "amd.com/gpu"
        operator: "Equal"
        value: "present"
        effect: "NoSchedule"
'
```
