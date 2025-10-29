locals {
  worker_ops_image_urls = {
    "Canonical-Ubuntu-22.04-2024.06.26-0" = "https://objectstorage.ap-melbourne-1.oraclecloud.com/p/OhoowBKU16nCQldaPAuXto24QhxatWq0BmHxqRQyTxxSwjvTqtQbfnVzRbgHptEX/n/hpc_limited_availability/b/oke-stack-images/o/Canonical-Ubuntu-22.04-2024.06.26-0"
  }

  #   worker_gpu_image_urls = {
  #     "Ubuntu-22-OCA-OFED-23.10-2.1.3.1-GPU-535-CUDA-12.2-2024.09.18-0" = "https://objectstorage.ca-toronto-1.oraclecloud.com/p/KOcEZeDpEAASLSKzumODnVr42mFwM_p9n1_Nra2FsV_F6BcpAkoH66HZxN4cCtIb/n/hpc_limited_availability/b/images/o/Ubuntu-22-OCA-OFED-23.10-2.1.3.1-GPU-535-CUDA-12.2-2024.09.18-0"
  #     "Ubuntu-22-OCA-OFED-23.10-2.1.3.1-GPU-550-CUDA-12.4-2024.09.18-0" = "https://objectstorage.ca-toronto-1.oraclecloud.com/p/EDngSWYfn3HjrN0xbfBSVCctRVKVvNf3NOW7DdInKMtgiZwiUqy7PsA_xifmI1oq/n/hpc_limited_availability/b/images/o/Ubuntu-22-OCA-OFED-23.10-2.1.3.1-GPU-550-CUDA-12.4-2024.09.18-0"
  #     "Ubuntu-22-OCA-OFED-23.10-2.1.3.1-GPU-560-CUDA-12.6-2024.09.18-0" = "https://objectstorage.ca-toronto-1.oraclecloud.com/p/a_KKMCajcBpt9EfqgmnZbtUInpc6gdC5s2g1wz7b0KUCLW28DSvTKwMeOSgW5O0R/n/hpc_limited_availability/b/images/o/Ubuntu-22-OCA-OFED-23.10-2.1.3.1-GPU-560-CUDA-12.6-2024.09.18-0"
  #     "Ubuntu-22-OFED-5.9-0.5.6.0.127-ROCM-6.2-90-2024.08.12-0.oci"     = "https://objectstorage.us-ashburn-1.oraclecloud.com/p/tpswnRAUmrJ49uLAGk_ku6B13hyGzf_Gv1vrggtDWhOywSM5YGzoMPiO88gc3Cv-/n/imagegen/b/GPU-imaging/o/Ubuntu-22-OFED-5.9-0.5.6.0.127-ROCM-6.2-90-2024.08.12-0.oci"
  #   }

  #   worker_gpu_image_urls = {
  #     "Ubuntu-22-OCA-OFED-23.10-2.1.3.1-GPU-535-CUDA-12.2-2024.09.18-0" = "https://objectstorage.ca-toronto-1.oraclecloud.com/p/KOcEZeDpEAASLSKzumODnVr42mFwM_p9n1_Nra2FsV_F6BcpAkoH66HZxN4cCtIb/n/hpc_limited_availability/b/images/o/Ubuntu-22-OCA-OFED-23.10-2.1.3.1-GPU-535-CUDA-12.2-2024.09.18-0"
  #     "Ubuntu-22-OCA-OFED-23.10-2.1.3.1-GPU-550-CUDA-12.4-2024.09.18-0" = "https://objectstorage.ca-toronto-1.oraclecloud.com/p/EDngSWYfn3HjrN0xbfBSVCctRVKVvNf3NOW7DdInKMtgiZwiUqy7PsA_xifmI1oq/n/hpc_limited_availability/b/images/o/Ubuntu-22-OCA-OFED-23.10-2.1.3.1-GPU-550-CUDA-12.4-2024.09.18-0"
  #     "Ubuntu-22-OCA-OFED-23.10-2.1.3.1-GPU-560-CUDA-12.6-2024.09.18-0" = "https://objectstorage.ca-toronto-1.oraclecloud.com/p/a_KKMCajcBpt9EfqgmnZbtUInpc6gdC5s2g1wz7b0KUCLW28DSvTKwMeOSgW5O0R/n/hpc_limited_availability/b/images/o/Ubuntu-22-OCA-OFED-23.10-2.1.3.1-GPU-560-CUDA-12.6-2024.09.18-0"
  #     "Ubuntu-22-OFED-5.9-0.5.6.0.127-ROCM-6.2-90-2024.08.12-0.oci"     = "https://objectstorage.us-ashburn-1.oraclecloud.com/p/tpswnRAUmrJ49uLAGk_ku6B13hyGzf_Gv1vrggtDWhOywSM5YGzoMPiO88gc3Cv-/n/imagegen/b/GPU-imaging/o/Ubuntu-22-OFED-5.9-0.5.6.0.127-ROCM-6.2-90-2024.08.12-0.oci"
  #   }  

  #   worker_rdma_image_urls = {
  #     "Ubuntu-22-OCA-OFED-23.10-2.1.3.1-GPU-535-CUDA-12.2-2024.09.18-0" = "https://objectstorage.ca-toronto-1.oraclecloud.com/p/KOcEZeDpEAASLSKzumODnVr42mFwM_p9n1_Nra2FsV_F6BcpAkoH66HZxN4cCtIb/n/hpc_limited_availability/b/images/o/Ubuntu-22-OCA-OFED-23.10-2.1.3.1-GPU-535-CUDA-12.2-2024.09.18-0"
  #     "Ubuntu-22-OCA-OFED-23.10-2.1.3.1-GPU-550-CUDA-12.4-2024.09.18-0" = "https://objectstorage.ca-toronto-1.oraclecloud.com/p/EDngSWYfn3HjrN0xbfBSVCctRVKVvNf3NOW7DdInKMtgiZwiUqy7PsA_xifmI1oq/n/hpc_limited_availability/b/images/o/Ubuntu-22-OCA-OFED-23.10-2.1.3.1-GPU-550-CUDA-12.4-2024.09.18-0"
  #     "Ubuntu-22-OCA-OFED-23.10-2.1.3.1-GPU-560-CUDA-12.6-2024.09.18-0" = "https://objectstorage.ca-toronto-1.oraclecloud.com/p/a_KKMCajcBpt9EfqgmnZbtUInpc6gdC5s2g1wz7b0KUCLW28DSvTKwMeOSgW5O0R/n/hpc_limited_availability/b/images/o/Ubuntu-22-OCA-OFED-23.10-2.1.3.1-GPU-560-CUDA-12.6-2024.09.18-0"
  #     "Ubuntu-22-OFED-5.9-0.5.6.0.127-ROCM-6.2-90-2024.08.12-0.oci"     = "https://objectstorage.us-ashburn-1.oraclecloud.com/p/tpswnRAUmrJ49uLAGk_ku6B13hyGzf_Gv1vrggtDWhOywSM5YGzoMPiO88gc3Cv-/n/imagegen/b/GPU-imaging/o/Ubuntu-22-OFED-5.9-0.5.6.0.127-ROCM-6.2-90-2024.08.12-0.oci"
  #   }

  worker_ops_image_url = lookup(local.worker_ops_image_urls, var.worker_ops_image_name, null)
  # worker_gpu_image_url = lookup(local.worker_gpu_image_urls, var.worker_gpu_image_name, null)
  #  worker_rdma_image_url = lookup(local.worker_rdma_image_urls, var.worker_rdma_image_name, null)

}

