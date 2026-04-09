#!/usr/bin/env bash
# Generates a JSON map of package names to their derivation paths.
# Usage: ./scripts/scan.sh [target] [--system <system>]
# Default target: current flake
# Default system: x86_64-linux
# Output: JSON to stdout

set -euo pipefail

cd "$(dirname "$0")/.."

TARGET="."
SYSTEM="x86_64-linux"
NIX_FLAGS=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --system) SYSTEM="$2"; shift 2;;
    --impure) NIX_FLAGS="--impure"; export NIXPKGS_ALLOW_UNFREE=1; shift;;
    --) shift; break;;
    *) TARGET="$1"; shift;;
  esac
done

FILTER_EXPR='
  pkgs: builtins.mapAttrs (n: v:
    if v.type or null == "derivation"
    then v.drvPath
    else null
  ) pkgs
'

if [[ "${DEBUG:-}" == "1" ]]; then
  nix eval $NIX_FLAGS --json "${TARGET}#packages.${SYSTEM}" \
    --apply "$FILTER_EXPR"
else
  nix eval $NIX_FLAGS --json "${TARGET}#packages.${SYSTEM}" \
    --apply "$FILTER_EXPR" 2>/dev/null
fi | jq 'with_entries(select(.value != null))'
