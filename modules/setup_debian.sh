#!/bin/bash
set -euo pipefail
# Ensure it runs as root from the orchestrator

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../core/common.sh"

print_step "Debian Module – Drivers and Multimedia"

# ---- Configure sources.list ----
print_substep "Ensuring non-free components in sources.list..."
SOURCES_FILE="/etc/apt/sources.list"
if [ -f "$SOURCES_FILE" ]; then
    sed -i 's/^\(deb.*trixie.*main\)[^#]*/\1 contrib non-free non-free-firmware/' "$SOURCES_FILE"
    sed -i 's/^\(deb.*trixie-security.*main\)[^#]*/\1 contrib non-free non-free-firmware/' "$SOURCES_FILE"
    sed -i 's/^\(deb.*trixie-updates.*main\)[^#]*/\1 contrib non-free non-free-firmware/' "$SOURCES_FILE"
fi

if [ -f /etc/apt/sources.list.d/debian.sources ]; then
    print_substep "Deleting duplicate DEB822 file..."
    rm -f /etc/apt/sources.list.d/debian.sources
fi
apt-get update

# ---- Multimedia and diagnostic packages ----
print_substep "Installing graphics and diagnostic packages..."
apt-get install -y \
    python3-numpy libmfx-gen1.2 libvpl2 libegl-mesa0 libegl1-mesa-dev libgbm1 \
    libgl1-mesa-dri libglapi-mesa libgles2-mesa-dev libglx-mesa0 libxatracker2 \
    mesa-libgallium vainfo clinfo nvtop ocl-icd-libopencl1

print_substep "Installing Intel video driver..."
if apt-get install -y intel-media-va-driver-non-free; then
    print_substep "Driver non-free installed."
else
    print_warning "No non-free version found, trying the free version..."
    apt-get install -y intel-media-va-driver
fi

# ---- Install NEO from GitHub ----
print_substep "Downloading and installing NEO…"
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"
trap 'rm -rf "$TEMP_DIR"' EXIT

# Hashes SHA256
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

print_substep "Instalando paquetes deb..."
apt-get install -y ./*.deb

cd /
rm -rf "$TEMP_DIR"

# ---- Add user to groups ----
print_substep "Adding user to render and video groups..."
if [ -n "${SUDO_USER:-}" ]; then
    usermod -a -G render,video "$SUDO_USER"
else
    # root
    current_user="${SUDO_USER:-$(logname 2>/dev/null || id -un)}"
    usermod -a -G render,video "$current_user"
fi
