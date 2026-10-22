# 🚀 Fedora Linux Optimizations for Dell Precision 5520 / XPS 15 9560

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Fedora](https://img.shields.io/badge/Fedora_Linux-44-blue.svg?logo=fedora)](https://fedoraproject.org/)
[![Kernel](https://img.shields.io/badge/Kernel-CachyOS_BORE-orange.svg)](https://github.com/CachyOS/linux-cachyos)
[![Hardware](https://img.shields.io/badge/Dell_Platform-Precision_5520_%7C_XPS_9560-green.svg)](https://www.dell.com/)

A comprehensive, production-tested suite of performance, thermal, power efficiency, and hardware optimizations tailored specifically for the **Dell Precision 5520** (Platform SKU `07BF`, Motherboard `0NKT5P`) and **Dell XPS 15 9560** running **Fedora Linux** (compatible with modern GNOME & Wayland).

---

## 💻 Target Machine & Hardware Architecture

* **Model**: Dell Precision 5520 (Identical chassis, thermal layout, and logic board to Dell XPS 15 9560)
* **CPU**: Intel Core i7-7700HQ (4 Cores / 8 Threads, 2.80GHz base, up to 3.80GHz Turbo, Kaby Lake-H, 45W TDP)
* **RAM**: 32 GB DDR4 Dual-Channel
* **Graphics**:
  * **iGPU**: Intel HD Graphics 630 (Kaby Lake-H GT2, `i915`, Mesa Iris)
  * **dGPU**: NVIDIA Quadro M1200 Mobile (4GB GDDR5, Maxwell GM107GLM, Subsystem `1028:07bf`)
* **Storage**: 1TB NVMe Solid State Drive (`nvme0n1`)
* **Audio**: Realtek ALC269 + Intel Display Audio (PipeWire)
* **OS & Desktop**: Fedora Linux 44 (Workstation Edition), GNOME Shell on Wayland

---

## ⚡ Core Optimizations Overview

### 1. 🏎️ CachyOS Performance Kernel & BORE Scheduler
- **BORE (Burst-Oriented Response Enhancer) & EEVDF**: Prevents desktop stutters and input lag during heavy background compiling or I/O.
- **1000Hz Timer Tickrate & Full Preemption (`PREEMPT_DYNAMIC` / `PREEMPT_FULL`)**: Delivers ultra-low latency audio processing and responsive cursor dynamics.
- **`ananicy-cpp` Auto-Nice Daemon**: Dynamic rule-based process scheduling via `cachyos-ananicy-rules`.

### 2. 🎮 NVIDIA Hybrid Graphics, Wayland KMS & Shader Cache
- **Direct Rendering Manager (DRM) KMS Modeset**: `nvidia_drm modeset=1 fbdev=1` enables seamless GDM login and native Wayland session support.
- **Memory Bandwidth & PAT**: `NVreg_UsePageAttributeTable=1` and `NVreg_InitializeSystemMemoryAllocations=0` maximize PCIe memory transfer bandwidth and reduce allocation stalls.
- **GDM Wayland Unmask**: Unmasks GDM Wayland rule (`/etc/udev/rules.d/61-gdm.rules -> /dev/null`) to ensure Wayland sessions stay active.
- **10 GB Shader Disk Cache**: `__GL_SHADER_DISK_CACHE_SIZE=10000000000` prevents shader compilation micro-stutters in Steam, Proton, and OpenGL/Vulkan workloads.
- **GTK4 / Mutter Font Glyph Fix**: `COGL_ATLAS_DEFAULT_BLIT_MODE=framebuffer` fixes invisible font rendering artifacts under Wayland.
- **EnvyControl Integration**: Effortless GPU switching between `hybrid` (PRIME on-demand) and `integrated` (dGPU completely powered down for 6-8+ hours battery).

### 3. 🌐 High-Performance BBR + Fair Queueing Network Stack
In `/etc/sysctl.d/99-network-performance.conf`:
- **TCP BBR + FQ**: `net.ipv4.tcp_congestion_control = bbr` and `net.core.default_qdisc = fq` maximize gigabit Wi-Fi and Ethernet throughput while keeping bufferbloat low.
- **TCP Fast Open (TFO)**: `net.ipv4.tcp_fastopen = 3` accelerates TLS handshakes and page loading.
- **16MB Window Buffers**: Expanded buffer ceilings (`rmem_max`, `wmem_max`, `tcp_rmem`, `tcp_wmem`) eliminate transfer bottlenecks.
- **Socket Timeouts**: Shortened `tcp_fin_timeout = 15` and enabled `tcp_tw_reuse = 1` prevent connection starvation.

### 4. 💽 Storage & Filesystem Tuning
- **NVMe Direct Queueing**: `/etc/udev/rules.d/60-nvme-scheduler.rules` forces `none` I/O scheduler on NVMe drives to bypass CPU queueing overhead and maximize IOPS.
- **Btrfs Transparent Compression**: Root and Home subvolumes mounted with `compress=zstd:1,noatime` for higher effective disk throughput, reduced flash wear, and fast metadata traversal.
- **Automated Discard**: `fstrim.timer` enabled for periodic SSD trim maintenance.
- **ZRAM Compressed In-RAM Swap**: `systemd-zram-generator` with 8 GB compressed swap partition.

### 5. 🔋 Power Management, Thermals & Battery Health
- **Dual-Profile Power Daemon**: Integrated with `power-options-daemon`:
  - **AC (Performance)**: 3.80GHz max boost, CPU Turbo on, PCIe ASPM performance, 45W sustained / 56W burst package power.
  - **Battery (Powersave)**: Turbo disabled, ASPM deep powersaving, CPU EPP `balance_power`, 35W/50W package power limit.
- **Passwordless Sysfs Power Udev Rules**: `/etc/udev/rules.d/99-mithrandir-power.rules` allows members of the `wheel` group to toggle Intel P-State Turbo Boost, CPU EPP, and PCIe ASPM dynamically without root prompts.
- **Battery Health Charging**: Script `/usr/local/bin/batteryhealthchargingctl` paired with the GNOME extension to cap charging at 80%, preserving battery chemistry longevity.

### 6. 🛠️ Low-Latency Kernel Boot Parameters (GRUB)
Configured in `/etc/default/grub` (`GRUB_CMDLINE_LINUX`):
- `rd.driver.blacklist=nouveau,nova_core modprobe.blacklist=nouveau,nova_core`: Ensures clean NVIDIA driver initialization without driver collisions.
- `split_lock_detect=off`: Prevents catastrophic CPU throttling caused by split locks in games and multithreaded apps.
- `nowatchdog nmi_watchdog=0`: Disables NMI hardware watchdogs, eliminating interrupt spikes and saving power.
- `pci=pcie_bus_perf`: Forces PCIe maximum bus throughput.
- `usbcore.autosuspend=-1`: Fixes audio dropouts on external USB DACs and wireless mouse lag.
- `page_alloc.shuffle=1`: Randomizes memory allocations for enhanced bus bandwidth and cache security.

### 7. 🎵 Low-Latency Audio & Real-time Priority
- **PipeWire Real-Time Limits**: `/etc/security/limits.d/25-pw-rlimits.conf` grants `@pipewire` group `rtprio 70`, `nice -19`, and 4GB memory locking.
- **GameMode**: `/etc/security/limits.d/10-gamemode.conf` grants `@gamemode` priority `nice -10`.

---

## 📂 Repository Structure

```
├── install.sh                         # Automated installer with rollback backup
├── uninstall.sh                       # Safe uninstallation script
├── LICENSE                            # MIT License
├── README.md                          # Documentation & architecture guide
├── configs/
│   ├── sysctl/
│   │   └── 99-network-performance.conf   # BBR + FQ TCP sysctl rules
│   ├── udev/
│   │   ├── 60-nvme-scheduler.rules       # NVMe direct hardware queueing rule
│   │   └── 99-mithrandir-power.rules     # Passwordless power management rule
│   ├── modprobe/
│   │   ├── nvidia.conf                   # NVIDIA PAT and memory optimizations
│   │   └── nvidia-drm-modeset.conf       # DRM KMS and fbdev flags
│   ├── environment/
│   │   └── environment                   # 10GB shader cache & COGL blit fix
│   ├── security/
│   │   ├── 10-gamemode.conf              # GameMode scheduling limits
│   │   └── 25-pw-rlimits.conf            # PipeWire real-time limits
│   ├── power-options/
│   │   ├── config.toml                   # Power-Options daemon config
│   │   ├── Performance.toml              # AC performance profile
│   │   └── Powersave.toml                # Battery powersave profile
│   └── grub/
│       └── grub.cmdline                  # Recommended GRUB command line
├── scripts/
│   ├── batteryhealthchargingctl          # Battery charge threshold control script
│   ├── gpu-switch.sh                     # EnvyControl GPU mode helper
│   └── verify-system.sh                  # System verification and telemetry audit
└── docs/
    ├── HARDWARE.md                       # Precision 5520 / XPS 15 9560 hardware breakdown
    └── CACHYOS_KERNEL.md                 # CachyOS kernel setup guide for Fedora
```

---

## 🚀 Quick Start & Installation

### 1. Clone the Repository
```bash
git clone https://github.com/Antux912012/fedora-optimization-dell-precision-5520.git
cd fedora-optimization-dell-precision-5520
```

### 2. Run the Automated Installer
```bash
sudo ./install.sh
```
*(All existing configuration files are automatically backed up to `/etc/dell-precision-5520-backup/` prior to modification).*

### 3. Update GRUB Bootloader
Edit `/etc/default/grub` and append the following to `GRUB_CMDLINE_LINUX`:
```text
rd.driver.blacklist=nouveau,nova_core modprobe.blacklist=nouveau,nova_core split_lock_detect=off nowatchdog nmi_watchdog=0 pci=pcie_bus_perf usbcore.autosuspend=-1 page_alloc.shuffle=1
```
Regenerate GRUB:
```bash
sudo grub2-mkconfig -o /boot/grub2/grub.cfg
```

### 4. Install the CachyOS Kernel (Optional but Recommended)
Refer to [`docs/CACHYOS_KERNEL.md`](docs/CACHYOS_KERNEL.md) for full instructions:
```bash
sudo dnf copr enable bieszczaders/kernel-cachyos
sudo dnf copr enable bieszczaders/kernel-cachyos-addons
sudo dnf install kernel-cachyos kernel-cachyos-devel-matched ananicy-cpp cachyos-ananicy-rules
sudo systemctl enable --now ananicy-cpp
```

### 5. Reboot and Verify
```bash
sudo reboot
```
After logging back in, run the built-in telemetry verification tool:
```bash
./scripts/verify-system.sh
```

---

## 🎮 Useful Commands & Shortcuts

```bash
# Check current GPU mode
./scripts/gpu-switch.sh status

# Switch to Hybrid graphics (Intel desktop + NVIDIA PRIME on-demand)
./scripts/gpu-switch.sh hybrid

# Switch to Integrated graphics (Powers off NVIDIA dGPU for maximum battery)
./scripts/gpu-switch.sh integrated

# Audit active system optimizations
./scripts/verify-system.sh
```

---

## 🧹 Uninstallation

To restore stock configuration files and remove installed udev/sysctl rules:
```bash
sudo ./uninstall.sh
```

---

## 📜 License
This project is licensed under the [MIT License](LICENSE).
