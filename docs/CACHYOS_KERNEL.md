# Running the CachyOS Performance Kernel on Fedora Linux

## Why CachyOS Kernel on the Dell Precision 5520?

The stock Fedora kernel is engineered for broad server and enterprise stability, using standard scheduling and conservative tick rates. 

By replacing the stock kernel with **CachyOS Linux Kernel** (`kernel-cachyos`), the Dell Precision 5520 gains:
1. **BORE (Burst-Oriented Response Enhancer) & EEVDF Scheduler**: Maximizes interactive desktop responsiveness and eliminates UI stutter under heavy compilation or rendering.
2. **High Tickrate (1000Hz) & Full Preemption (`PREEMPT_DYNAMIC` / `PREEMPT_FULL`)**: Drastically reduces audio latency in PipeWire and mouse input lag in gaming/Wayland.
3. **Optimized Compiler Flags (`-O3`, LTO, PGO)**: Better branch prediction and execution throughput on Intel Kaby Lake architecture.
4. **ZSTD Module Compression & Kernel Memory Tweaks**: Faster cold boot times and reduced kernel memory footprint.

---

## Installation on Fedora Linux

### 1. Enable CachyOS COPR Repositories
```bash
sudo dnf copr enable bieszczaders/kernel-cachyos
sudo dnf copr enable bieszczaders/kernel-cachyos-addons
```

### 2. Install Kernel & Headers
```bash
sudo dnf install kernel-cachyos kernel-cachyos-devel-matched kernel-cachyos-modules
```

### 3. Install Ananicy Auto-Nice Daemon
```bash
sudo dnf install ananicy-cpp cachyos-ananicy-rules
sudo systemctl enable --now ananicy-cpp
```

### 4. Build NVIDIA Kernel Module for CachyOS
Ensure the Akmod NVIDIA driver builds against the CachyOS kernel:
```bash
sudo akmods --kernels $(uname -r) --force
sudo dracut --regenerate-all --force
```

### 5. Reboot and Verify
```bash
uname -r
# Expected output: 7.x.x-cachyos1.fc44.x86_64
```
