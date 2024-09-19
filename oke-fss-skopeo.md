# Importing images from OCI File Storage Service (FSS) to OKE nodes instead of downloading them from a registry

### 1. Create an FSS File System
https://docs.oracle.com/en-us/iaas/Content/File/Tasks/create-file-system.htm#top

### 2. Mount the FSS File System to your worker nodes
https://docs.oracle.com/en-us/iaas/Content/File/Tasks/mountingunixstyleos.htm#mountingFS

> [!NOTE]  
> This guide assumes you mounted FSS to /mnt/share

### 3. Install `skopeo` in your worker nodes and create a dir under /mnt/share (we'll use /mnt/share/images as the example)
```
apt update
apt install -y skopeo
mkdir -p /mnt/share/images
```
### 4. Using `skopeo`, copy the image from a registry to the FSS shared folder
We'll use the Docker registry, but any registry including private ones can be used.

```
skopeo copy docker://busybox:latest dir:/mnt/share/images/busybox

Getting image source signatures
Copying blob 2fce1e0cdfc5 done
Copying config 6fd955f66c done
Writing manifest to image destination
Storing signatures
```

