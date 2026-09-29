#!/bin/bash
# ------------------------------------------------------------------------------
# Shared NEO block: version variables, SHA256 hashes, download with
# verification and install via apt. Sourced by the setup_*.sh modules.
#
# The next version update changes ONLY the 4 variables here
# (+ the NEO_HASHES values if the hashes change).
# Requires: common.sh already sourced (uses print_*), CWD = TEMP_DIR when
# calling install_neo_packages.
# ------------------------------------------------------------------------------

# --- Versions (pinned; no auto-detection) ---
IGC_TAG="v2.41.5"                 # release tag in intel/intel-graphics-compiler
IGC_BUILD="22716"                 # IGC package build: 2.41.5+22716
IGC_VERSION="${IGC_TAG#v}"        # derived: 2.41.5
NEO_VERSION="26.35.39758.10"      # release in intel/compute-runtime
GMM_VERSION="22.10.0"             # libigdgmm12 (stable across releases)

# --- SHA256 hashes by package name (values change with each version) ---
declare -A NEO_HASHES=(
    ["intel-igc-core-2"]="0a6e64a663ae65a0fa02d6912ae3b6b37cf85b90c21cc423fd9fef70aaf4f628"
    ["intel-igc-opencl-2"]="779e1b9e88098eb25711e9a8f67c2752665bad22f134aa40ed5649f6e1b87058"
    ["intel-ocloc"]="c64bff586edf2bd9b49f3e4c9c2be25e05c43466e4dafa2a2c3948d498c736b7"
    ["intel-opencl-icd"]="61712caaddeba3d38e4f79e2a0fb23fea25596ca2d72c3144c6eea2331ec4301"
    ["libigdgmm12"]="6031a63d6e8a12ce61c14efc15f2c8e727061286e3820b8594e6d00615e04d54"
    ["libze-intel-gpu1"]="c19a641b953d55aebbf1d51bec364a84bf629f985e02fbbe6dc70224c0e88470"
)

# --- Package filename by family ---
neo_pkg_filename() {
    case "$1" in
        intel-igc-core-2|intel-igc-opencl-2)
            echo "${1}_${IGC_VERSION}+${IGC_BUILD}_amd64.deb" ;;
        libigdgmm12)
            echo "${1}_${GMM_VERSION}_amd64.deb" ;;
        *)
            echo "${1}_${NEO_VERSION}-0_amd64.deb" ;;
    esac
}

# --- Download URL by family ---
neo_pkg_url() {
    case "$1" in
        intel-igc-core-2|intel-igc-opencl-2)
            echo "https://github.com/intel/intel-graphics-compiler/releases/download/${IGC_TAG}/$(neo_pkg_filename "$1")" ;;
        *)
            echo "https://github.com/intel/compute-runtime/releases/download/${NEO_VERSION}/$(neo_pkg_filename "$1")" ;;
    esac
}

# --- Download with SHA256 verification ---
download_and_verify() {
    local url="$1"
    local filename="$2"
    local expected="$3"
    wget -q --show-progress "$url" -O "$filename"
    local actual
    actual=$(sha256sum "$filename" | awk '{print $1}')
    if [ "$actual" != "$expected" ]; then
        print_error "SHA256 mismatch for $filename"
        exit 1
    fi
}

# --- Download + verify + install of the 6 production packages ---
install_neo_packages() {
    local pkg f
    for pkg in intel-igc-core-2 intel-igc-opencl-2 intel-ocloc libigdgmm12 libze-intel-gpu1 intel-opencl-icd; do
        f="$(neo_pkg_filename "$pkg")"
        download_and_verify "$(neo_pkg_url "$pkg")" "$f" "${NEO_HASHES[$pkg]}"
    done

    print_substep "Installing deb packages..."
    apt-get install -y ./*.deb
}
