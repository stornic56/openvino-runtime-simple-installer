# Description

This project repository provides a comprehensive automated installation and configuration script for Intel hardware acceleration. The primary utility is to orchestrate the setup of OpenVINO Runtime 2026 along with necessary Intellectual Property Compute runtime drivers (NEO). This script establishes the required dependencies, system libraries, and GPU access layers essential for `llama.cpp` leveraging Intel GPUs.

## Supported Operating Systems

*   Debian 13
*   Ubuntu 24.04
*   Ubuntu 26.04
*   Fedora 43

---

## Usage Instructions

The installer scripts are designed to be executed as a root user (`sudo`). Ensure all necessary system dependencies (such as `git`, `wget`, and the respective package managers like `dpkg`/`dnf`) exist before execution.

### Setup & Clone Repository
First, clone the repository from GitHub:
```bash
# 1. Clone the installer repository
git clone https://github.com/stornic56/openvino-runtime-simple-installer
cd openvino-runtime-simple-installer

# 2. Grant execute permissions to the main orchestrator script
chmod +x main.sh
```

### Execution
Execute the primary installation script using elevated privileges (root access is mandatory):
```bash
sudo ./main.sh
```

## Components Installed

The execution of `main.sh` automatically handles OS detection and conditionally installs components based on hardware presence, ensuring a fully configured inference pipeline:

**Core Runtime & Libraries:**
*   **OpenVINO Toolkit 2026.0:** The complete runtime package is downloaded from the official OpenVINO repository (`https://storage.openvinotoolkit.org/repositories/openvino/packages/2026.0/linux`) and installed under `/opt/intel/openvino_2026`. It is the same version used within llama.cpp.
*   **System Dependencies:** Required libraries, including `cmake`, Python 3 (with version-specific dependencies like `libpython3.13` for Debian 13 or `libpython3.13` for Ubuntu 26.04), GCC compilers (`g++`), NumPy bindings, and standard development tools are installed via system package managers (`apt`/`dnf`).

**Hardware Acceleration & Drivers (NEO):**
*   **Intel Compute Runtime NEO:** If an Intel GPU is detected, the respective module script installs critical proprietary drivers:
    *   `intel-igc-core`: Graphics Compiler core components.
    *   `intel-igc-opencl`: OpenCL interface libraries for graphics compilation.
    *   `intel-ocloc`/`libze-intel-gpu1`: Compute Runtime interfaces and GPU acceleration layers (OpenCL/oneAPI).
    *   **Multimedia Support:** Installation of `mesa-va-drivers`, `vainfo`, and related packages to ensure Video Acceleration API support, crucial for media inference tasks.

**Environment Configuration:**
*   User permissions are configured by adding the executing user (`$SUDO_USER`) to the system groups `render` and `video` to allow proper GPU access post-installation.


## After Installation

```bash
1. Load the OpenVINO environment
source /opt/intel/openvino_2026/setupvars.sh

2. Verify installation
echo $INTEL_OPENVINO_DIR 

3. Check Intel GPU
clinfo | grep -i "device name"

4. Check video acceleration
vainfo
```
## Note:
Users should reference the following official projects:
- Llamacpp: [Official Repository Link](https://github.com/ggml-org/llama.cpp) [OpenvinoBackend](https://github.com/ggml-org/llama.cpp/blob/master/docs/backend/OPENVINO.md)
- OpenVino Toolkit: [Official Website/Repository Link](https://docs.openvino.ai/2026/get-started/install-openvino/install-openvino-archive-linux.html)
- Intel NEO Drivers: [Intel Compute Runtime](https://github.com/intel/compute-runtime))
