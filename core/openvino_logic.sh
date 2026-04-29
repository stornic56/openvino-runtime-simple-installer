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

    # Clean up any previous installation before proceeding
    if [ -d "/opt/intel/openvino_2026.0" ]; then
        print_warning "An existing OpenVINO installation was found. Removing it..."
        rm -rf "/opt/intel/openvino_2026.0"
    fi
    if [ -L "/opt/intel/openvino_2026" ]; then
        rm -f "/opt/intel/openvino_2026"
    fi

    print_substep "Unzipping $FILENAME..."
    tar -xf "$FILENAME"

    # The name of the extracted folder matches the name of the tarball without the .tgz extension
    DIRNAME="${FILENAME%.tgz}"
    if [ ! -d "$DIRNAME" ]; then
        # guess the real name
        DIRNAME=$(tar -tf "$FILENAME" | head -1 | cut -d/ -f1)
    fi
    print_substep "Moving $DIRNAME a /opt/intel/openvino_2026.0..."
    mkdir -p /opt/intel
    mv "$DIRNAME" "/opt/intel/openvino_2026.0"

    print_substep "Create symbolic link /opt/intel/openvino_2026..."
    ln -sf /opt/intel/openvino_2026.0 /opt/intel/openvino_2026
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
