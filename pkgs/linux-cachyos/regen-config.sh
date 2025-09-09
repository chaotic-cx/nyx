#!/usr/bin/env bash
set -eu

for flavor in cachyos{,-lto,-server,-lts,-rc,-hardened}; do
  cat "$(nix build ".#legacyPackages.x86_64-linux.linuxPackages_${flavor}.kernel.kconfigToNix" --no-link --print-out-paths)" \
    >"pkgs/linux-cachyos/config-nix/${flavor}.x86_64-linux.nix"
done
