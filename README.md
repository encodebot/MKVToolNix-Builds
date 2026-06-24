# MKVToolNix-Builds
MKVToolNix Builds For ARM64 & AMD64

# Automated MKVToolNix Compiler

An optimized, cloud-native automation pipeline that monitors upstream official mirrors for stable MKVToolNix releases and automatically builds highly portable, headless executable packages for **linux/amd64** and **linux/arm64** architectures.

---

## 🚀 Key Features

* **Native Multi-Architecture Compilation**: Avoids slow QEMU emulation overhead by utilizing GitHub’s native AMD64 and ARM64 runners.
* **100% Portable & Headless**: Compiled with GUI tools disabled (`--disable-gui --disable-qt`). Uses an advanced `ldd` wrapper to bundle all required shared libraries natively. Core dependencies (`libebml`, `libmatroska`, `Boost`, `fmt`, `pugixml`) are compiled from source and statically linked to maximize portability across various Linux environments with zero `apt-get` prerequisites.
<!-- ❌ Delete This Block Later, When Re-Enable Caching. ❌
* **Robust Docker Remote Caching**: Implements `--cache-to/from type=gha` layers to guarantee subsequent code builds complete within minutes. -->
* **Automatic Security Checksums**: Every build dynamically computes and attaches an authoritative `checksums.sha256` verification manifest to the GitHub Release.
* **Autonomous Pipeline Maintenance**: Integrated self-cleaning logic stores only the latest 4 production releases while automated keepalive protocols prevent GitHub Actions from sleeping.

---

## ⚙️ Automated Pipeline Policies

### 🕒 Build Schedule
* **Execution Interval**: Builds trigger automatically every week at **02:00 AM UTC On Sundays, Tuesdays, Thursdays & Saturdays**, as well as on manual execution via `workflow_dispatch`.
* **Smart Verification**: The compiler checks upstream `mkvtoolnix.download` releases first, utilizing advanced RegEx to filter out beta/RC versions. If a brand-new stable upstream version is detected, a clean build is triggered. If no upstream updates exist, the workflow automatically force-rebuilds the current version to apply the latest security patches to all bundled dependencies.

### 💻 Target Architectures
This project focuses explicitly on delivering high-performance, optimized **64-bit Linux environments**. 
* **Supported Architectures**: Native executable directory structures (with bundled `.so` libraries) are compiled and packaged into `.tar.xz` archives for **linux/amd64** (`x86_64`) and **linux/arm64** (`aarch64`).
* **Non-Supported Environments**: There are no active automated builds for Windows or 32-bit platforms. However, you can use the provided standalone `Dockerfile` to manually compile your target configurations locally.

### 🗑️ Release Retention Policy
To prevent repository bloat while maintaining quick access to stable historical versions, the pipeline enforces a strict self-cleaning cycle:
* **The Last 4 Releases Are Kept**: The cleanup script evaluates the storage history on every successful release and retains exactly the **4 most recent production versions**.
* **Automatic Tag Purging**: Releases older than the top 4 are automatically removed along with their corresponding git repository tags.
* **Deterministic Version Tags**: Releases use explicit upstream version naming conventions (e.g., `v85.0`), allowing you to anchor your production scripts to unchanging, specific versions.

---

## 🛠️ Infrastructure Overview

```mermaid
graph TD
    A[Cron Schedule / Manual Dispatch] --> B{Version Check}
    B -- Upstream == Local Tag --> C[Force Rebuild <br> Security Updates]
    B -- New Version Found --> D[New Release <br> Clean Build]
    C --> M[Parallel Build Matrix]
    D --> M

    subgraph Build Platforms.
    M --> E[linux/amd64 <br> ubuntu-26.04]
    M --> F[linux/arm64 <br> ubuntu-26.04-arm]
    end

    E --> G[Generate Hashes <br> sha256sum]
    F --> G
    G --> H[Overwrites Old Tag <br> If Rebuilding]
    H --> I[Publishes Assets]
    I --> J[Purges Old Releases]

    style C fill:#ffeb99,stroke:#333,stroke-width:2px
    style D fill:#baffc9,stroke:#333,stroke-width:2px
    style H fill:#e3a6c3,stroke:#333,stroke-width:2px
    style I fill:#e3a6c3,stroke:#333,stroke-width:2px
    style J fill:#e3a6c3,stroke:#333,stroke-width:2px
```