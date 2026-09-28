# gpu-undervolt

Applies a tuned clock offset to an NVIDIA laptop GPU (RTX 4070 Laptop, HP Victus 16)
on a **Wayland-only** system, at boot, via a throwaway headless Xorg.

Tuned values here: **core +125 MHz, memory +250 MHz, no clock lock** — the GPU still
boosts freely, just on a raised V/F curve, so it reaches the same clocks at lower
voltage. `GPUPowerMizerMode=1` (prefer maximum performance) is set in the same pass.

## Why a headless Xorg is needed at all

`GPUGraphicsClockOffsetAllPerformanceLevels` / `GPUMemoryTransferRateOffsetAllPerformanceLevels`
are only reachable through `nvidia-settings` + Coolbits, i.e. NV-CONTROL on a real
Xorg with the NVIDIA DDX loaded. NVML has no public API for them, and XWayland doesn't
load the real NVIDIA driver, so it can't expose NV-CONTROL either. On a Wayland-only
machine there's no X server to talk to — so the script starts its own on a free VT,
applies the offsets, and tears it down.

It uses `Xorg -displayfd`, so Xorg picks a free display number and reports readiness
by writing it to a pipe — no sleep/poll loop, no fixed `:1` that might already be
taken. On exit (including failure or interrupt) it kills the server and restores the
original VT.

## Files

- `gpu-undervolt-apply` — the script (installed as `~/.local/bin/gpu-undervolt-apply`).
  Must run as root. Edit `CORE_OFFSET`/`MEM_OFFSET` at the top to retune.
- `gpu-undervolt-apply.initd` — OpenRC service (`/etc/init.d/gpu-undervolt-apply`).
  Belongs in the **boot** runlevel (`rc-update add gpu-undervolt-apply boot`), before
  any getty/login starts the Wayland session — the VT switch then happens while
  nothing is on screen yet.
- `20-nvidia.conf` — `/etc/X11/xorg.conf.d/20-nvidia.conf`, the Coolbits option the
  whole thing depends on. Without `Option "Coolbits" "28"` the `nvidia-settings`
  attributes silently don't exist. Needs `x11-base/xorg-server` installed even though
  the system is otherwise Wayland-only.

## Known limitation: both monitors blink on a manual run

Starting the second Xorg does a real VT switch, which pauses the *entire* Wayland
session — including outputs on the integrated GPU, not just the NVIDIA-attached one.
The ~1.5s of it is Xorg doing a real modeset and DisplayPort link-training on the
connected external monitor, even though only NV-CONTROL is wanted here.
`Option "UseDisplayDevice" "none"` + `AllowEmptyInitialConfiguration` did not avoid
it, most likely because `nvidia-drm.modeset=1` bypasses that legacy knob. Accepted
as-is: at boot the service runs before the session exists, so nothing is disrupted in
normal use — it only shows up when re-running by hand to test new values.

## Care when re-running by hand

Running this repeatedly in quick succession while a game is under heavy load has
caused a real `Xid 109: CTX SWITCH TIMEOUT` GPU fault, and once left an output stuck
disabled (`nvidia-modeset: Invalid request parameters`) until a reboot. Check the GPU
isn't under heavy load first, and that it has free VRAM (`nvidia-smi
--query-gpu=memory.free`) — a low-VRAM situation makes the headless Xorg fail
outright with "Failed to allocate primary buffer: out of memory". The script surfaces
that case with a hint pointing at `/tmp/xorg-undervolt-apply.log`.

## Related

The rest of this machine's power setup (EC turbo re-arm, fan daemon, AC/battery
switch, deep idle) lives in [power-scripts](https://github.com/tarilka0gg/power-scripts);
the BIOS-unlock and CPU undervolt research that preceded it is in
[system-lab](https://github.com/tarilka0gg/system-lab).
