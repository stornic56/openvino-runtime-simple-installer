#!/bin/bash
# ------------------------------------------------------------------------------
# doctor: post-installation verification (no root required).
# Sourced by main.sh (doctor subcommand) and by the menu.
# Output with print_* from common.sh; exit code = number of failed checks.
# ------------------------------------------------------------------------------

run_doctor_checks() {
    print_step "Doctor: verifying OpenVINO installation..."
    local fails=0

    # 1. Stable symlink
    if [ -L /opt/intel/openvino_2026 ]; then
        print_substep "Symlink OK: /opt/intel/openvino_2026 -> $(readlink /opt/intel/openvino_2026)"
    else
        print_error "Missing symlink /opt/intel/openvino_2026 (was the installation performed?)"
        fails=$((fails+1))
    fi

    # 2. Installed version
    if [ -f /opt/intel/openvino_2026/runtime/version.txt ]; then
        print_substep "Installed version: $(cat /opt/intel/openvino_2026/runtime/version.txt)"
    else
        print_error "runtime/version.txt not found"
        fails=$((fails+1))
    fi

    # 3. OpenCL (clinfo) — capture first (clinfo output is large; grep -q would
    # SIGPIPE-kill the pipe and report a false negative under pipefail)
    if command -v clinfo >/dev/null 2>&1; then
        CLINFO_OUT=$(clinfo 2>/dev/null || true)   # clinfo exits !=0 when no devices
        if [[ "${CLINFO_OUT^^}" == *"DEVICE NAME"* ]]; then
            print_substep "OpenCL OK (device detected)"
        else
            print_warning "clinfo does not detect a device (missing NEO driver or render/video groups?)"
            fails=$((fails+1))
        fi
    else
        print_warning "clinfo is not installed"
        fails=$((fails+1))
    fi

    # 4. VAAPI (vainfo) — same capture-first pattern (consistency + latent SIGPIPE)
    if command -v vainfo >/dev/null 2>&1; then
        VAINFO_OUT=$(vainfo 2>/dev/null || true)
        if [[ "${VAINFO_OUT^^}" == *"DRIVER VERSION"* ]]; then
            print_substep "VAAPI OK (driver loaded)"
        else
            print_warning "vainfo does not load a driver (missing intel-media-va-driver?)"
            fails=$((fails+1))
        fi
    else
        print_warning "vainfo is not installed"
        fails=$((fails+1))
    fi

    # 5. render/video groups
    if id -Gn 2>/dev/null | grep -qw render && id -Gn 2>/dev/null | grep -qw video; then
        print_substep "Groups OK: user is in render and video"
    else
        print_warning "User is NOT in the render/video groups (restart your session after installing)"
        fails=$((fails+1))
    fi

    if [ "$fails" -eq 0 ]; then
        print_substep "Doctor: ALL OK"
    else
        print_warning "Doctor: $fails check(s) with warnings or failures"
    fi
    return "$fails"
}
