#!/bin/bash
# ------------------------------------------------------------------------------
# Common printing functions for all installer scripts.
# Dual output: colores ANSI a stdout + texto plano (sin codigos) a $LOG_FILE.
# El log es AUXILIAR: su fallo de escritura no debe abortar la operacion
# (p. ej. log root-owned + doctor sin root) — por eso el append va guardado.
# ------------------------------------------------------------------------------

LOG_FILE="${LOG_FILE:-install.log}"

_log_plain() { printf '%s\n' "$1" >> "$LOG_FILE" 2>/dev/null || true; }

print_step()    { echo -e "\n\033[1;34m>>>\033[0m \033[1m$1\033[0m"; _log_plain "";    _log_plain ">>> $1"; }
print_substep() { echo -e "\033[1;32m  =>\033[0m $1";                 _log_plain "  => $1"; }
print_warning() { echo -e "\033[1;33m  [WARNING]\033[0m $1";            _log_plain "  [WARNING] $1"; }
print_error()   { echo -e "\033[1;31m  [ERROR]\033[0m $1";            _log_plain "  [ERROR] $1"; }
