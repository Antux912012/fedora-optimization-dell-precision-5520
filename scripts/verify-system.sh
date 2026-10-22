#!/usr/bin/env bash
# ==============================================================================
# System Verification & Telemetry Audit Script
# Validates active optimizations on Dell Precision 5520 / XPS 15 9560
# ==============================================================================

set -uo pipefail

BOLD="\033[1m"
GREEN="\033[32m"
YELLOW="\033[33m"
RED="\033[31m"
RESET="\033[0m"

pass() { echo -e "  [${GREEN}✓ PASS${RESET}] $1"; }
warn() { echo -e "  [${YELLOW}! WARN${RESET}] $1"; }
fail() { echo -e "  [${RED}✗ FAIL${RESET}] $1"; }

echo -e "${BOLD}======================================================================${RESET}"
echo -e "${BOLD}       Dell Precision 5520 Optimization Audit & Status Check          ${RESET}"
echo -e "${BOLD}======================================================================${RESET}"

# 1. Hardware & Model
echo -e "\n${BOLD}[1] Hardware Identification${RESET}"
MODEL=$(cat /sys/devices/virtual/dmi/id/product_name 2>/dev/null || echo "Unknown")
CPU=$(lscpu | grep "Model name:" | sed 's/Model name:[ \t]*//')
echo "  Hardware Model : ${MODEL}"
echo "  CPU            : ${CPU}"

# 2. Kernel & Scheduler
echo -e "\n${BOLD}[2] Kernel & CPU Scheduler${RESET}"
KERNEL=$(uname -r)
echo "  Running Kernel : ${KERNEL}"
if echo "${KERNEL}" | grep -qi "cachyos"; then
  pass "CachyOS performance kernel is running with BORE/EEVDF scheduler."
else
  warn "Running stock kernel (${KERNEL}). Consider installing kernel-cachyos for low-latency tuning."
fi

# 3. Ananicy Auto-Nice Daemon
echo -e "\n${BOLD}[3] Process Scheduling Daemon (ananicy-cpp)${RESET}"
if systemctl is-active --quiet ananicy-cpp; then
  pass "ananicy-cpp is active with CachyOS dynamic nice rules."
elif command -v ananicy-cpp >/dev/null; then
  warn "ananicy-cpp is installed but not active. Run: sudo systemctl enable --now ananicy-cpp"
else
  warn "ananicy-cpp is not installed."
fi

# 4. TCP Congestion Control & Network
echo -e "\n${BOLD}[4] Network Stack & TCP Congestion Control${RESET}"
CC=$(sysctl -n net.ipv4.tcp_congestion_control 2>/dev/null)
QDISC=$(sysctl -n net.core.default_qdisc 2>/dev/null)
TFO=$(sysctl -n net.ipv4.tcp_fastopen 2>/dev/null)

if [ "${CC}" = "bbr" ]; then
  pass "TCP Congestion Control is set to BBR (${CC})."
else
  fail "TCP Congestion Control is '${CC}', expected 'bbr'."
fi

if [ "${QDISC}" = "fq" ]; then
  pass "Default queueing discipline is set to FQ (${QDISC})."
else
  fail "Default qdisc is '${QDISC}', expected 'fq'."
fi

if [ "${TFO}" = "3" ]; then
  pass "TCP Fast Open is enabled for both client and server (${TFO})."
else
  warn "TCP Fast Open is set to '${TFO}'."
fi

# 5. NVMe I/O Scheduler
echo -e "\n${BOLD}[5] Storage I/O Scheduler (NVMe)${RESET}"
if [ -d /sys/block/nvme0n1/queue ]; then
  SCHED=$(cat /sys/block/nvme0n1/queue/scheduler 2>/dev/null)
  if echo "${SCHED}" | grep -q "\[none\]"; then
    pass "NVMe drive nvme0n1 uses direct hardware queueing: ${SCHED}"
  else
    warn "NVMe drive nvme0n1 scheduler is ${SCHED} (expected [none])."
  fi
else
  warn "No nvme0n1 block device found to check."
fi

