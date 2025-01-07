### Disable OKE GPU device plugin
Add the `oci.oraclecloud.com/disable-gpu-device-plugin=true` label to your nodes via either the node pool labels or after the cluster is deployed.

### Install the NVIDIA Container Toolkit
```sh
curl -s -L https://nvidia.github.io/libnvidia-container/stable/rpm/nvidia-container-toolkit.repo | \
sudo tee /etc/yum.repos.d/nvidia-container-toolkit.repo

sudo yum install -y nvidia-container-toolkit
```

### Configure settings for `crio`
OKE uses `crio` as the runtime. Running the below command with create the settings file for crio.

```sh
sudo nvidia-ctk runtime configure --runtime=crio --set-as-default --config=/etc/crio/crio.conf.d/99-nvidia.conf
```

### Restart `crio`
```sh
sudo yum install -y nvidia-container-toolkit
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
