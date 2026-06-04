#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../core/common.sh"

print_step "Ubuntu Module – Drivers and Multimedia"

# ---- 1. Actualizar repositorios ----
print_substep "Updating package list..."
apt-get update

# ---- 2. Paquetes multimedia y diagnóstico ----
print_substep "Installing graphics and diagnostic packages..."
apt-get install -y \
    python3-numpy libmfx-gen1.2 libvpl2 libegl-mesa0 libegl1-mesa-dev libgbm1 \
    libgl1-mesa-dri libglapi-mesa libgles2-mesa-dev libglx-mesa0 libxatracker2 \
    mesa-va-drivers mesa-vdpau-drivers vainfo clinfo nvtop ocl-icd-libopencl1

print_substep "Installing Intel non-free video driver..."
apt-get install -y intel-media-va-driver-non-free

# ---- 3. Install NEO ----
print_substep "Downloading and installing NEO…"
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"

declare -A NEO_HASHES=(
    ["intel-igc-core-2_2.34.4+21428_amd64.deb"]="1150de9f1b8c06aab0bf6e619a6c02ed4cd0c7b4135752ae74c82c8f8fb7acb2"
    ["intel-igc-opencl-2_2.34.4+21428_amd64.deb"]="f36cb8a6899353c61cc7261b650f287f4a652acadaad859103bdfc51f93b6e8a"
    ["intel-ocloc_26.18.38308.1-0_amd64.deb"]="74b98d91a92d59c487e4938175284e57d5a84ec35d9997a9d65fa4db3f51b96b"
    ["intel-opencl-icd_26.18.38308.1-0_amd64.deb"]="b2d0c924e56b3f9e5837774d68b0c67461b8633035d93ca18b1a8e3e5ead15fa"
    ["libigdgmm12_22.10.0_amd64.deb"]="6031a63d6e8a12ce61c14efc15f2c8e727061286e3820b8594e6d00615e04d54"
    ["libze-intel-gpu1_26.18.38308.1-0_amd64.deb"]="12b8254e6d3415c32cee9cd13943030b991d91212445c79fe1cc27176a72eca4"
)

download_and_verify() {
    local url="$1"
    local filename="$2"
    local expected="$3"
    wget -q --show-progress "$url" -O "$filename"
    actual=$(sha256sum "$filename" | awk '{print $1}')
    if [ "$actual" != "$expected" ]; then
        print_error "SHA256 mismatch para $filename"
        exit 1
    fi
}

download_and_verify "https://github.com/intel/intel-graphics-compiler/releases/download/v2.34.4/intel-igc-core-2_2.34.4+21428_amd64.deb" \
    "intel-igc-core-2_2.34.4+21428_amd64.deb" "${NEO_HASHES["intel-igc-core-2_2.34.4+21428_amd64.deb"]}"
download_and_verify "https://github.com/intel/intel-graphics-compiler/releases/download/v2.34.4/intel-igc-opencl-2_2.34.4+21428_amd64.deb" \
    "intel-igc-opencl-2_2.34.4+21428_amd64.deb" "${NEO_HASHES["intel-igc-opencl-2_2.34.4+21428_amd64.deb"]}"
download_and_verify "https://github.com/intel/compute-runtime/releases/download/26.18.38308.1/intel-ocloc_26.18.38308.1-0_amd64.deb" \
    "intel-ocloc_26.18.38308.1-0_amd64.deb" "${NEO_HASHES["intel-ocloc_26.18.38308.1-0_amd64.deb"]}"
download_and_verify "https://github.com/intel/compute-runtime/releases/download/26.18.38308.1/intel-opencl-icd_26.18.38308.1-0_amd64.deb" \
    "intel-opencl-icd_26.18.38308.1-0_amd64.deb" "${NEO_HASHES["intel-opencl-icd_26.18.38308.1-0_amd64.deb"]}"
download_and_verify "https://github.com/intel/compute-runtime/releases/download/26.18.38308.1/libigdgmm12_22.10.0_amd64.deb" \
    "libigdgmm12_22.10.0_amd64.deb" "${NEO_HASHES["libigdgmm12_22.10.0_amd64.deb"]}"
download_and_verify "https://github.com/intel/compute-runtime/releases/download/26.18.38308.1/libze-intel-gpu1_26.18.38308.1-0_amd64.deb" \
    "libze-intel-gpu1_26.18.38308.1-0_amd64.deb" "${NEO_HASHES["libze-intel-gpu1_26.18.38308.1-0_amd64.deb"]}"

dpkg -i libigdgmm12_22.10.0_amd64.deb

dpkg -i intel-igc-core-2_2.34.4+21428_amd64.deb

dpkg -i intel-igc-opencl-2_2.34.4+21428_amd64.deb

dpkg -i intel-ocloc_26.18.38308.1-0_amd64.deb

dpkg -i libze-intel-gpu1_26.18.38308.1-0_amd64.deb

dpkg -i intel-opencl-icd_26.18.38308.1-0_amd64.deb
apt-get install -f -y

cd /
rm -rf "$TEMP_DIR"

# ---- 4. add user ----
print_substep "Añadiendo usuario a grupos render y video..."
if [ -n "${SUDO_USER:-}" ]; then
    usermod -a -G render,video "$SUDO_USER"
else
    current_user=$(logname 2>/dev/null || echo "$USER")
    usermod -a -G render,video "$current_user"
fi
