## Testing RDMA bandwidth between two NICs on two nodes

1 - On the server node, run:

```
ib_send_bw -d <RDMA interface> -D 10 -R -F
```

You can get the list of RDMA interfaces by running `ibdev2netdev`.

Example:

```
ibdev2netdev

mlx5_0 port 1 ==> eth0 (Up)
mlx5_1 port 1 ==> eth1 (Up)
mlx5_2 port 1 ==> rdma0 (Up)
mlx5_3 port 1 ==> rdma1 (Down)
```

For example, you can use `mlx5_2` as the interface in the command in Step 1.

2 - On the client node, run:

```
ib_send_bw -d <RDMA interface> -D 10 -R -F -p <IP of the server instance>
```

Again, choose the correct RDMA interface, it might be different than the interface in the server node.

You can change the duration of the test in seconds by changing the value after the `-D` option.

You should use the `-R` option so the command uses RDMA.

Example result:

```
ib_send_bw -d mlx5_2 -D 100 -R -F 192.168.1.126

---------------------------------------------------------------------------------------
                    Send BW Test
 Dual-port       : OFF		Device         : mlx5_2
 Number of qps   : 1		Transport type : IB
 Connection type : RC		Using SRQ      : OFF
 PCIe relax order: ON
 ibv_wr* API     : ON
 TX depth        : 128
 CQ Moderation   : 1
 Mtu             : 4096[B]
 Link type       : Ethernet
 GID index       : 3
 Max inline data : 0[B]
 rdma_cm QPs	 : ON
 Data ex. method : rdma_cm
---------------------------------------------------------------------------------------
 local address: LID 0000 QPN 0x10008 PSN 0x85ddc9
 GID: 00:00:00:00:00:00:00:00:00:00:255:255:192:168:01:147
 remote address: LID 0000 QPN 0x10008 PSN 0x4df954
 GID: 00:00:00:00:00:00:00:00:00:00:255:255:192:168:01:126
---------------------------------------------------------------------------------------
 #bytes     #iterations    BW peak[MB/sec]    BW average[MB/sec]   MsgRate[Mpps]
 65536      9349389          0.00               11714.10		   0.187426
---------------------------------------------------------------------------------------
```
