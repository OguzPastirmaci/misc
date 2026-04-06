
## From a node that has `kubectl` access to the cluster

### Drain the node
```
kubectl drain $NODE --ignore-daemonsets --delete-emptydir-data
```

### Delete the node from OKE
```
kubectl delete node $NODE
```
## SSH into the node

### Remove the current package
```
sudo systemctl stop kubelet crio
sudo rm -rf /var/lib/kubelet/pki/* /etc/proxymux /etc/oke
sudo apt remove oci-oke-node-all* oci-oke-node-client cri-o crictl kubelet -y
sudo apt autoremove -y
sudo rm /etc/apt/sources.list.d/archive_uri-https_odx-oke_objectstorage_us-sanjose-1_oci_customer-oci_com_n_odx-oke_b_okn-repositories_o_prod_ubuntu-jammy_kubernetes-1_31-jammy.list
```

### Install the new package and bootstrap
```
sudo add-apt-repository -y "deb [trusted=yes] https://odx-oke.objectstorage.us-sanjose-1.oci.customer-oci.com/n/odx-oke/b/okn-repositories/o/prod/ubuntu-jammy/kubernetes-1.30 stable main"

sudo apt -y update
sudo apt -y install oci-oke-node-all*
sudo systemctl daemon-reload
sudo oke bootstrap
```
