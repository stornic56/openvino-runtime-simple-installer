#!/bin/bash
# ------------------------------------------------------------------------------
# doctor: verificacion post-instalacion (sin root requerido).
# Sourced por main.sh (subcomando doctor) y por el menu.
# Salida con print_* de common.sh; exit code = numero de checks con fallo.
# ------------------------------------------------------------------------------

run_doctor_checks() {
    print_step "Doctor: verificando la instalacion de OpenVINO..."
    local fails=0

    # 1. Symlink estable
    if [ -L /opt/intel/openvino_2026 ]; then
        print_substep "Symlink OK: /opt/intel/openvino_2026 -> $(readlink /opt/intel/openvino_2026)"
    else
        print_error "Falta el symlink /opt/intel/openvino_2026 (¿la instalacion no se realizo?)"
        fails=$((fails+1))
    fi

    # 2. Version instalada
    if [ -f /opt/intel/openvino_2026/runtime/version.txt ]; then
        print_substep "Version instalada: $(cat /opt/intel/openvino_2026/runtime/version.txt)"
    else
        print_error "No se encontro runtime/version.txt"
        fails=$((fails+1))
    fi

    # 3. OpenCL (clinfo)
    if command -v clinfo >/dev/null 2>&1; then
        CLINFO_OUT=$(clinfo 2>/dev/null || true)   # clinfo exits !=0 when no devices
        if [[ "${CLINFO_OUT^^}" == *"DEVICE NAME"* ]]; then
            print_substep "OpenCL OK (dispositivo detectado)"
        else
            print_warning "clinfo no detecta dispositivo (¿falta el driver NEO o los grupos render/video?)"
            fails=$((fails+1))
        fi
    else
        print_warning "clinfo no esta instalado"
        fails=$((fails+1))
    fi

    # 4. VAAPI (vainfo)
    if command -v vainfo >/dev/null 2>&1; then
        VAINFO_OUT=$(vainfo 2>/dev/null || true)
        if [[ "${VAINFO_OUT^^}" == *"DRIVER VERSION"* ]]; then
            print_substep "VAAPI OK (driver cargado)"
        else
            print_warning "vainfo no carga driver (¿falta intel-media-va-driver?)"
            fails=$((fails+1))
        fi
    else
        print_warning "vainfo no esta instalado"
        fails=$((fails+1))
    fi

    # 5. Grupos render/video
    if id -Gn 2>/dev/null | grep -qw render && id -Gn 2>/dev/null | grep -qw video; then
        print_substep "Grupos OK: el usuario esta en render y video"
    else
        print_warning "El usuario NO esta en los grupos render/video (reinicia la sesion tras instalar)"
        fails=$((fails+1))
    fi

    if [ "$fails" -eq 0 ]; then
        print_substep "Doctor: TODO OK"
    else
        print_warning "Doctor: $fails check(s) con avisos o fallos"
    fi
    return "$fails"
}
