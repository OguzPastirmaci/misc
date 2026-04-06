### Enable Nvidia GPU device plugin add-on

```
oci ce cluster install-addon --cluster-id <cluster-id> --addon-name NvidiaGpuPlugin --region <region>
```

### Disable OKE GPU device plugin
Add the `oci.oraclecloud.com/disable-gpu-device-plugin=true` label to your nodes via either the node pool labels or after the cluster is deployed.

### Configure settings for `crio`
OKE uses `crio` as the runtime. Running the below command with create the settings file for crio.

```sh
sudo nvidia-ctk runtime configure --runtime=crio --set-as-default --config=/etc/crio/crio.conf.d/99-nvidia.conf
```

### Restart `crio`
```sh
sudo systemctl restart crio
```

### Add the Nvidia GPU device plugin Helm repo
```
helm repo add nvdp https://nvidia.github.io/k8s-device-plugin
helm repo update
```

### Create the config
```sh
cat << EOF > /tmp/dp-mps-10.yaml
version: v1
sharing:
  mps:
    resources:
    - name: nvidia.com/gpu
      replicas: 10
EOF
```

### Deploy the plugin with the above config
```sh
helm upgrade -i nvdp nvdp/nvidia-device-plugin \
    --namespace nvidia-device-plugin \
    --create-namespace \
    --set gfd.enabled=true \
    --set config.default=mps10 \
    --set-file config.map.mps10=/tmp/dp-mps-10.yaml
```
