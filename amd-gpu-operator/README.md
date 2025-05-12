1. Install AMD GPU Operator

```
helm install amd-gpu-operator rocm/gpu-operator-charts   --namespace amd-gpu-operator   --create-namespace   -f values.yaml
```

2.  Patch `devicePlugin` to add the tolerations.

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

3. Patch `testRunner` to add the tolerations.

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
