# Packaging

`packaging/package.sh` → `dist/gpu-undervolt-<version>.tar.gz` (+ `.sha256`). The offsets (core +125, memory +250) are tuned for one RTX 4070 Laptop; lower them for other cards. The packed init script calls `/usr/local/bin/gpu-undervolt-apply` instead of the original home-directory path. Enables nothing. No ebuild (by choice).

Install from the tarball: `./install.sh` (under `/usr/local`), `DESTDIR=… ./install.sh` to stage, `./install.sh uninstall` to remove
what it installed (it records a manifest). Existing files in `/etc` are never overwritten; the new copy is written as `<name>.new`.
Checked: install/uninstall in a DESTDIR. The script was not run.
