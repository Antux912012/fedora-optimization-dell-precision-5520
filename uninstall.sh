#!/usr/bin/env bash
# ==============================================================================
# Uninstaller: Dell Precision 5520 / XPS 15 9560 Linux Optimizations
# ==============================================================================

set -euo pipefail

BOLD="\033[1m"
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
RESET="\033[0m"

if [ "$EUID" -ne 0 ]; then
  echo -e "${YELLOW}Please run this uninstaller with root privileges:${RESET}"
  echo "  sudo ./uninstall.sh"
  exit 1
fi

echo -e "${BOLD}${RED}Removing Dell Precision 5520 custom optimizations...${RESET}"

rm -f /etc/sysctl.d/99-network-performance.conf
rm -f /etc/udev/rules.d/60-nvme-scheduler.rules
rm -f /etc/udev/rules.d/99-mithrandir-power.rules
rm -f /etc/udev/rules.d/61-gdm.rules
rm -f /etc/modprobe.d/nvidia.conf
rm -f /etc/modprobe.d/nvidia-drm-modeset.conf
rm -f /etc/security/limits.d/10-gamemode.conf
rm -f /etc/security/limits.d/25-pw-rlimits.conf
rm -f /usr/local/bin/batteryhealthchargingctl

# Clean up /etc/environment entries
if [ -f "/etc/environment" ]; then
  sed -i '/__GL_SHADER_DISK_CACHE_SIZE=10000000000/d' /etc/environment
  sed -i '/COGL_ATLAS_DEFAULT_BLIT_MODE=framebuffer/d' /etc/environment
fi

sysctl --system >/dev/null 2>&1 || true
udevadm control --reload-rules || true
udevadm trigger || true

echo -e "${BOLD}${GREEN}Optimizations removed cleanly. (Backup configs remain in /etc/dell-precision-5520-backup/)${RESET}"
