#!/bin/bash
set -euo pipefail

# common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

if [ $# -lt 2 ]; then
    print_error "Usage: $0 <URL> <OUTPUT_FILE> | $0 --install <FILE>"
    exit 1
fi

if [ "$1" = "--install" ]; then
    FILENAME="$2"
    if [ ! -f "$FILENAME" ]; then
        print_error "   $FILENAME could not be found to install."
        exit 1
    fi

    # Derive destination from version (official doc pattern: year.patch)
    # e.g. openvino_toolkit_ubuntu24_<VERSION>_x86_64.tgz -> /opt/intel/openvino_<YEAR.PATCH>
    VERSION_FULL="$(echo "$FILENAME" | cut -d_ -f4)"
    case "$VERSION_FULL" in
    20[0-9][0-9].*) ;; # valid version format, continue
    *)
        print_error "Could not derive version from: $FILENAME"
        exit 1
        ;;
    esac
    INSTALL_DIR="/opt/intel/openvino_$(echo "$VERSION_FULL" | cut -d. -f1-3)"

    # Replace policy (updates): remove ANY previous 2026 install and the previous symlink.
    # Known limitation: the previous install is deleted BEFORE extracting; if the tar
    # failed afterwards, the system would be left without OpenVINO. Acceptable because
    # the SHA256 was already verified during the download step.
    if ls -d /opt/intel/openvino_2026.* >/dev/null 2>&1; then
        print_warning "An existing OpenVINO installation was found. Replacing it..."
    fi
    rm -rf /opt/intel/openvino_2026    # remove previous symlink OR real directory (rm -rf does not follow symlinks)
    rm -rf /opt/intel/openvino_2026.* # ANY previous 2026 install
    mkdir -p /opt/intel

    DIRNAME="${FILENAME%.tgz}"   # known before tar (enables trap cleanup)
    trap 'rm -rf "$DIRNAME"' EXIT
    print_substep "Unzipping $FILENAME..."
    tar -xf "$FILENAME"

    if [ ! -d "$DIRNAME" ]; then
        # guess the real name
        TAR_LIST=$(tar -tf "$FILENAME")
        DIRNAME="${TAR_LIST%%$'\n'*}"   # first entry (no pipe, no SIGPIPE)
        DIRNAME="${DIRNAME%%/*}"
    fi
    print_substep "Moving $DIRNAME a $INSTALL_DIR..."
    mv "$DIRNAME" "$INSTALL_DIR"

    print_substep "Create symbolic link /opt/intel/openvino_2026..."
    ln -s "$INSTALL_DIR" /opt/intel/openvino_2026
    exit 0
fi

# Download and verification mode
URL="$1"
FILENAME="$2"

if [ -f "$FILENAME" ]; then
    print_warning "The file $FILENAME already exists. The download is skipped."
else
    print_substep "Download from $URL ..."
    wget -q --show-progress "$URL" -O "$FILENAME"
fi

# Download checksum if available
SHA_URL="${URL}.sha256"
SHA_FILE="${FILENAME}.sha256"
if wget -q --spider "$SHA_URL" 2>/dev/null; then
    print_substep "Downloading SHA256..."
    wget -q "$SHA_URL" -O "$SHA_FILE"
    EXPECTED=$(awk '{print $1}' "$SHA_FILE")
    print_substep "Verifying integrity of $FILENAME..."
    ACTUAL=$(sha256sum "$FILENAME" | awk '{print $1}')
    if [ "$ACTUAL" != "$EXPECTED" ]; then
        print_error "SHA256 verification failed!"
        echo "   Expected: $EXPECTED"
        echo "   Obtained:  $ACTUAL"
        print_error "The file may be corrupt or manipulated."
        exit 1
    fi
    print_substep "SHA256 verified successfully."
else
    print_warning "No .sha256 file was found for $FILENAME. Verification will be skipped."
fi
