#!/bin/bash
# ------------------------------------------------------------------------------
# Common printing functions for all installer scripts.
# ------------------------------------------------------------------------------

print_step() { echo -e "\n\033[1;34m>>>\033[0m \033[1m$1\033[0m"; }
print_substep() { echo -e "\033[1;32m  =>\033[0m $1"; }
print_warning() { echo -e "\033[1;33m  [AVISO]\033[0m $1"; }
print_error() { echo -e "\033[1;31m  [ERROR]\033[0m $1"; }
