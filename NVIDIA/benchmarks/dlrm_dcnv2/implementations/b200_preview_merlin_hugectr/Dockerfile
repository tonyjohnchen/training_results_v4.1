# Copyright (c) 2021-2024, NVIDIA CORPORATION.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# You may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

FROM nvcr.io/nvidia/nemo:25.02.rc4

ARG SM="90;100"
ARG ENABLE_MULTINODES=ON

ARG HWLOC_VERSION=2.4.1
ARG RELEASE=true

RUN apt-get update -y && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        coreutils \
        hostname \
        clang-format \
        libboost-serialization-dev \
        libtbb-dev \
        libaio-dev \
        libgflags-dev \
        zlib1g-dev libbz2-dev libsnappy-dev liblz4-dev libzstd-dev \
        libssl-dev libsasl2-dev && \
    rm -rf /var/lib/apt/lists/*
    
ENV PATH=/usr/local/bin:$PATH

# CUDA-Aware hwloc
RUN cd /opt/hpcx/ompi/include/openmpi/opal/mca/hwloc/hwloc201 && rm -rfv hwloc201.h hwloc/include/hwloc.h
RUN mkdir -p /var/tmp && wget -q -nc --no-check-certificate -P /var/tmp https://download.open-mpi.org/release/hwloc/v2.4/hwloc-${HWLOC_VERSION}.tar.gz && \
    tar -x -f /var/tmp/hwloc-${HWLOC_VERSION}.tar.gz -C /var/tmp && \
    cd /var/tmp/hwloc-${HWLOC_VERSION} && \
    ./configure CPPFLAGS="-I/usr/local/cuda/include/ -L/usr/local/cuda/lib64/" LDFLAGS="-L/usr/local/cuda/lib64" --enable-cuda && \
    make -j$(nproc) && make install && \
    rm -rf /var/tmp/hwloc-${HWLOC_VERSION} /var/tmp/hwloc-${HWLOC_VERSION}.tar.gz

ENV CPATH=/usr/local/include

# Create the necessary directory
RUN mkdir -p /usr/local/gib

# Install NCCL plugin from the installer image
# TODO: replace the image to be consistent with the NCCL plugin URL
COPY --from=us-docker.pkg.dev/gce-ai-infra/gpudirect-gib/nccl-plugin-gib:v1.0.5 /usr/local/gib /usr/local/gib

ENV NCCL_NET=gIB
ENV NCCL_CROSS_NIC=0
ENV NCCL_NET_GDR_LEVEL=PIX
ENV NCCL_P2P_NET_CHUNKSIZE=131072
ENV NCCL_P2P_PCI_CHUNKSIZE=131072
ENV NCCL_P2P_NVL_CHUNKSIZE=524288
ENV NCCL_NVLS_CHUNKSIZE=524288
ENV NCCL_IB_GID_INDEX=3
ENV NCCL_IB_ADAPTIVE_ROUTING=1
ENV NCCL_IB_QPS_PER_CONNECTION=4
ENV NCCL_IB_TC=52
ENV NCCL_IB_FIFO_TC=84
ENV NCCL_TUNER_CONFIG_PATH=/usr/local/gib/configs/tuner_config_a4.txtpb

# Env variables for NCCL
ENV NCCL_LAUNCH_MODE=PARALLEL

# ENV variables for Sharp
ENV SHARP_COLL_NUM_COLL_GROUP_RESOURCE_ALLOC_THRESHOLD=0 \
    SHARP_COLL_LOCK_ON_COMM_INIT=1 \
    SHARP_COLL_LOG_LEVEL=3 \
    HCOLL_ENABLE_MCAST=0

RUN ln -s /usr/lib/x86_64-linux-gnu/libibverbs.so.1 /usr/lib/x86_64-linux-gnu/libibverbs.so
RUN mkdir -p /workspace/dlrm

WORKDIR /workspace/dlrm
COPY . .

RUN pip3 install --no-cache-dir -r requirements.txt

# FIXME: Temporal workaround to make HugeCTR compile correctly
#  for the latest PyT base image (following conda removal):
RUN pip3 uninstall -y tbb

ENV PYTHON_VERSION=3.12
# HugeCTR
RUN if [ "$RELEASE" = "true" ]; \
    then \
    cd /workspace/dlrm/ && \
    git clone --recurse-submodules -b v24.04.00 https://github.com/NVIDIA-Merlin/HugeCTR.git hugectr && \
        cd hugectr && \
        git log -n 1 && git checkout v25.03.00 && \
        mkdir build && cd build && \
        cmake -DCMAKE_BUILD_TYPE=Release -DSM=$SM -DUSE_CUDART_STATIC=ON \
            -DENABLE_MULTINODES=$ENABLE_MULTINODES -DSHARP_A2A=OFF .. && \
        make -j$(nproc) && make install && \
        chmod +x /usr/local/hugectr/bin/* && \
        chmod +x /usr/local/hugectr/lib/* && \
        rm -rf /workspace/dlrm/hugectr && \
    rm /usr/lib/x86_64-linux-gnu/libibverbs.so; \
    else \
      echo "Build container for development successfully!"; \
    fi

# Install dependencies
RUN apt-get update && apt-get install -y \
    curl \
    apt-transport-https \
    ca-certificates \
    gnupg

# Add Google Cloud SDK repository
RUN curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg
RUN echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] http://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list

# Install Google Cloud SDK
RUN apt-get update && apt-get install -y google-cloud-cli

# Install gcsfuse
RUN echo "deb http://packages.cloud.google.com/apt gcsfuse-jammy main" | tee /etc/apt/sources.list.d/gcsfuse.list && \
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add - && \
    apt-get update && \
    apt-get install -y gcsfuse && \
    rm -rf /var/lib/apt/lists/*

# Verify gcsfuse installation
RUN gcsfuse --version

ENV PATH=/usr/local/hugectr/bin:$PATH \
    LIBRARY_PATH=/usr/local/hugectr/lib:$LIBRARY_PATH \
    LD_LIBRARY_PATH=/usr/local/hugectr/lib:$LD_LIBRARY_PATH \
    PYTHONPATH=/usr/local/hugectr/lib


ARG CUDA13_GENCODE='-gencode=arch=compute_100,code=sm_100 -gencode=arch=compute_120,code=sm_120'
ARG CUDA13_PTX='-gencode=arch=compute_120,code=compute_120'

WORKDIR /third_party
RUN git clone https://github.com/NVIDIA/nccl.git nccl-netsupport && \
  cd nccl-netsupport && \
  git fetch --all --tags && \
  git checkout v2.25.1-1
WORKDIR nccl-netsupport
RUN make NVCC_GENCODE="$CUDA13_GENCODE $CUDA13_PTX" -j 16

# Make the pods capable of speaking to each other via SSH on port 222
RUN cd /etc/ssh/ && sed --in-place='.bak' 's/#Port 22/Port 222/' sshd_config && \
    sed --in-place='.bak' 's/#PermitRootLogin prohibit-password/PermitRootLogin prohibit-password/' sshd_config
RUN ssh-keygen -t rsa -b 4096 -q -f /root/.ssh/id_rsa -N ""
RUN touch /root/.ssh/authorized_keys && chmod 600 /root/.ssh/authorized_keys
RUN cat /root/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys

WORKDIR /workspace

# Optional: Add command to check PATH at end of build
# RUN echo "Final PATH=$PATH"
# RUN which sed grep cut rm hostname || echo "Warning: Some core utils not found in PATH during build"

HEALTHCHECK NONE
ENTRYPOINT []
CMD ["/bin/bash"]