#!/bin/bash
set -euo pipefail

# ------------------------------------------------------------------------------
# OpenVINO Simple Installer – Orquestador
# Detects OS, Intel GPU, installs drivers (NEO), dependencies and the runtime.
# It supports Debian 13, Ubuntu 22.04/24.04/26.04, and Fedora (latest stable versions).
# ------------------------------------------------------------------------------

# privileges
if [ "$EUID" -ne 0 ]; then
    echo "ERROR: This script must be run as root. Use:"
    echo "  sudo bash $0"
    exit 1
fi

# routes
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CORE_DIR="$SCRIPT_DIR/core"
MODULES_DIR="$SCRIPT_DIR/modules"
DEPS_DIR="$SCRIPT_DIR/deps"

# print
source "$CORE_DIR/common.sh"

print_step "============================================="
print_step "  OpenVINO 2026 - SimpleInstaller"
print_step "============================================="

# ------------------------------------------------------------------------------
# 1. Detect operating system
# ------------------------------------------------------------------------------
print_step "1. Detecting operating system..."

if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS_ID="$ID"
    VERSION_ID="$VERSION_ID"
else
    print_error "Could not read /etc/os-release. Unsupported system."
    exit 1
fi

print_substep "System detected: $OS_ID $VERSION_ID"

# Prefix mapping
case "$OS_ID" in
    debian)
        PREFIX="ubuntu24"   # Tested and working on Debian 13
        ;;
    ubuntu)
        case "$VERSION_ID" in
            22.04) PREFIX="ubuntu22" ;;
            24.04|26.04) PREFIX="ubuntu24" ;;
            *)
                print_error "Unsupported Ubuntu version: $VERSION_ID"
                exit 1
                ;;
        esac
        ;;
    fedora)
        PREFIX="rhel8"
        ;;
    *)
        print_error "Unsupported distribution: $OS_ID"
        exit 1
        ;;
esac

# ------------------------------------------------------------------------------
# 2. Detect Intel GPU
# ------------------------------------------------------------------------------
print_step "2. Detecting Intel GPU..."

if GPU_LINE=$(lspci -nn | grep -i "vga\|3d\|display" | grep -i "intel" | head -1); then
    GPU_NAME=$(echo "$GPU_LINE" | awk -F': ' '{print $2}')
    print_substep "Intel GPU detected: $GPU_NAME"
    GPU_PRESENT=true
else
    print_warning "No Intel GPU was detected."
    GPU_PRESENT=false
    read -p "Do you want to continue the installation WITHOUT GPU support? [y/n]: " response
    case "$response" in
        [yY]*) ;;
        *)
            print_error "Installation cancelled by the user."
            exit 0
            ;;
    esac
fi

# ------------------------------------------------------------------------------
# 3. Install NEO (only if there is a GPU)
# ------------------------------------------------------------------------------
if $GPU_PRESENT; then
    print_step "3. Installing GPU drivers (Intel Compute Runtime NEO)..."
    case "$OS_ID" in
        debian)
            bash "$MODULES_DIR/setup_debian.sh"
            ;;
        ubuntu)
            bash "$MODULES_DIR/setup_ubuntu.sh"
            ;;
        fedora)
            bash "$MODULES_DIR/setup_fedora.sh"
            ;;
    esac
else
    print_step "3. Skipping NEO driver installation (no Intel GPU)."
fi

# ------------------------------------------------------------------------------
# 4. Download OpenVINO Runtime
# ------------------------------------------------------------------------------
print_step "4. Downloading OpenVINO Runtime package..."
BASE_URL="https://storage.openvinotoolkit.org/repositories/openvino/packages/2026.0/linux"
VERSION="2026.0.0.20965.c6d6a13a886"
FILENAME="openvino_toolkit_${PREFIX}_${VERSION}_x86_64.tgz"
URL="$BASE_URL/$FILENAME"

bash "$CORE_DIR/openvino_logic.sh" "$URL" "$FILENAME"

# ------------------------------------------------------------------------------
# 5. Verify the integrity of the downloaded package
# ------------------------------------------------------------------------------
print_step "5. Integrity verification completed."

# ------------------------------------------------------------------------------
# 6. Install system dependencies for OpenVINO
# ------------------------------------------------------------------------------
print_step "6. Installing system dependencies (Python, cmake, etc.)..."
bash "$DEPS_DIR/install_openvino_dependencies.sh" -y

# ------------------------------------------------------------------------------
# 7. Install OpenVINO
# ------------------------------------------------------------------------------
print_step "7. Installing OpenVINO structure in /opt/intel..."
bash "$CORE_DIR/openvino_logic.sh" --install "$FILENAME"

# ------------------------------------------------------------------------------
# Final message
# ------------------------------------------------------------------------------
print_step "Installation completed successfully!"

# installed version
if [ -f "/opt/intel/openvino_2026.0/runtime/version.txt" ]; then
    echo "Version: $(cat /opt/intel/openvino_2026.0/runtime/version.txt)"
else
    echo "Version: could not be determined"
fi

echo ""
echo "To start using OpenVINO run:"
echo "  source /opt/intel/openvino_2026/setupvars.sh"
echo ""
echo "----------------------------------------------------------------------"

if $GPU_PRESENT; then
    echo "IMPORTANT NOTES:"
    echo "1. Restart your session (or system) for the group changes (render, video) to take effect and for you to be able to use the GPU."
    echo "2. Check the OpenCL status with: clinfo"
    echo "3. Check video acceleration: vainfo"
    echo "4. Monitor your GPU in real time: nvtop"
    echo "----------------------------------------------------------------------"
else
    echo "No GPU drivers or diagnostic tools were installed."
    echo "You can use OpenVINO in CPU mode only."
    echo "----------------------------------------------------------------------"
fi

# note for Debian (backports)
if [ "$OS_ID" = "debian" ]; then
    if ! grep -q "trixie-backports" /etc/apt/sources.list /etc/apt/sources.list.d/* 2>/dev/null; then
        echo "NOTE ON VERY RECENT HARDWARE (Battlemage):"
        echo "If after restarting the GPU is not recognized (clinfo or vainfo do not"
        echo "show devices), you might need a more modern kernel."
        echo "Run the following commands:"
        echo "  echo 'deb http://deb.debian.org/debian/ trixie-backports main contrib non-free non-free-firmware' | sudo tee /etc/apt/sources.list.d/backports.list"
        echo "  sudo apt update"
        echo "  sudo apt install -t trixie-backports linux-image-amd64 firmware-linux"
        echo "  sudo reboot"
    fi
fi
