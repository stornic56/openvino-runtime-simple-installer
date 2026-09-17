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
    ["intel-igc-core-2_2.40.13+22418_amd64.deb"]="ebd795e9fddf303a9b24b7f04545d8ddd9ad1f85b3d0cb1166476fab24da6d44"
    ["intel-igc-opencl-2_2.40.13+22418_amd64.deb"]="4f990874efc11c3f6091a663b08aef576c4af592dcd8f12e116f8c2fc92d34d9"
    ["intel-ocloc_26.31.39395.13-0_amd64.deb"]="12c5e61ed1dca5cbf38494e280abf88100a451580d57c44f601a17d9727e465e"
    ["intel-opencl-icd_26.31.39395.13-0_amd64.deb"]="5a9c9e8fdca8a2f9e22754b1a4618c7babf21d7c3ab3503c680005007c7a8c44"
    ["libigdgmm12_22.10.0_amd64.deb"]="6031a63d6e8a12ce61c14efc15f2c8e727061286e3820b8594e6d00615e04d54"
    ["libze-intel-gpu1_26.31.39395.13-0_amd64.deb"]="1722943f81b576b9bb8d61016464208f48ce533dc3bf24ad39605293115cc289"
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

download_and_verify "https://github.com/intel/intel-graphics-compiler/releases/download/v2.40.13/intel-igc-core-2_2.40.13+22418_amd64.deb" \
    "intel-igc-core-2_2.40.13+22418_amd64.deb" "${NEO_HASHES["intel-igc-core-2_2.40.13+22418_amd64.deb"]}"
download_and_verify "https://github.com/intel/intel-graphics-compiler/releases/download/v2.40.13/intel-igc-opencl-2_2.40.13+22418_amd64.deb" \
    "intel-igc-opencl-2_2.40.13+22418_amd64.deb" "${NEO_HASHES["intel-igc-opencl-2_2.40.13+22418_amd64.deb"]}"
download_and_verify "https://github.com/intel/compute-runtime/releases/download/26.31.39395.13/intel-ocloc_26.31.39395.13-0_amd64.deb" \
    "intel-ocloc_26.31.39395.13-0_amd64.deb" "${NEO_HASHES["intel-ocloc_26.31.39395.13-0_amd64.deb"]}"
download_and_verify "https://github.com/intel/compute-runtime/releases/download/26.31.39395.13/intel-opencl-icd_26.31.39395.13-0_amd64.deb" \
    "intel-opencl-icd_26.31.39395.13-0_amd64.deb" "${NEO_HASHES["intel-opencl-icd_26.31.39395.13-0_amd64.deb"]}"
download_and_verify "https://github.com/intel/compute-runtime/releases/download/26.31.39395.13/libigdgmm12_22.10.0_amd64.deb" \
    "libigdgmm12_22.10.0_amd64.deb" "${NEO_HASHES["libigdgmm12_22.10.0_amd64.deb"]}"
download_and_verify "https://github.com/intel/compute-runtime/releases/download/26.31.39395.13/libze-intel-gpu1_26.31.39395.13-0_amd64.deb" \
    "libze-intel-gpu1_26.31.39395.13-0_amd64.deb" "${NEO_HASHES["libze-intel-gpu1_26.31.39395.13-0_amd64.deb"]}"

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