resource "oci_core_image" "imported_worker_ops_image" {
  count          = var.import_worker_images ? 1 : 0
  compartment_id = var.compartment_ocid
  display_name   = var.worker_ops_image_name
  image_source_details {
    source_type = "objectStorageUri"
    source_uri  = local.worker_ops_image_url
  }
}

resource "oci_core_image" "imported_worker_gpu_image" {
  count          = var.import_worker_images && var.worker_gpu_enabled ? 1 : 0
  compartment_id = var.compartment_ocid
  display_name   = var.worker_gpu_image_name
  image_source_details {
    source_type = "objectStorageUri"
    source_uri  = coalesce(var.gpu_image_pars[var.worker_gpu_image_name][var.region], var.gpu_image_pars[var.worker_gpu_image_name]["us-ashburn-1"])
  }
}

# resource "oci_core_image" "imported_worker_rdma_image" {
#   count = var.worker_rdma_image_import && var.worker_rdma_enabled ? 1 : 0
#   compartment_id = var.compartment_ocid
#   display_name   = var.worker_rdma_image_name
#   image_source_details {
#     source_type = "objectStorageUri"
#     source_uri = local.worker_rdma_image_url
#   }
# }

resource "oci_core_shape_management" "imported_worker_gpu_image" {
  count          = var.import_worker_images && var.worker_gpu_enabled ? 1 : 0
  compartment_id = var.compartment_ocid
  image_id       = oci_core_image.imported_worker_gpu_image[0].id
  shape_name     = var.worker_gpu_shape
}

resource "oci_core_shape_management" "imported_worker_rdma_image" {
  count          = var.import_worker_images && var.worker_rdma_enabled ? 1 : 0
  compartment_id = var.compartment_ocid
  image_id       = oci_core_image.imported_worker_gpu_image[0].id
  shape_name     = var.worker_rdma_shape
}

# resource "oci_core_shape_management" "imported_worker_rdma_image" {
#   count = var.worker_rdma_image_import && var.worker_rdma_enabled ? 1 : 0
#   compartment_id = var.compartment_ocid
#   image_id       = oci_core_image.imported_worker_rdma_image[0].id
#   shape_name     = var.worker_rdma_shape
# }
