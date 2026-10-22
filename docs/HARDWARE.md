# Dell Precision 5520 (Platform SKU 07BF) Hardware Architecture

## Overview
The **Dell Precision 5520** is an enterprise mobile workstation sharing the identical unibody chassis, dual-fan thermal assembly, and motherboard architecture with the popular **Dell XPS 15 9560**.

Under GNU/Linux, this machine delivers desktop-class performance when configured properly, but requires specific kernel, thermal, and hybrid graphics tuning to eliminate thermal throttling, latency spikes, and battery drain.

---

## Technical Specifications

| Component | Specification | Linux Subsystem & Driver |
| :--- | :--- | :--- |
| **Chassis / Platform** | Dell Precision 5520 (SKU `07BF`, Board `0NKT5P`) | `dell-laptop`, `dell-smm-hwmon`, `dell-rbtn` |
| **Firmware / BIOS** | Dell UEFI BIOS 1.40.0+ | `efivarfs`, `capsule_loader` |
| **Processor (CPU)** | Intel Core i7-7700HQ @ 2.80GHz (up to 3.80GHz Turbo, 4C/8T) | `intel_pstate`, `intel_rapl_msr` |
| **Integrated GPU (iGPU)** | Intel HD Graphics 630 (Kaby Lake-H GT2, Gen9.5) | `i915` (Mesa Iris / OpenGL 4.6 / Vulkan 1.3) |
| **Dedicated GPU (dGPU)** | NVIDIA Quadro M1200 Mobile (4GB GDDR5, Maxwell GM107GLM) | Proprietary `nvidia` 580xx (`nvidia_drm`, `nvidia_modeset`) |
| **System Memory** | 32 GB DDR4-2400 MT/s Dual-Channel | Non-ECC SODIMM |
| **Primary Storage** | 1TB NVMe M.2 Solid State Drive (`nvme0n1`) | Direct PCIe Gen3 x4 / NVMe driver (`scheduler=none`) |
| **Audio Subsystem** | Realtek ALC269 + Intel Display Audio | PipeWire + ALC269 Realtek codec driver |
| **Wireless / BT** | Intel Wireless-AC 8265 Dual-Band 2x2 | `iwlwifi`, `btintel` |
| **Battery Subsystem** | 97Wh / 56Wh 6-cell Lithium-Ion | ACPI battery interface with charge threshold support |

---

## Hardware Quirks & Solutions

### 1. Hybrid Graphics (NVIDIA Optimus / Dynamic Switch)
- **Problem**: Leaving the NVIDIA dGPU awake at all times draws 10W-15W additional power, generating heat and cutting battery life to ~2 hours.
- **Solution**: Use `envycontrol` to switch dynamically:
  - **Hybrid Mode**: Intel powers Wayland desktop; games and 3D CAD apps run on Quadro M1200 via `prime-run` or `__NV_PRIME_RENDER_OFFLOAD=1`.
  - **Integrated Mode**: Quadro M1200 is powered down at the PCIe root port level, yielding 6-8+ hours of battery life on a healthy battery.

### 2. Dual Fan Thermal Profile
- **Problem**: Dell's EC fan controller has conservative thresholds that ramp fans late, leading to thermal throttling on heavy multithreaded loads.
- **Solution**: Thermald (`thermald.service`) combined with `power-options-daemon` or `tuned` applies fine-grained CPU frequency caps and RAPL power package limits (45W sustained / 56W burst on AC, 35W/50W on battery).

### 3. Missing Font Glyphs on GTK4 / Wayland
- **Problem**: When running GNOME Shell / Mutter with NVIDIA modesetting on Wayland, font atlases occasionally fail to blit, causing invisible labels in GTK apps.
- **Solution**: Setting `COGL_ATLAS_DEFAULT_BLIT_MODE=framebuffer` in `/etc/environment` resolves the font atlas allocation bug.

### 4. Audio Pops & USB Mouse Latency
- **Problem**: Default aggressive Linux USB autosuspend puts USB audio interfaces and wireless dongles to sleep every 2 seconds, producing crackles and mouse wake lag.
- **Solution**: `usbcore.autosuspend=-1` in the kernel command line disables premature USB autosuspension.
