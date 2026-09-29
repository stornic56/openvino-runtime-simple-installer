#!/bin/bash
# ------------------------------------------------------------------------------
# Minimalist pure-bash menu (zero external dependencies: ANSI + read -sn1).
# Navigation: up/down arrows + Enter, number keys as a shortcut, q/ESC exit.
# Returns: 0=exit, 1=full installation, 2=NEO only, 3=OpenVINO only,
#          4=doctor, 5=uninstall
# Requires: common.sh already sourced (print_*), no root needed to navigate.
# ------------------------------------------------------------------------------

MENU_OPTS=("Full installation" "NEO drivers only" "OpenVINO Runtime only" "Verify installation (doctor)" "Uninstall" "Exit")

show_menu() {
    local sel=0
    local n=${#MENU_OPTS[@]}
    local key rest i opt pad
    while true; do
        printf '\033[2J\033[H'
        echo ""
        echo "┌──────────────────────────────────────────────┐"
        echo "│      OpenVINO Simple Installer 2026.4        │"
        echo "└──────────────────────────────────────────────┘"
        echo ""
        i=0
        for opt in "${MENU_OPTS[@]}"; do
            pad=$(( 38 - ${#opt} ))
            if [ "$i" -eq "$sel" ]; then
                printf '│   \033[1;34m▸ %s. %s\033[0m%*s│\n' "$((i+1))" "$opt" "$pad" ""
            else
                printf '│     %s. %s%*s│\n' "$((i+1))" "$opt" "$pad" ""
            fi
            i=$((i+1))
        done
        echo "└──────────────────────────────────────────────┘"
        echo ""
        echo "  Arrows + Enter · number + Enter · q/ESC exit"
        if ! read -rsn1 key; then
            print_error "No input available."
            return 0
        fi
        if [ "$key" = $'\x1b' ]; then
            rest=""
            read -rsn2 -t 0.001 rest || true
            case "$rest" in
            '[A') sel=$(( (sel - 1 + n) % n )) ;;
            '[B') sel=$(( (sel + 1) % n )) ;;
            *) return 0 ;;   # ESC sin flecha: salir
            esac
        elif [ "$key" = "" ]; then
            # Enter: seleccionar la opcion marcada
            [ "$sel" -eq $((n-1)) ] && return 0
            return $((sel+1))
        elif [[ "$key" =~ ^[0-9]$ ]]; then
            # Atajo numerico: 1..5 seleccionan, 0 sale
            [ "$key" = "0" ] && return 0
            if [ "$key" -ge 1 ] && [ "$key" -le $((n-1)) ]; then
                return "$key"
            fi
        elif [ "$key" = "q" ]; then
            return 0
        fi
    done
}
