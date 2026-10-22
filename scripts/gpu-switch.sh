#!/usr/bin/env bash
# ==============================================================================
# GPU Switcher Helper for Dell Precision 5520 (Intel HD 630 + NVIDIA Quadro M1200)
# Powered by EnvyControl
# ==============================================================================

set -euo pipefail

usage() {
  echo "Usage: $0 {hybrid|integrated|nvidia|status}"
  echo ""
  echo "Commands:"
  echo "  hybrid      - Switch to Hybrid mode (Intel iGPU powers desktop, NVIDIA on-demand via PRIME)"
  echo "  integrated  - Switch to Integrated mode (NVIDIA dGPU completely powered off for maximum battery)"
  echo "  nvidia      - Switch to dedicated NVIDIA mode (All rendering on NVIDIA Quadro M1200)"
  echo "  status      - Display current GPU mode and active driver"
  exit 1
}

if [ $# -lt 1 ]; then
  usage
fi

case "$1" in
  hybrid)
    echo "==> Switching GPU to Hybrid mode..."
    sudo envycontrol -s hybrid
    echo "==> Please reboot your system to apply the new GPU configuration."
    ;;
  integrated|off)
    echo "==> Switching GPU to Integrated mode (powers down Quadro M1200)..."
    sudo envycontrol -s integrated
    echo "==> Please reboot your system to apply the new GPU configuration."
    ;;
  nvidia|on)
    echo "==> Switching GPU to dedicated NVIDIA mode..."
    sudo envycontrol -s nvidia
    echo "==> Please reboot your system to apply the new GPU configuration."
    ;;
  status)
    echo "==> Current EnvyControl GPU Mode:"
    envycontrol -q
    echo ""
    echo "==> Active Kernel Drivers:"
    lspci -nnk | grep -iA3 -E "vga|3d|display"
    ;;
  *)
    usage
    ;;
esac
