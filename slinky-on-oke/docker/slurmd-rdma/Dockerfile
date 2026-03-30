# syntax=docker/dockerfile:1
#
# Custom slurmd image for bare-metal GPU nodes with RDMA.
# Based on the oci-hpc-oke NCCL test Dockerfile, adapted to use the Slinky
# slurmd image as the base so it works as both an NCCL test runner and a
# Slurm worker daemon.
#
# Build:
#   docker build -t your-registry/slurmd-rdma:25.11-ubuntu24.04 .
#
# Use in slinky-values.yaml:
#   nodesets:
#     gpu-b4:
#       slurmd:
#         image:
#           repository: your-registry/slurmd-rdma
#           tag: 25.11-ubuntu24.04

ARG SLURMD_IMAGE=ghcr.io/slinkyproject/slurmd:25.11-ubuntu24.04
ARG INSTALL_LATEST_NCCL_VERSION=true

################################################################################
FROM ${SLURMD_IMAGE}

ARG DEBIAN_FRONTEND=noninteractive
ARG INSTALL_LATEST_NCCL_VERSION

USER root

# --------------------------------------------------------------------------
# Install packages (mirrors the oci-hpc-oke nccl-tests Dockerfile)
# --------------------------------------------------------------------------
# The slurmd base image already provides: openssh-server, openmpi-bin,
# supervisor, tini, procps, iputils-ping.
# We add: CUDA toolkit (nvcc), NCCL, RDMA userspace, build tools, diags.
# --------------------------------------------------------------------------
RUN apt-get -qq update && apt-get -qq -y install --no-install-recommends \
    build-essential \
    infiniband-diags \
    kmod \
    wget \
    ca-certificates \
    iproute2 \
    net-tools \
    curl \
    tcpdump \
    ethtool \
    lsof \
    pciutils \
    numactl \
    iperf3 \
    autoconf \
    automake \
    libtool \
    libpci-dev \
    git \
    # MPI dev headers (base image only has openmpi-bin runtime)
    libopenmpi-dev \
    # RDMA userspace -- versions must match host kernel RDMA modules
    libibverbs-dev rdma-core ibverbs-providers librdmacm-dev libibumad-dev \
    && if [ "${INSTALL_LATEST_NCCL_VERSION}" = "true" ]; then \
        CUDA_ARCH=$([ "$(dpkg --print-architecture)" = "amd64" ] && echo "x86_64" || echo "sbsa") \
        && wget -q https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2404/${CUDA_ARCH}/cuda-keyring_1.1-1_all.deb \
        && dpkg -i cuda-keyring_1.1-1_all.deb \
        && rm cuda-keyring_1.1-1_all.deb \
        && apt-get -qq update \
        && apt-get -qq -y install --no-install-recommends \
            cuda-nvcc-13-1 \
            cuda-cudart-dev-13-1 \
            libnccl2 \
            libnccl-dev; \
    fi \
    && rm -rf /var/lib/apt/lists/*

# --------------------------------------------------------------------------
# Build nccl-tests
# --------------------------------------------------------------------------
# Key difference from the standalone NCCL test image:
#   MPI_HOME points to Ubuntu's OpenMPI (/usr/lib/x86_64-linux-gnu/openmpi)
#   instead of /usr/local/mpi (which is where the NVIDIA cuda-dl-base puts it).
# --------------------------------------------------------------------------
ARG NCCL_TESTS_VERSION=2.18.2
ARG NVCC_GENCODE="-gencode=arch=compute_80,code=sm_80 -gencode=arch=compute_90,code=sm_90 -gencode=arch=compute_100,code=sm_100 -gencode=arch=compute_120,code=sm_120 -gencode=arch=compute_120,code=compute_120"
WORKDIR /workspace

RUN git clone --depth 1 --branch v${NCCL_TESTS_VERSION} https://github.com/NVIDIA/nccl-tests.git nccl-tests-${NCCL_TESTS_VERSION} \
    && cd nccl-tests-${NCCL_TESTS_VERSION} \
    && make -j MPI=1 MPI_HOME=/usr/lib/x86_64-linux-gnu/openmpi \
       CUDA_HOME=/usr/local/cuda NCCL_HOME=/usr \
       NVCC_GENCODE="${NVCC_GENCODE}" \
    && ln -s /workspace/nccl-tests-${NCCL_TESTS_VERSION} /workspace/nccl-tests \
    # Also install to /opt/nccl-tests/bin/ so test commands work with both
    # the stager DaemonSet path and this custom image
    && mkdir -p /opt/nccl-tests/bin \
    && cp build/*_perf /opt/nccl-tests/bin/

# --------------------------------------------------------------------------
# Build perftest (ib_write_bw, ib_read_bw, etc.)
# --------------------------------------------------------------------------
# Key difference: --with-mpi uses Ubuntu's OpenMPI path.
# --------------------------------------------------------------------------
ARG PERFTEST_VERSION=perftest-26.01.5
RUN for lib in libibverbs.so.1 librdmacm.so.1 libibumad.so.3 libmlx5.so.1 libefa.so.1; do \
        base=$(echo $lib | sed 's/\.so\..*/\.so/'); \
        ln -sf /usr/lib/x86_64-linux-gnu/$lib /usr/lib/x86_64-linux-gnu/$base; \
    done \
    && git clone --depth 1 --branch ${PERFTEST_VERSION} https://github.com/linux-rdma/perftest.git /tmp/perftest \
    && cd /tmp/perftest \
    && ./autogen.sh \
    && ./configure --prefix=/usr/local \
       CUDA_H_PATH=/usr/local/cuda/include/cuda.h \
       --enable-cuda --with-cuda=/usr/local/cuda \
       --enable-mpi --with-mpi=/usr/lib/x86_64-linux-gnu/openmpi \
    && make -j \
    && make install \
    && rm -rf /tmp/perftest

# --------------------------------------------------------------------------
# SSH config (same as oci-hpc-oke nccl-tests image)
# --------------------------------------------------------------------------
# Note: with hostNetwork the slurmd's sshd (port 22) will fail to bind
# because the host sshd already uses it. This is non-fatal -- mpirun
# connects to the host's sshd via hostNetwork. These settings ensure
# SSH between nodes works without host key prompts.
# --------------------------------------------------------------------------
RUN sed -i 's/[ #]\(.*StrictHostKeyChecking \).*/ \1no/g' /etc/ssh/ssh_config && \
    echo "    UserKnownHostsFile /dev/null" >> /etc/ssh/ssh_config && \
    sed -i 's/#\(StrictModes \).*/\1no/g' /etc/ssh/sshd_config && \
    mkdir /var/run/sshd -p

# --------------------------------------------------------------------------
# Extra tools
# --------------------------------------------------------------------------
COPY --from=ghcr.io/huggingface/gpu-fryer:1.2.0 /usr/local/bin/gpu-fryer /usr/local/bin/gpu-fryer

RUN curl -so /usr/sbin/ibdev2netdev \
    https://raw.githubusercontent.com/Mellanox/container_scripts/refs/heads/master/ibdev2netdev \
    && chmod +x /usr/sbin/ibdev2netdev

# Library path so nccl-tests finds NCCL and CUDA at runtime
ENV LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:/usr/local/cuda/lib64:${LD_LIBRARY_PATH}

WORKDIR /
# Entrypoint is inherited from the slurmd base image (supervisord)
