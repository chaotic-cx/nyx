#!/usr/bin/env bash
set -eu

for flavor in cachyos{-gcc,-hardened,-lto,-lts,-rc,-server}; do
  echo "Recreating $flavor"
  out="$(nix build ".#legacyPackages.x86_64-linux.linuxPackages_${flavor}.kernel.kconfigToNix" --no-link --print-out-paths)"
  [ -s "$out" ] && cat "$out" >"pkgs/linux-cachyos/config-nix/${flavor}.x86_64-linux.nix"
done
