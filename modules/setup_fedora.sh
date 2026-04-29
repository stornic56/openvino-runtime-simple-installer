#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../core/common.sh"

print_step "Fedora Module – Drivers and Multimedia"

# ---- 1. Instalar NEO completo y herramientas ----
print_substep "Installing Intel Compute Runtime (NEO)"
dnf install -y intel-compute-runtime clinfo vainfo nvtop

# ---- 2. Driver multimedia Intel ----
print_substep "Installing VAAPI Intel driver..."
dnf install -y libva-intel-media-driver

# ---- 3. Paquetes adicionales (VPL, GBM) ----
print_substep "Installing libvpl and mesa-libgbm..."
dnf install -y libvpl mesa-libgbm

# ---- 4. Añadir usuario a grupos ----
print_substep "Adding user to render and video groups (if they exist)..."
if [ -n "${SUDO_USER:-}" ]; then
    usermod -a -G render,video "$SUDO_USER"
else
    current_user=$(logname 2>/dev/null || echo "$USER")
    usermod -a -G render,video "$current_user"
fi
