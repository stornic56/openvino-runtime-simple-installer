#!/bin/bash
set -euo pipefail
# Ensure it runs as root from the orchestrator

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../core/common.sh"
source "$SCRIPT_DIR/../core/neo_apt.sh"

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
install_neo_packages

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
