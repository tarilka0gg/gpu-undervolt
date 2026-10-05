#!/bin/bash
# package.sh - pack gpu-undervolt: dist/gpu-undervolt-<version>.tar.gz (+ .sha256).
# A shell script, an OpenRC service and the Xorg Coolbits snippet; no build step. The repo's init script calls
# the script from one user's ~/.local/bin; the packed copy points at /usr/local/bin, where install.sh puts it.
# Nothing is enabled, and the offsets are tuned for an RTX 4070 Laptop: see POST-INSTALL.txt.
set -euo pipefail
cd "$(dirname "$0")/.."
NAME=gpu-undervolt
VERSION=${VERSION:-0.1.0+git$(git rev-parse --short HEAD 2>/dev/null || echo local)}
D=dist/$NAME-$VERSION
rm -rf "${D:?}"

install -Dm755 gpu-undervolt-apply -t "$D/prefix/bin"
install -Dm755 /dev/stdin "$D/etc/init.d/gpu-undervolt-apply" < <(sed 's#^\t/home/[^ ]*/gpu-undervolt-apply$#\t/usr/local/bin/gpu-undervolt-apply#' gpu-undervolt-apply.initd)
grep -q '/usr/local/bin/gpu-undervolt-apply' "$D/etc/init.d/gpu-undervolt-apply" || { echo "package.sh: the init script's path was not rewritten" >&2; exit 1; }
! grep -q '/home/' "$D/etc/init.d/gpu-undervolt-apply" || { echo "package.sh: a /home path is left in the init script" >&2; exit 1; }
install -Dm644 20-nvidia.conf "$D/etc/X11/xorg.conf.d/20-nvidia.conf"
install -Dm644 README.md -t "$D/prefix/share/doc/$NAME"
echo /usr/local > "$D/REQUIRE_PREFIX"
install -m755 packaging/install.sh "$D/install.sh"
cat > "$D/POST-INSTALL.txt" <<'TXT'
Nothing is enabled. The offsets in /usr/local/bin/gpu-undervolt-apply (core +125 MHz, memory +250 MHz) were tuned for
one RTX 4070 Laptop GPU; other cards can crash with them. Lower CORE_OFFSET/MEM_OFFSET at the top of the script first.
Needs x11-base/xorg-server and nvidia-settings. Then:
  rc-update add gpu-undervolt-apply boot
Read the README's "Care when re-running by hand" before running it manually.
TXT

OUT=dist/$NAME-$VERSION.tar.gz
tar -C dist --owner=0 --group=0 -czf "$OUT" "$NAME-$VERSION"
(cd dist && sha256sum "$(basename "$OUT")" > "$(basename "$OUT").sha256")
echo "$OUT"
