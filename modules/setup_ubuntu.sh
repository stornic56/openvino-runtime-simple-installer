#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../core/common.sh"
source "$SCRIPT_DIR/../core/neo_apt.sh"

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

install_neo_packages

cd /
rm -rf "$TEMP_DIR"

# ---- 4. add user ----
print_substep "Adding user to render and video groups..."
if [ -n "${SUDO_USER:-}" ]; then
    usermod -a -G render,video "$SUDO_USER"
else
    current_user="${SUDO_USER:-$(logname 2>/dev/null || id -un)}"
    usermod -a -G render,video "$current_user"
fi
