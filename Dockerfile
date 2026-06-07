FROM debian:trixie-slim AS builder

# Enforce strict error handling. Instantly aborts on any hidden failure.
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Set non-interactive frontend for apt to prevent hanging prompts
ENV DEBIAN_FRONTEND=noninteractive

# 1. Install ONLY the core build tools and verified stable C libraries.
# Removed libmagic-dev (deprecated in MKVToolNix v59.0.0).
# Removed zlib1g-dev and libogg-dev (we will compile the 2026 versions from source).
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    cmake \
    curl \
    wget \
    xz-utils \
    bzip2 \
    ca-certificates \
    pkg-config \
    ruby \
    rake \
    libgmp-dev \
    libvorbis-dev \
    libflac-dev \
    gettext \
    file \
    jq \
    && rm -rf /var/lib/apt/lists/*

# Set PKG_CONFIG_PATH globally so MKVToolNix prioritizes custom compiled libraries
ENV PKG_CONFIG_PATH="/usr/local/lib/pkgconfig:/usr/local/lib/$(uname -m)-linux-gnu/pkgconfig:/usr/local/lib/x86_64-linux-gnu/pkgconfig:/usr/local/lib/aarch64-linux-gnu/pkgconfig:$PKG_CONFIG_PATH"

# ==========================================
# 🛠️ COMPILE LATEST 2026 LIBRARIES FROM SOURCE (STATICALLY)
# ==========================================

# 1. Compile Absolute Latest 'zlib' (Statically Linked)
RUN echo "Fetching latest zlib version..." && \
    ZLIB_VERSION=$(curl -fsSL "https://api.github.com/repos/madler/zlib/tags" | jq -r '.[].name' | grep -oP '^v\K\d+\.\d+(\.\d+)?$' | sort -Vu | tail -n 1) && \
    if [ -z "$ZLIB_VERSION" ]; then echo "⚠️ API failed, using fallback"; ZLIB_VERSION="1.3.1"; fi && \
    echo "💡 Building zlib version: $ZLIB_VERSION" && \
    wget -q --show-progress "https://github.com/madler/zlib/archive/refs/tags/v${ZLIB_VERSION}.tar.gz" -O zlib.tar.gz && \
    tar -xf zlib.tar.gz && cd zlib-${ZLIB_VERSION} && \
    ./configure --static && \
    make -j"$(nproc)" && make install && \
    cd .. && rm -rf zlib*

# 2. Compile Absolute Latest 'libogg' (Statically Linked)
RUN echo "Fetching latest libogg version..." && \
    OGG_VERSION=$(curl -fsSL "https://api.github.com/repos/xiph/ogg/tags" | jq -r '.[].name' | grep -oP '^v\K\d+\.\d+(\.\d+)?$' | sort -Vu | tail -n 1) && \
    if [ -z "$OGG_VERSION" ]; then echo "⚠️ API failed, using fallback"; OGG_VERSION="1.3.5"; fi && \
    echo "💡 Building libogg version: $OGG_VERSION" && \
    wget -q --show-progress "https://github.com/xiph/ogg/archive/refs/tags/v${OGG_VERSION}.tar.gz" -O libogg.tar.gz && \
    tar -xf libogg.tar.gz && cd ogg-${OGG_VERSION} && \
    cmake -DCMAKE_INSTALL_PREFIX=/usr/local -DBUILD_SHARED_LIBS=OFF . && \
    make -j"$(nproc)" && make install && \
    cd .. && rm -rf libogg* ogg*

# 3. Compile Absolute Latest 'fmt' (Statically Linked)
RUN echo "Fetching latest fmt version..." && \
    FMT_VERSION=$(curl -fsSL "https://api.github.com/repos/fmtlib/fmt/tags" | jq -r '.[].name' | grep -oP '^\d+\.\d+(\.\d+)?$' | sort -Vu | tail -n 1) && \
    if [ -z "$FMT_VERSION" ]; then echo "⚠️ API failed, using fallback"; FMT_VERSION="10.2.1"; fi && \
    echo "💡 Building fmt version: $FMT_VERSION" && \
    wget -q --show-progress "https://github.com/fmtlib/fmt/archive/refs/tags/${FMT_VERSION}.tar.gz" -O fmt.tar.gz && \
    tar -xf fmt.tar.gz && cd fmt-${FMT_VERSION} && \
    cmake -DCMAKE_INSTALL_PREFIX=/usr/local -DBUILD_SHARED_LIBS=OFF -DFMT_TEST=OFF . && \
    make -j"$(nproc)" && make install && \
    cd .. && rm -rf fmt*

# 4. Compile Absolute Latest 'pugixml' (Statically Linked)
RUN echo "Fetching latest pugixml version..." && \
    PUGI_VERSION=$(curl -fsSL "https://api.github.com/repos/zeux/pugixml/tags" | jq -r '.[].name' | grep -oP '^v\K\d+\.\d+(\.\d+)?$' | sort -Vu | tail -n 1) && \
    if [ -z "$PUGI_VERSION" ]; then echo "⚠️ API failed, using fallback"; PUGI_VERSION="1.14"; fi && \
    echo "💡 Building pugixml version: $PUGI_VERSION" && \
    wget -q --show-progress "https://github.com/zeux/pugixml/archive/refs/tags/v${PUGI_VERSION}.tar.gz" -O pugixml.tar.gz && \
    tar -xf pugixml.tar.gz && cd pugixml-${PUGI_VERSION} && \
    cmake -DCMAKE_INSTALL_PREFIX=/usr/local -DBUILD_SHARED_LIBS=OFF -DPUGIXML_BUILD_TESTS=OFF . && \
    make -j"$(nproc)" && make install && \
    cd .. && rm -rf pugixml*

# 5. Compile Absolute Latest 'libebml' (Statically Linked)
RUN echo "Fetching latest libebml version..." && \
    EBML_VERSION=$(curl -fsSL "https://api.github.com/repos/Matroska-Org/libebml/tags" | jq -r '.[].name' | grep -oP '^release-\K\d+\.\d+(\.\d+)?$' | sort -Vu | tail -n 1) && \
    if [ -z "$EBML_VERSION" ]; then echo "⚠️ API failed, using fallback"; EBML_VERSION="1.4.5"; fi && \
    echo "💡 Building libebml version: $EBML_VERSION" && \
    wget -q --show-progress "https://github.com/Matroska-Org/libebml/archive/refs/tags/release-${EBML_VERSION}.tar.gz" -O libebml.tar.gz && \
    tar -xf libebml.tar.gz && cd libebml-release-${EBML_VERSION} && \
    cmake -DCMAKE_INSTALL_PREFIX=/usr/local -DBUILD_SHARED_LIBS=OFF . && \
    make -j"$(nproc)" && make install && \
    cd .. && rm -rf libebml*

# 6. Compile Absolute Latest 'libmatroska' (Statically Linked)
RUN echo "Fetching latest libmatroska version..." && \
    MATROSKA_VERSION=$(curl -fsSL "https://api.github.com/repos/Matroska-Org/libmatroska/tags" | jq -r '.[].name' | grep -oP '^release-\K\d+\.\d+(\.\d+)?$' | sort -Vu | tail -n 1) && \
    if [ -z "$MATROSKA_VERSION" ]; then echo "⚠️ API failed, using fallback"; MATROSKA_VERSION="1.7.1"; fi && \
    echo "💡 Building libmatroska version: $MATROSKA_VERSION" && \
    wget -q --show-progress "https://github.com/Matroska-Org/libmatroska/archive/refs/tags/release-${MATROSKA_VERSION}.tar.gz" -O libmatroska.tar.gz && \
    tar -xf libmatroska.tar.gz && cd libmatroska-release-${MATROSKA_VERSION} && \
    cmake -DCMAKE_INSTALL_PREFIX=/usr/local -DBUILD_SHARED_LIBS=OFF . && \
    make -j"$(nproc)" && make install && \
    cd .. && rm -rf libmatroska*

# 7. Compile Absolute Latest 'Boost' (Statically Linked)
RUN echo "Fetching latest Boost version..." && \
    BOOST_VERSION=$(curl -fsSL "https://archives.boost.io/release/" | grep -oP '(?<=href=")\d+\.\d+\.\d+(?=/")' | sort -Vu | tail -n 1) && \
    if [ -z "$BOOST_VERSION" ]; then echo "⚠️ API failed, using fallback"; BOOST_VERSION="1.85.0"; fi && \
    echo "💡 Building Boost version: $BOOST_VERSION" && \
    BOOST_UNDERSCORE="${BOOST_VERSION//./_}" && \
    wget -q --show-progress "https://archives.boost.io/release/${BOOST_VERSION}/source/boost_${BOOST_UNDERSCORE}.tar.bz2" -O boost.tar.bz2 && \
    tar -xf boost.tar.bz2 && cd "boost_${BOOST_UNDERSCORE}" && \
    ./bootstrap.sh --prefix=/usr/local && \
    ./b2 -j"$(nproc)" link=static variant=release threading=multi \
    --with-system --with-filesystem --with-regex --with-date_time install && \
    cd .. && rm -rf boost*

# ==========================================
# 🚀 COMPILE MKVTOOLNIX
# ==========================================

# Accept MKVToolNix version as a dynamic build argument
ARG MKV_VERSION

# Download and extract MKVToolNix source safely
RUN wget --progress=dot:giga "https://mkvtoolnix.download/sources/mkvtoolnix-${MKV_VERSION}.tar.xz" -O mkvtoolnix_src.tar.xz && \
    tar -xf mkvtoolnix_src.tar.xz

WORKDIR /mkvtoolnix-${MKV_VERSION}

# Configure the build. 
# Explicitly disable the GUI and Qt to save massive amounts of compilation time and space.
RUN ./configure \
    --prefix=/mkvtoolnix-build \
    --disable-gui \
    --disable-qt \
    --disable-update-check

# Compile with multi-core support directly passed to rake.
RUN rake -j"$(nproc)" && \
    rake install

# ==========================================
# 📦 PORTABLE WRAPPER GENERATION
# ==========================================
# 1. Create the portable directory structure
RUN mkdir -p /mkvtoolnix-portable/bin /mkvtoolnix-portable/lib && \
    cp /mkvtoolnix-build/bin/mkv* /mkvtoolnix-portable/bin/

# 2. Auto-detect and bundle any remaining shared libraries (.so files)
RUN for bin in /mkvtoolnix-portable/bin/mkv*; do \
        ldd "$bin" | grep "=> /" | awk '{print $3}' | while read -r lib; do \
            if [[ "$lib" != *"/libc.so"* && "$lib" != *"/libm.so"* && "$lib" != *"/libdl.so"* && "$lib" != *"/libpthread.so"* && "$lib" != *"/librt.so"* && "$lib" != *"/libgcc_s.so"* && "$lib" != *"/libstdc++.so"* ]]; then \
                cp -n "$lib" /mkvtoolnix-portable/lib/ || true; \
            fi; \
        done; \
    done

# 3. Create the Wrapper Scripts
RUN for bin in mkvmerge mkvpropedit mkvextract mkvinfo; do \
        if [ -f "/mkvtoolnix-portable/bin/$bin" ]; then \
            mv "/mkvtoolnix-portable/bin/$bin" "/mkvtoolnix-portable/bin/$bin.bin"; \
            echo '#!/bin/bash' > "/mkvtoolnix-portable/bin/$bin"; \
            echo 'DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"' >> "/mkvtoolnix-portable/bin/$bin"; \
            echo 'export LD_LIBRARY_PATH="$DIR/../lib:$LD_LIBRARY_PATH"' >> "/mkvtoolnix-portable/bin/$bin"; \
            echo 'exec "$DIR/$(basename "$0").bin" "$@"' >> "/mkvtoolnix-portable/bin/$bin"; \
            chmod +x "/mkvtoolnix-portable/bin/$bin"; \
        fi; \
    done

# 4. Strip debugging symbols from the actual binaries to shrink the final size
RUN find /mkvtoolnix-portable/bin -type f -name "*.bin" -exec strip --strip-all "{}" \;

# Use a scratch image to export ONLY the portable directory structure back to the host
FROM scratch AS export-stage
COPY --from=builder /mkvtoolnix-portable /