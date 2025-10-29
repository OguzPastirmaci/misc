variable "gpu_shapes" {
  type    = list(string)
  default = ["BM.GPU4.8", "BM.GPU.A100-v2.8", "BM.GPU.B4.8", "BM.GPU.A10.4", "BM.GPU.H100.8", "BM.GPU.H200.8", "BM.GPU.MI300X.8", "VM.GPU.A10.1", "VM.GPU.A10.2", "BM.GPU.L40S.4", "VM.GPU.L40S.1", "VM.GPU.L40S.2", "VM.GPU.A100.40G.1", "VM.GPU.A100.40G.2", "VM.GPU.A100.40G.4", "VM.GPU.A100.B40G.1", "VM.GPU.A100.B40G.2", "VM.GPU.A100.B40G.4"]
}

variable "worker_ops_image_name" {
  default = "Canonical-Ubuntu-22.04-2024.06.26-0"
  type    = string
}

variable "worker_cpu_image_name" {
  default = "Canonical-Ubuntu-22.04-2024.06.26-0"
  type    = string
}

variable "worker_gpu_image_name" {
  default = ""
  type    = string
}

# variable "worker_rdma_image_name" {
#   default = ""
#   type        = string
# }

# variable "worker_ops_image_import" {
#   default = true
#   type    = bool
# }

# variable "worker_cpu_image_import" {
#   default = true
#   type    = bool
# }

# variable "worker_gpu_image_import" {
#   default = true
#   type    = bool
# }

# variable "worker_rdma_image_import" {
#   default = true
#   type    = bool
# }

variable "import_worker_images" {
  default = true
  type    = bool
}

