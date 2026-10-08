#!/bin/bash
# ------------------------------------------------------------------------------
# uninstall: removes OpenVINO Runtime (and optionally the NEO drivers).
# Sourced by main.sh (uninstall subcommand). Requires root to operate.
# Arguments: --purge-drivers (dpkg -r of the 6 NEO packages), --yes (no prompt).
# ------------------------------------------------------------------------------

run_uninstall() {
    local PURGE_DRIVERS=false
    local ASSUME_YES=false
    while [ $# -gt 0 ]; do
        case "$1" in
        --purge-drivers) PURGE_DRIVERS=true ;;
        --yes) ASSUME_YES=true ;;
        *) break ;;
        esac
        shift
    done

    if [ "$EUID" -ne 0 ]; then
        print_error "uninstall requires root. Use: sudo bash main.sh uninstall [--purge-drivers] [--yes]"
        exit 1
    fi

    print_step "Uninstall: removing OpenVINO Runtime..."

    # Mandatory confirmation (skipped with --yes)
    if [ "$ASSUME_YES" != true ]; then
        read -r -p "This will remove /opt/intel/openvino_2026* (all 2026 installations). Continue? [y/n]: " response || {
            print_error "No input available. Uninstall cancelled."
            exit 1
        }
        case "$response" in
        [yY]*) ;;
        *)
            print_error "Uninstall cancelled by the user."
            exit 0
            ;;
        esac
    fi

    # Runtime: symlink OR real directory + any 2026 installation
    # (rm -rf does not follow symlinks — covers both cases)
    rm -rf /opt/intel/openvino_2026
    rm -rf /opt/intel/openvino_2026.*
    print_substep "OpenVINO Runtime removed (/opt/intel/openvino_2026*)"

    # NEO drivers (optional, best-effort with a warning)
    if [ "$PURGE_DRIVERS" = true ]; then
        print_substep "Purging NEO drivers (dpkg -r)..."
        if ! dpkg -r intel-opencl-icd intel-ocloc libigdgmm12 libze-intel-gpu1 intel-igc-core-2 intel-igc-opencl-2 2>/dev/null; then
            print_warning "Some NEO packages were not installed (on Fedora: dnf remove intel-compute-runtime)"
        fi
    fi

    print_substep "Uninstall completed."
}
