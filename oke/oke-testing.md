### FOR RDMA

- Create the policy in your tenancy: https://docs.oracle.com/en-us/iaas/Content/ContEng/Tasks/contengdynamicgrouppolicyforselfmanagednodes.htm#contengprereqsforselfmanagednodes-accessreqs

- Import the image that you can use for testing RDMA (this one has GPU driver 510 preinstalled. I'll share the one without GPU drivers when it's ready)

https://objectstorage.ap-osaka-1.oraclecloud.com/p/akcmD2ZeEMMOLTRPIx8OB-Pd84IfbJrKL_Bpt85tlC-kGGhyw2_SekxwENfuRvkN/n/hpc_limited_availability/b/oke-images/o/OracleLinux-7-RHCK-3.10.0-OFED-5.4-3.6.8.1-GPU-510-OKE-1.26.2-2023.07.14-2

- Deploy a cluster using the template here: 

- Follow the instructions here for deploying GPU Operator and Network Operator: https://github.com/OguzPastirmaci/oke-rdma/tree/main

### FOR NON-RDMA

- Import the image for testing non-RDMA worker pools

https://objectstorage.us-phoenix-1.oraclecloud.com/p/vxK2ALLOcJMdcCKwmDeD5v3pEAFVVOJTd6RO_f61hy1T9W6REUZYQ3e4N_AwlSwK/n/hpc_limited_availability/b/oke-images/o/RHCK-Oracle-Linux-7.9-2023.05.24-0-OKE-1.26.2-625

- Deploy a cluster using the template here: 