variable "gpu_image_pars" {
  type = map(map(string))
  default = {
    "Ubuntu-22-OCA-OFED-23.10-2.1.3.1-GPU-535-CUDA-12.2-2024.09.18-0" = {
      "ca-toronto-1"   = "https://objectstorage.ca-toronto-1.oraclecloud.com/p/KOcEZeDpEAASLSKzumODnVr42mFwM_p9n1_Nra2FsV_F6BcpAkoH66HZxN4cCtIb/n/hpc_limited_availability/b/images/o/Ubuntu-22-OCA-OFED-23.10-2.1.3.1-GPU-535-CUDA-12.2-2024.09.18-0"
      "ap-melbourne-1" = "https://objectstorage.ap-melbourne-1.oraclecloud.com/p/dsAGIbb_8jeTZXPx-8kvUGhWzPqE_Rfh95m3obtIiwi9PL5ksfg9ZMzfRuy-56pD/n/hpc_limited_availability/b/oke-stack-images/o/Ubuntu-22-OCA-OFED-23.10-2.1.3.1-GPU-535-CUDA-12.2-2024.09.18-0"
      "eu-frankfurt-1" = "https://objectstorage.eu-frankfurt-1.oraclecloud.com/p/QA-rOnAlOqa-MpqiMkKEuQtG3aiLI_vPgns-E68uWQQfe5zGU02lRsumEr2raKIr/n/hpc_limited_availability/b/oke-stack-images/o/Ubuntu-22-OCA-OFED-23.10-2.1.3.1-GPU-535-CUDA-12.2-2024.09.18-0"
      "ap-osaka-1"     = "https://objectstorage.ap-osaka-1.oraclecloud.com/p/x7y7D9w40dwnsAGImUFPI6uAiKpFxfSjUOOKPR3NY794iXeVBTQy8l6jLS-z3PoZ/n/hpc_limited_availability/b/oke-stack-images/o/Ubuntu-22-OCA-OFED-23.10-2.1.3.1-GPU-535-CUDA-12.2-2024.09.18-0"
      "uk-london-1"    = "https://objectstorage.uk-london-1.oraclecloud.com/p/RgoBflknJ6hnJxvYBxp0rcna9dpX4-g9u8-W_CzXtA2OS42ByBGDNCXSMMqhjpCJ/n/hpc_limited_availability/b/oke-stack-images/o/Ubuntu-22-OCA-OFED-23.10-2.1.3.1-GPU-535-CUDA-12.2-2024.09.18-0"
      "us-ashburn-1"   = "https://objectstorage.us-ashburn-1.oraclecloud.com/p/sIqyAXlD579oa5CjT8H-iNzZTptxMURXKfjJiPhrZqjcojk12ti65Mncu59oPNNs/n/hpc_limited_availability/b/oke-stack-images/o/Ubuntu-22-OCA-OFED-23.10-2.1.3.1-GPU-535-CUDA-12.2-2024.09.18-0"
      "us-chicago-1"   = "https://objectstorage.us-chicago-1.oraclecloud.com/p/IvT_inTijgMI9B9QlyXhlM-BCwrD1IRrJhzT-JJC3SrKh-QLYGcfw3mlLBMLEnev/n/hpc_limited_availability/b/oke-stack-images/o/Ubuntu-22-OCA-OFED-23.10-2.1.3.1-GPU-535-CUDA-12.2-2024.09.18-0"
      "us-phoenix-1"   = "https://objectstorage.us-phoenix-1.oraclecloud.com/p/ISPDMRMJuH7Z7R9wtOSfCll5Gam7euDviN6zgCLohcdysi-rjZqaNdZwf8aBjXkY/n/hpc_limited_availability/b/oke-stack-images/o/Ubuntu-22-OCA-OFED-23.10-2.1.3.1-GPU-535-CUDA-12.2-2024.09.18-0"
      "us-sanjose-1"   = "https://objectstorage.us-sanjose-1.oraclecloud.com/p/IlBWNwF_hCSJjosrIEFALjWppLnBUFt_HGkEq0bkdNAjlI114vs1Y1DpWTpiSVp9/n/hpc_limited_availability/b/oke-stack-images/o/Ubuntu-22-OCA-OFED-23.10-2.1.3.1-GPU-535-CUDA-12.2-2024.09.18-0"
    }
    "Ubuntu-22-OCA-OFED-23.10-2.1.3.1-GPU-550-CUDA-12.4-2024.09.18-0" = {
      "ca-toronto-1"   = "https://objectstorage.ca-toronto-1.oraclecloud.com/p/EDngSWYfn3HjrN0xbfBSVCctRVKVvNf3NOW7DdInKMtgiZwiUqy7PsA_xifmI1oq/n/hpc_limited_availability/b/images/o/Ubuntu-22-OCA-OFED-23.10-2.1.3.1-GPU-550-CUDA-12.4-2024.09.18-0"
      "ap-melbourne-1" = "https://objectstorage.ap-melbourne-1.oraclecloud.com/p/drVM8lMV4nwmpTCVeKYORCuiySFzY7gdsrLyILJGjc7ycVaHAbx2GaoOten2gOf_/n/hpc_limited_availability/b/oke-stack-images/o/Ubuntu-22-OCA-OFED-23.10-2.1.3.1-GPU-550-CUDA-12.4-2024.09.18-0"
      "eu-frankfurt-1" = "https://objectstorage.eu-frankfurt-1.oraclecloud.com/p/PQ4bO48adlZ-Ffy3dSg8EtRD3lGeMjLF9DHvRlkNNT86ABiBGVbh7egjxyNArgsr/n/hpc_limited_availability/b/oke-stack-images/o/Ubuntu-22-OCA-OFED-23.10-2.1.3.1-GPU-550-CUDA-12.4-2024.09.18-0"
      "ap-osaka-1"     = "https://objectstorage.ap-osaka-1.oraclecloud.com/p/E74l6a10Vee5v7nOlK4p3085iLYA_By_nYYp9ZdnOAHcJlwqaASeF_9vh770jaRO/n/hpc_limited_availability/b/oke-stack-images/o/Ubuntu-22-OCA-OFED-23.10-2.1.3.1-GPU-550-CUDA-12.4-2024.09.18-0"
      "uk-london-1"    = "https://objectstorage.uk-london-1.oraclecloud.com/p/ZijYI3Ga_g5q4cZif8WxO-tFmTlCI1U1Ta1XgbPKaypB-_8yjDe8XY8a7kIWg12b/n/hpc_limited_availability/b/oke-stack-images/o/Ubuntu-22-OCA-OFED-23.10-2.1.3.1-GPU-550-CUDA-12.4-2024.09.18-0"
      "us-ashburn-1"   = "https://objectstorage.us-ashburn-1.oraclecloud.com/p/-qIBMeExYl_Tp5v70oN9QaPmRWc2jxj65ZtgYpGnPZLP-_gI3_6U5XitUur6MViF/n/hpc_limited_availability/b/oke-stack-images/o/Ubuntu-22-OCA-OFED-23.10-2.1.3.1-GPU-550-CUDA-12.4-2024.09.18-0"
      "us-chicago-1"   = "https://objectstorage.us-chicago-1.oraclecloud.com/p/YXRQv1NpiAu3HLQYS1v1Y2dendfcqTukJKRbmvewNEhprfryjJyPNKUpldthJ0oL/n/hpc_limited_availability/b/oke-stack-images/o/Ubuntu-22-OCA-OFED-23.10-2.1.3.1-GPU-550-CUDA-12.4-2024.09.18-0"
      "us-phoenix-1"   = "https://objectstorage.us-phoenix-1.oraclecloud.com/p/knHzV5v-aJ7zSOjNrH6fyUicMNsILMQCv1SYumI63aytm8TJQkdin4gdWomSwev3/n/hpc_limited_availability/b/oke-stack-images/o/Ubuntu-22-OCA-OFED-23.10-2.1.3.1-GPU-550-CUDA-12.4-2024.09.18-0"
      "us-sanjose-1"   = "https://objectstorage.us-sanjose-1.oraclecloud.com/p/BWZdXAw1AoC9eTtNDpk_3ROLFM5R0UyFZYRorue83QteprBMwtPhSucbU2nB16M4/n/hpc_limited_availability/b/oke-stack-images/o/Ubuntu-22-OCA-OFED-23.10-2.1.3.1-GPU-550-CUDA-12.4-2024.09.18-0"
    }
    "Ubuntu-22-OCA-OFED-23.10-2.1.3.1-GPU-560-CUDA-12.6-2024.09.18-0" = {
      "ca-toronto-1"   = "https://objectstorage.ca-toronto-1.oraclecloud.com/p/a_KKMCajcBpt9EfqgmnZbtUInpc6gdC5s2g1wz7b0KUCLW28DSvTKwMeOSgW5O0R/n/hpc_limited_availability/b/images/o/Ubuntu-22-OCA-OFED-23.10-2.1.3.1-GPU-560-CUDA-12.6-2024.09.18-0"
      "ap-melbourne-1" = "https://objectstorage.ap-melbourne-1.oraclecloud.com/p/gDQnGxcKDPfeRPG46kz9kwAiu0CVtfiI2JQWbQJTVba6oYqVSnkckssPU9-qEq6A/n/hpc_limited_availability/b/oke-stack-images/o/Ubuntu-22-OCA-OFED-23.10-2.1.3.1-GPU-560-CUDA-12.6-2024.09.18-0"
      "eu-frankfurt-1" = "https://objectstorage.eu-frankfurt-1.oraclecloud.com/p/BGUiZOVWcbO8mmLsVkXfCUQezU7shMGB32OhS2xTZvIs1Rot7044bKG-xZPfhnlz/n/hpc_limited_availability/b/oke-stack-images/o/Ubuntu-22-OCA-OFED-23.10-2.1.3.1-GPU-560-CUDA-12.6-2024.09.18-0"
      "ap-osaka-1"     = "https://objectstorage.ap-osaka-1.oraclecloud.com/p/jZqwOOIx3837yL-PsTDUlXyu-yp4T8Xeae3UYoJNdsCfMi_RJzMYttlgKuJwEK_U/n/hpc_limited_availability/b/oke-stack-images/o/Ubuntu-22-OCA-OFED-23.10-2.1.3.1-GPU-560-CUDA-12.6-2024.09.18-0"
      "uk-london-1"    = "https://objectstorage.uk-london-1.oraclecloud.com/p/xxS8hiaJlojYB0-yA7ELc3g9f3styCd8KTQo6ADxI7_4a9zZq4F2uXnSUkeGWRTx/n/hpc_limited_availability/b/oke-stack-images/o/Ubuntu-22-OCA-OFED-23.10-2.1.3.1-GPU-560-CUDA-12.6-2024.09.18-0"
      "us-ashburn-1"   = "https://objectstorage.us-ashburn-1.oraclecloud.com/p/yiv5azRMhiRJKBe6bK1qF6I8p0EtUi1hKcuFjNrrmNPrXW6dt7Pvu9LRUKg4rST4/n/hpc_limited_availability/b/oke-stack-images/o/Ubuntu-22-OCA-OFED-23.10-2.1.3.1-GPU-560-CUDA-12.6-2024.09.18-0"
      "us-chicago-1"   = "https://objectstorage.us-chicago-1.oraclecloud.com/p/gBzhM-BTTgSTZrzMXQrgRkshqYcDWKqZuK9jCis6sob4dXRIcoShaYw9lq9IsvJP/n/hpc_limited_availability/b/oke-stack-images/o/Ubuntu-22-OCA-OFED-23.10-2.1.3.1-GPU-560-CUDA-12.6-2024.09.18-0"
      "us-phoenix-1"   = "https://objectstorage.us-phoenix-1.oraclecloud.com/p/EN9aTsIML5lvIf4HbRg6WQjf9X1gJHv2rhZCvlz61SpyyWUqOoeVaLGqNkKYtSmF/n/hpc_limited_availability/b/oke-stack-images/o/Ubuntu-22-OCA-OFED-23.10-2.1.3.1-GPU-560-CUDA-12.6-2024.09.18-0"
      "us-sanjose-1"   = "https://objectstorage.us-sanjose-1.oraclecloud.com/p/LfjCaa6XhY4Tr7zQyAn4rSY6GUzx2byJu65cumzSTPdt7QzauUu2KlCtX6MJOFqn/n/hpc_limited_availability/b/oke-stack-images/o/Ubuntu-22-OCA-OFED-23.10-2.1.3.1-GPU-560-CUDA-12.6-2024.09.18-0"
    }
  }
}