# 6. NVIDIA GPU & Wayland KMS
echo -e "\n${BOLD}[6] NVIDIA GPU Modesetting & Wayland${RESET}"
if lsmod | grep -q "^nvidia_drm"; then
  pass "nvidia_drm module is loaded."
  MODESET=$(cat /sys/module/nvidia_drm/parameters/modeset 2>/dev/null || echo "N")
  FBDEV=$(cat /sys/module/nvidia_drm/parameters/fbdev 2>/dev/null || echo "N")
  if [ "${MODESET}" = "Y" ]; then
    pass "Direct Rendering Manager (DRM) KMS modesetting is active (modeset=Y)."
  else
    warn "DRM modeset is not enabled (modeset=${MODESET})."
  fi
  if [ "${FBDEV}" = "Y" ]; then
    pass "DRM framebuffer emulation is active (fbdev=Y)."
  fi
else
  warn "NVIDIA driver is either not loaded or running in pure integrated mode."
fi

if command -v envycontrol >/dev/null; then
  GPU_MODE=$(envycontrol -q 2>/dev/null || echo "Unknown")
  echo "  EnvyControl Mode: ${GPU_MODE}"
fi

# 7. Environment & Shader Cache
echo -e "\n${BOLD}[7] Graphics Environment Variables${RESET}"
SHADER_SIZE=$(grep -E "^__GL_SHADER_DISK_CACHE_SIZE=" /etc/environment 2>/dev/null | cut -d'=' -f2)
COGL_MODE=$(grep -E "^COGL_ATLAS_DEFAULT_BLIT_MODE=" /etc/environment 2>/dev/null | cut -d'=' -f2)

if [ "${SHADER_SIZE}" = "10000000000" ]; then
  pass "NVIDIA shader cache expanded to 10 GB (__GL_SHADER_DISK_CACHE_SIZE=10000000000)."
else
  warn "NVIDIA shader cache size is not set to 10GB in /etc/environment."
fi

if [ "${COGL_MODE}" = "framebuffer" ]; then
  pass "COGL atlas blit mode set to 'framebuffer' (fixes GTK missing glyphs)."
else
  warn "COGL_ATLAS_DEFAULT_BLIT_MODE not set to framebuffer."
fi

# 8. Btrfs Compression & Mounts
echo -e "\n${BOLD}[8] Btrfs Compression & Mount Flags${RESET}"
ROOT_MOUNT=$(findmnt -n -o OPTIONS / 2>/dev/null)
if echo "${ROOT_MOUNT}" | grep -q "compress=zstd"; then
  pass "Root filesystem mounted with transparent zstd compression."
else
  warn "Root filesystem does not use zstd compression: ${ROOT_MOUNT}"
fi
if echo "${ROOT_MOUNT}" | grep -q "noatime"; then
  pass "Root filesystem mounted with 'noatime' (minimizes redundant metadata writes)."
fi

# 9. Power Management & CPU EPP
echo -e "\n${BOLD}[9] CPU Power Management & ASPM${RESET}"
if [ -f /sys/devices/system/cpu/intel_pstate/no_turbo ]; then
  NO_TURBO=$(cat /sys/devices/system/cpu/intel_pstate/no_turbo)
  if [ "${NO_TURBO}" = "1" ]; then
    echo "  Intel Turbo Boost : DISABLED (Power Saver Mode active)"
  else
    echo "  Intel Turbo Boost : ENABLED (Performance Mode active)"
  fi
fi
if [ -f /sys/devices/system/cpu/cpu0/cpufreq/energy_performance_preference ]; then
  EPP=$(cat /sys/devices/system/cpu/cpu0/cpufreq/energy_performance_preference)
  echo "  CPU0 EPP Profile  : ${EPP}"
fi
if [ -f /sys/module/pcie_aspm/parameters/policy ]; then
  ASPM=$(cat /sys/module/pcie_aspm/parameters/policy)
  echo "  PCIe ASPM Policy  : ${ASPM}"
fi

echo -e "\n${BOLD}======================================================================${RESET}"
echo -e "${BOLD}                     Audit Scan Completed                             ${RESET}"
echo -e "${BOLD}======================================================================${RESET}"
