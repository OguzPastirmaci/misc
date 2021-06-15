CORES=256
GET_PERF="\$2==\"Benchmark\"{n++; s+=log(\$8); print \"Instant:\",1/\$8,\" ns/day\"}END{print \"Final:\",1/exp(s/n)}"

# With charm
./charmrun namd2 +p $CORES /nfs/block/namd_global/apoa1/apoa1.namd | awk "$GET_PERF"

./charmrun namd2 +p $CORES +setcpuaffinity /nfs/block/namd_global/apoa1/apoa1.namd.NEW | awk "$GET_PERF"

./charmrun namd2 +p $CORES +setcpuaffinity /mnt/nfs-share/namd_global/stmv/stmv.namd > stmv.log
