#!/bin/bash
# ------------------------------------------------------------------------------
# uninstall: desinstala OpenVINO Runtime (y opcionalmente los drivers NEO).
# Sourced por main.sh (subcomando uninstall). Requiere root para operar.
# Argumentos: --purge-drivers (dpkg -r de los 6 paquetes NEO), --yes (sin prompt).
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
        print_error "uninstall requiere root. Usa: sudo bash main.sh uninstall [--purge-drivers] [--yes]"
        exit 1
    fi

    print_step "Uninstall: desinstalando OpenVINO Runtime..."

    # Confirmacion obligatoria (con --yes se omite)
    if [ "$ASSUME_YES" != true ]; then
        read -r -p "Esto eliminara /opt/intel/openvino_2026* (todas las instalaciones 2026). ¿Continuar? [y/n]: " response || {
            print_error "Sin entrada disponible. Desinstalacion cancelada."
            exit 1
        }
        case "$response" in
        [yY]*) ;;
        *)
            print_error "Desinstalacion cancelada por el usuario."
            exit 0
            ;;
        esac
    fi

    # Runtime: symlink O directorio real + cualquier instalacion 2026
    # (rm -rf no sigue symlinks — cubre ambos casos)
    rm -rf /opt/intel/openvino_2026
    rm -rf /opt/intel/openvino_2026.*
    print_substep "OpenVINO Runtime eliminado (/opt/intel/openvino_2026*)"

    # Drivers NEO (opcional, best-effort con aviso)
    if [ "$PURGE_DRIVERS" = true ]; then
        print_substep "Purgando drivers NEO (dpkg -r)..."
        if ! dpkg -r intel-opencl-icd intel-ocloc libigdgmm12 libze-intel-gpu1 intel-igc-core-2 intel-igc-opencl-2 2>/dev/null; then
            print_warning "Algunos paquetes NEO no estaban instalados (en Fedora: dnf remove intel-compute-runtime)"
        fi
    fi

    print_substep "Desinstalacion completada."
}
