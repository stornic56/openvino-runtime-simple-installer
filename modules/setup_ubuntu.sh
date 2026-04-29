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
    ["intel-igc-core-2_2.30.1+20950_amd64.deb"]="0a3114a6f74bf6382d5976633c262ff4c392273828424fce04c7185071f8b2ca"
    ["intel-igc-opencl-2_2.30.1+20950_amd64.deb"]="9b24a5778af3c4a6bd211a21e7b6860fde9c6869b29c7c4423b5b1a949db13fd"
    ["intel-ocloc_26.09.37435.1-0_amd64.deb"]="893185ee9df9656f1350d701bffc240a7ec04021879e0b8ac645dd1db419cd9e"
    ["intel-opencl-icd_26.09.37435.1-0_amd64.deb"]="611c758c169a81c91bfc0b089cb6a53949ec2b6aedbf892635a579c529c63e7a"
    ["libigdgmm12_22.9.0_amd64.deb"]="9d712f71c18baee076de9961dda71e8089291e1bd0deb5d649ab5ba5de114f97"
    ["libze-intel-gpu1_26.09.37435.1-0_amd64.deb"]="9fb35fbccbb5f85a60283803de961398ec8ae7d23bfd07f1f272307f596972c9"
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

download_and_verify "https://github.com/intel/intel-graphics-compiler/releases/download/v2.30.1/intel-igc-core-2_2.30.1+20950_amd64.deb" \
    "intel-igc-core-2_2.30.1+20950_amd64.deb" "${NEO_HASHES["intel-igc-core-2_2.30.1+20950_amd64.deb"]}"
download_and_verify "https://github.com/intel/intel-graphics-compiler/releases/download/v2.30.1/intel-igc-opencl-2_2.30.1+20950_amd64.deb" \
    "intel-igc-opencl-2_2.30.1+20950_amd64.deb" "${NEO_HASHES["intel-igc-opencl-2_2.30.1+20950_amd64.deb"]}"
download_and_verify "https://github.com/intel/compute-runtime/releases/download/26.09.37435.1/intel-ocloc_26.09.37435.1-0_amd64.deb" \
    "intel-ocloc_26.09.37435.1-0_amd64.deb" "${NEO_HASHES["intel-ocloc_26.09.37435.1-0_amd64.deb"]}"
download_and_verify "https://github.com/intel/compute-runtime/releases/download/26.09.37435.1/intel-opencl-icd_26.09.37435.1-0_amd64.deb" \
    "intel-opencl-icd_26.09.37435.1-0_amd64.deb" "${NEO_HASHES["intel-opencl-icd_26.09.37435.1-0_amd64.deb"]}"
download_and_verify "https://github.com/intel/compute-runtime/releases/download/26.09.37435.1/libigdgmm12_22.9.0_amd64.deb" \
    "libigdgmm12_22.9.0_amd64.deb" "${NEO_HASHES["libigdgmm12_22.9.0_amd64.deb"]}"
download_and_verify "https://github.com/intel/compute-runtime/releases/download/26.09.37435.1/libze-intel-gpu1_26.09.37435.1-0_amd64.deb" \
    "libze-intel-gpu1_26.09.37435.1-0_amd64.deb" "${NEO_HASHES["libze-intel-gpu1_26.09.37435.1-0_amd64.deb"]}"

dpkg -i libigdgmm12_22.9.0_amd64.deb
dpkg -i intel-igc-core-2_2.30.1+20950_amd64.deb
dpkg -i intel-igc-opencl-2_2.30.1+20950_amd64.deb
dpkg -i intel-ocloc_26.09.37435.1-0_amd64.deb
dpkg -i libze-intel-gpu1_26.09.37435.1-0_amd64.deb
dpkg -i intel-opencl-icd_26.09.37435.1-0_amd64.deb
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
