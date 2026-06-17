#!/usr/bin/env bash
set -xeuo pipefail

NYX_FLAKE=${NYX_FLAKE:-$PWD}
NYX_TARGET=${NYX_TARGET:-kernel}

test -s "$NYX_FLAKE/flake.nix"

NYX_WD="${NYX_WD:-$(mktemp -d)}"
cd "$NYX_WD"
echo "Working at $NYX_WD"

CACHY_VERSION=${CACHY_VERSION:-7.0.11-1}
CACHY_URL="https://mirror.cachyos.org/repo/x86_64${CACHY_REPO_SUFFIX:-}/cachyos/linux-cachyos${CACHY_FILE_SUFFIX:--$CACHY_VERSION-x86_64}.pkg.tar.zst"

[ -e ./linux-cachy.pkg.tar.zst ] || curl -o linux-cachy.pkg.tar.zst "$CACHY_URL"

[ -e ./linux-cachy/.PKGINFO ] || (mkdir -p linux-cachy && cd linux-cachy && tar --zstd -xf ../linux-cachy.pkg.tar.zst)

if [ "$NYX_TARGET" = 'kernel' ]; then
  nix build --out-link ./linux-nyx "$NYX_FLAKE#${NYX_PKG:-linux_cachyos-lto}"
elif [ "$NYX_TARGET" = 'configfile' ]; then
  nix build --out-link ./linux-nyx.kconfig "$NYX_FLAKE#${NYX_PKG:-linux_cachyos-lto}.passthru.configfile"
else
  echo 'Unsupported NYX_TARGET' >&2
  exit 1
fi

[ -n "$(find ./linux-nyx-src -mindepth 2 -maxdepth 2 -name Makefile -print -quit)" ] || (
  mkdir -p linux-nyx-src &&
    cd linux-nyx-src &&
    tar -xzf "$(nix build --no-link --print-out-paths "$NYX_FLAKE#${NYX_PKG:-linux_cachyos}.src" | head -n 1)"
)

EXTRACTOR=$(echo ./linux-nyx-src/*/scripts/extract-ikconfig)

test -e "$EXTRACTOR"

CACHY_VMLINUZ="./linux-cachy/usr/lib/modules/${CACHY_MODDIR:-$CACHY_VERSION-cachyos}/vmlinuz"
NYX_VMLINUZ="./linux-nyx/bzImage"

"$EXTRACTOR" "$CACHY_VMLINUZ" | sort -u >cachy-config.txt

if [ "$NYX_TARGET" = 'kernel' ]; then
  "$EXTRACTOR" "$NYX_VMLINUZ" | sort -u >nyx-config.txt
else
  sort -u linux-nyx.kconfig >nyx-config.txt
fi

echo 'Done, diff:'

diff -u cachy-config.txt nyx-config.txt
