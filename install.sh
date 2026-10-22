#!/usr/bin/env bash
# ==============================================================================
# Installer: Dell Precision 5520 / XPS 15 9560 Linux Optimizations
# ==============================================================================

set -euo pipefail

BOLD="\033[1m"
GREEN="\033[32m"
YELLOW="\033[33m"
CYAN="\033[36m"
RESET="\033[0m"

BACKUP_DIR="/etc/dell-precision-5520-backup/$(date +%Y%m%d_%H%M%S)"

if [ "$EUID" -ne 0 ]; then
  echo -e "${YELLOW}Please run this installer with root privileges:${RESET}"
  echo "  sudo ./install.sh"
  exit 1
fi

echo -e "${BOLD}${CYAN}======================================================================${RESET}"
echo -e "${BOLD}${CYAN}      Dell Precision 5520 / XPS 15 9560 Linux Optimization Suite      ${RESET}"
echo -e "${BOLD}${CYAN}======================================================================${RESET}"

mkdir -p "${BACKUP_DIR}"
echo -e "==> Created backup directory at ${BOLD}${BACKUP_DIR}${RESET}"

backup_and_copy() {
  local src="$1"
  local dest="$2"

  if [ -f "${dest}" ]; then
    mkdir -p "${BACKUP_DIR}/$(dirname "${dest}")"
    cp -L "${dest}" "${BACKUP_DIR}/${dest}"
    echo "    Backed up: ${dest}"
  fi
  mkdir -p "$(dirname "${dest}")"
  cp "${src}" "${dest}"
  echo -e "    ${GREEN}Installed:${RESET} ${dest}"
}

# 1. Sysctl Network & TCP Tuning
echo -e "\n${BOLD}[1] Applying Sysctl (BBR + Fair Queueing + Buffer limits)...${RESET}"
backup_and_copy "configs/sysctl/99-network-performance.conf" "/etc/sysctl.d/99-network-performance.conf"
sysctl --system >/dev/null 2>&1 || true

# 2. Udev Rules (NVMe Scheduler, GDM Wayland Unmask, Power Rules)
echo -e "\n${BOLD}[2] Installing Udev Rules...${RESET}"
backup_and_copy "configs/udev/60-nvme-scheduler.rules" "/etc/udev/rules.d/60-nvme-scheduler.rules"
backup_and_copy "configs/udev/99-mithrandir-power.rules" "/etc/udev/rules.d/99-mithrandir-power.rules"

# Unmask GDM Wayland for NVIDIA
if [ ! -L "/etc/udev/rules.d/61-gdm.rules" ]; then
  ln -sf /dev/null /etc/udev/rules.d/61-gdm.rules
  echo -e "    ${GREEN}Unmasked:${RESET} GDM Wayland for NVIDIA (/etc/udev/rules.d/61-gdm.rules -> /dev/null)"
fi

udevadm control --reload-rules || true
udevadm trigger || true

# 3. Modprobe NVIDIA Configuration
echo -e "\n${BOLD}[3] Configuring NVIDIA Kernel Module Options...${RESET}"
backup_and_copy "configs/modprobe/nvidia.conf" "/etc/modprobe.d/nvidia.conf"
backup_and_copy "configs/modprobe/nvidia-drm-modeset.conf" "/etc/modprobe.d/nvidia-drm-modeset.conf"

# 4. Environment Variables
echo -e "\n${BOLD}[4] Setting Environment Variables (Shader Cache & GTK Blit Fix)...${RESET}"
if [ -f "/etc/environment" ]; then
  mkdir -p "${BACKUP_DIR}/etc"
  cp "/etc/environment" "${BACKUP_DIR}/etc/environment"
fi

touch /etc/environment
if ! grep -q "__GL_SHADER_DISK_CACHE_SIZE" /etc/environment; then
  echo "" >> /etc/environment
  echo "# increase Nvidia shader cache size to 10GB" >> /etc/environment
  echo "__GL_SHADER_DISK_CACHE_SIZE=10000000000" >> /etc/environment
fi
if ! grep -q "COGL_ATLAS_DEFAULT_BLIT_MODE" /etc/environment; then
  echo "# missing glyph in GTK / Mutter fix" >> /etc/environment
  echo "COGL_ATLAS_DEFAULT_BLIT_MODE=framebuffer" >> /etc/environment
fi
echo -e "    ${GREEN}Configured:${RESET} /etc/environment"

# 5. Security & PipeWire Limits
echo -e "\n${BOLD}[5] Configuring Realtime Audio (PipeWire) & GameMode Limits...${RESET}"
backup_and_copy "configs/security/10-gamemode.conf" "/etc/security/limits.d/10-gamemode.conf"
backup_and_copy "configs/security/25-pw-rlimits.conf" "/etc/security/limits.d/25-pw-rlimits.conf"

# 6. Battery Health Charging Controller
echo -e "\n${BOLD}[6] Installing Battery Health Charging Utility...${RESET}"
backup_and_copy "scripts/batteryhealthchargingctl" "/usr/local/bin/batteryhealthchargingctl"
chmod +x /usr/local/bin/batteryhealthchargingctl

# 7. Power Options Profiles
if [ -d "/etc/power-options" ]; then
  echo -e "\n${BOLD}[7] Updating Power-Options Profiles...${RESET}"
  mkdir -p /etc/power-options/profiles
  backup_and_copy "configs/power-options/config.toml" "/etc/power-options/config.toml"
  backup_and_copy "configs/power-options/Performance.toml" "/etc/power-options/profiles/Performance.toml"
  backup_and_copy "configs/power-options/Powersave.toml" "/etc/power-options/profiles/Powersave.toml"
fi

# 8. Instructions for GRUB
echo -e "\n${BOLD}${CYAN}======================================================================${RESET}"
echo -e "${BOLD}${GREEN}                   Installation Finished Successfully!                ${RESET}"
echo -e "${BOLD}${CYAN}======================================================================${RESET}"
echo ""
echo -e "Next steps to complete bootloader optimization:"
echo -e "1. Edit ${BOLD}/etc/default/grub${RESET} and append these parameters to ${BOLD}GRUB_CMDLINE_LINUX${RESET}:"
echo -e "   ${CYAN}rd.driver.blacklist=nouveau,nova_core modprobe.blacklist=nouveau,nova_core split_lock_detect=off nowatchdog nmi_watchdog=0 pci=pcie_bus_perf usbcore.autosuspend=-1 page_alloc.shuffle=1${RESET}"
echo ""
echo -e "2. Regenerate your GRUB configuration:"
echo -e "   ${BOLD}sudo grub2-mkconfig -o /boot/grub2/grub.cfg${RESET}"
echo ""
echo -e "3. Run the verification script:"
echo -e "   ${BOLD}./scripts/verify-system.sh${RESET}"
echo ""
