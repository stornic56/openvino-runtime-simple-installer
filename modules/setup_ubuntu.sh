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
# TODO (H0 watch-out): Debian 13 required dropping mesa-va-drivers AND mesa-vdpau-drivers
# in favor of mesa-libgallium (Mesa >= 25.2 moved the gallium VA-API and VDPAU drivers into
# mesa-libgallium, which Breaks both old names < 25.2.8-3; no amd64 version >= 25.2.8-3
# exists in trixie nor backports -- see setup_debian.sh). Ubuntu 24.04 is not affected
# (mesa 24.x, real packages). Ubuntu 26.04 may be affected if it ships Mesa >= 25.2 (same
# transition) -- change only with evidence.
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
trap 'rm -rf "$TEMP_DIR"' EXIT

declare -A NEO_HASHES=(
    ["intel-igc-core-2_2.41.5+22716_amd64.deb"]="0a6e64a663ae65a0fa02d6912ae3b6b37cf85b90c21cc423fd9fef70aaf4f628"
    ["intel-igc-opencl-2_2.41.5+22716_amd64.deb"]="779e1b9e88098eb25711e9a8f67c2752665bad22f134aa40ed5649f6e1b87058"
    ["intel-ocloc_26.35.39758.10-0_amd64.deb"]="c64bff586edf2bd9b49f3e4c9c2be25e05c43466e4dafa2a2c3948d498c736b7"
    ["intel-opencl-icd_26.35.39758.10-0_amd64.deb"]="61712caaddeba3d38e4f79e2a0fb23fea25596ca2d72c3144c6eea2331ec4301"
    ["libigdgmm12_22.10.0_amd64.deb"]="6031a63d6e8a12ce61c14efc15f2c8e727061286e3820b8594e6d00615e04d54"
    ["libze-intel-gpu1_26.35.39758.10-0_amd64.deb"]="c19a641b953d55aebbf1d51bec364a84bf629f985e02fbbe6dc70224c0e88470"
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

download_and_verify "https://github.com/intel/intel-graphics-compiler/releases/download/v2.41.5/intel-igc-core-2_2.41.5+22716_amd64.deb" \
    "intel-igc-core-2_2.41.5+22716_amd64.deb" "${NEO_HASHES["intel-igc-core-2_2.41.5+22716_amd64.deb"]}"
download_and_verify "https://github.com/intel/intel-graphics-compiler/releases/download/v2.41.5/intel-igc-opencl-2_2.41.5+22716_amd64.deb" \
    "intel-igc-opencl-2_2.41.5+22716_amd64.deb" "${NEO_HASHES["intel-igc-opencl-2_2.41.5+22716_amd64.deb"]}"
download_and_verify "https://github.com/intel/compute-runtime/releases/download/26.35.39758.10/intel-ocloc_26.35.39758.10-0_amd64.deb" \
    "intel-ocloc_26.35.39758.10-0_amd64.deb" "${NEO_HASHES["intel-ocloc_26.35.39758.10-0_amd64.deb"]}"
download_and_verify "https://github.com/intel/compute-runtime/releases/download/26.35.39758.10/intel-opencl-icd_26.35.39758.10-0_amd64.deb" \
    "intel-opencl-icd_26.35.39758.10-0_amd64.deb" "${NEO_HASHES["intel-opencl-icd_26.35.39758.10-0_amd64.deb"]}"
download_and_verify "https://github.com/intel/compute-runtime/releases/download/26.35.39758.10/libigdgmm12_22.10.0_amd64.deb" \
    "libigdgmm12_22.10.0_amd64.deb" "${NEO_HASHES["libigdgmm12_22.10.0_amd64.deb"]}"
download_and_verify "https://github.com/intel/compute-runtime/releases/download/26.35.39758.10/libze-intel-gpu1_26.35.39758.10-0_amd64.deb" \
    "libze-intel-gpu1_26.35.39758.10-0_amd64.deb" "${NEO_HASHES["libze-intel-gpu1_26.35.39758.10-0_amd64.deb"]}"

apt-get install -y ./*.deb

cd /
rm -rf "$TEMP_DIR"

# ---- 4. add user ----
print_substep "Añadiendo usuario a grupos render y video..."
if [ -n "${SUDO_USER:-}" ]; then
    usermod -a -G render,video "$SUDO_USER"
else
    current_user="${SUDO_USER:-$(logname 2>/dev/null || id -un)}"
    usermod -a -G render,video "$current_user"
fi
