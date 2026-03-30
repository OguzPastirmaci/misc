# syntax=docker/dockerfile:1
#
# Custom slurmd image with PMIx-enabled OpenMPI for direct srun --mpi=pmix support.
# Extends the slurmd-rdma image by replacing Ubuntu's openmpi-bin with a custom
# build that includes --with-pmix --with-slurm.
#
# Build:
#   docker build -t your-registry/slurmd-rdma-pmix:25.11-ubuntu24.04 .
#
# Use in slinky-values.yaml:
#   nodesets:
#     gpu-b4:
#       slurmd:
#         image:
#           repository: your-registry/slurmd-rdma-pmix
#           tag: 25.11-ubuntu24.04

ARG SLURMD_IMAGE=ghcr.io/slinkyproject/slurmd:25.11-ubuntu24.04
ARG INSTALL_LATEST_NCCL_VERSION=true
ARG OPENMPI_VERSION=5.0.7

################################################################################
# Stage 1: Build OpenMPI with PMIx + Slurm support
################################################################################
FROM ${SLURMD_IMAGE} AS ompi-builder

ARG DEBIAN_FRONTEND=noninteractive
ARG OPENMPI_VERSION

USER root
WORKDIR /tmp

# Remove stock openmpi-bin, install PMIx dev headers, build OpenMPI from source
RUN apt-get -qq update && apt-get -qq -y install --no-install-recommends \
    build-essential wget ca-certificates \
    libpmix-dev libhwloc-dev libevent-dev \
    libibverbs-dev rdma-core librdmacm-dev \
    && apt-get -qq -y remove --purge openmpi-bin libopenmpi3t64 || true \
    && rm -rf /var/lib/apt/lists/*

RUN wget -q https://download.open-mpi.org/release/open-mpi/v${OPENMPI_VERSION%.*}/openmpi-${OPENMPI_VERSION}.tar.gz \
    && tar xzf openmpi-${OPENMPI_VERSION}.tar.gz \
    && cd openmpi-${OPENMPI_VERSION} \
    && ./configure --prefix=/usr/local/openmpi \
       --with-pmix \
       --with-slurm \
       --with-hwloc \
       --without-verbs \
       --without-ucx \
    && make -j$(nproc) \
    && make install \
    && cd / && rm -rf /tmp/openmpi*

################################################################################
# Stage 2: Final image
################################################################################
FROM ${SLURMD_IMAGE}

ARG DEBIAN_FRONTEND=noninteractive
ARG INSTALL_LATEST_NCCL_VERSION=true

USER root

# Remove stock openmpi (will be replaced by custom build)
RUN apt-get -qq update && apt-get -qq -y remove --purge openmpi-bin libopenmpi3t64 || true

# Install runtime deps + CUDA + NCCL + RDMA + build tools (same as slurmd-rdma)
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
    # PMIx runtime (needed by our custom OpenMPI)
    libpmix2t64 libhwloc15 \
    # RDMA userspace
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

# Copy custom PMIx-enabled OpenMPI
COPY --from=ompi-builder /usr/local/openmpi /usr/local/openmpi

# Put OpenMPI on PATH and library path
ENV PATH=/usr/local/openmpi/bin:${PATH}
ENV LD_LIBRARY_PATH=/usr/local/openmpi/lib:/usr/lib/x86_64-linux-gnu:/usr/local/cuda/lib64
ENV OPAL_PREFIX=/usr/local/openmpi

# Force OpenMPI to use eth0 for TCP communication.
# Without this, OpenMPI picks up K8s pod IPs from hostNetwork interfaces,
# causing MPI_Bcast to hang during NCCL bootstrap.
ENV OMPI_MCA_oob_tcp_if_include=eth0
ENV OMPI_MCA_btl_tcp_if_include=eth0

# --------------------------------------------------------------------------
# Build nccl-tests against the PMIx-enabled OpenMPI
# --------------------------------------------------------------------------
ARG NCCL_TESTS_VERSION=2.18.2
ARG NVCC_GENCODE="-gencode=arch=compute_80,code=sm_80 -gencode=arch=compute_90,code=sm_90 -gencode=arch=compute_100,code=sm_100 -gencode=arch=compute_120,code=sm_120 -gencode=arch=compute_120,code=compute_120"
WORKDIR /workspace

RUN git clone --depth 1 --branch v${NCCL_TESTS_VERSION} https://github.com/NVIDIA/nccl-tests.git nccl-tests-${NCCL_TESTS_VERSION} \
    && cd nccl-tests-${NCCL_TESTS_VERSION} \
    && make -j MPI=1 MPI_HOME=/usr/local/openmpi \
       CUDA_HOME=/usr/local/cuda NCCL_HOME=/usr \
       NVCC_GENCODE="${NVCC_GENCODE}" \
    && ln -s /workspace/nccl-tests-${NCCL_TESTS_VERSION} /workspace/nccl-tests \
    && mkdir -p /opt/nccl-tests/bin \
    && cp build/*_perf /opt/nccl-tests/bin/

# --------------------------------------------------------------------------
# Build perftest
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
       --enable-mpi --with-mpi=/usr/local/openmpi \
    && make -j \
    && make install \
    && rm -rf /tmp/perftest

# --------------------------------------------------------------------------
# SSH config + extra tools (same as slurmd-rdma)
# --------------------------------------------------------------------------
RUN sed -i 's/[ #]\(.*StrictHostKeyChecking \).*/ \1no/g' /etc/ssh/ssh_config && \
    echo "    UserKnownHostsFile /dev/null" >> /etc/ssh/ssh_config && \
    sed -i 's/#\(StrictModes \).*/\1no/g' /etc/ssh/sshd_config && \
    mkdir /var/run/sshd -p

COPY --from=ghcr.io/huggingface/gpu-fryer:1.2.0 /usr/local/bin/gpu-fryer /usr/local/bin/gpu-fryer

RUN curl -so /usr/sbin/ibdev2netdev \
    https://raw.githubusercontent.com/Mellanox/container_scripts/refs/heads/master/ibdev2netdev \
    && chmod +x /usr/sbin/ibdev2netdev

WORKDIR /
# Entrypoint inherited from slurmd base (supervisord)
