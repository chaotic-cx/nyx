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
  pkgs: let
    flatten = prefix: attrs: builtins.foldl'"'"' (
      acc: name: let
        r = builtins.tryEval (builtins.getAttr name attrs);
      in
        if !r.success then acc else
        let v = r.value; in
        if !builtins.isAttrs v then acc else
        let key = if prefix == "" then name else "${prefix}.${name}"; in
        if v.type or "" == "derivation" then
          let d = builtins.tryEval v.drvPath; in
          if d.success then acc // { ${key} = d.value; } else acc
        else if v.recurseForDerivations or false then
          acc // flatten key v
        else
          acc
    ) {} (builtins.attrNames attrs);
  in flatten "" pkgs
'

if [[ "${DEBUG:-}" == "1" ]]; then
  nix eval $NIX_FLAGS --json "${TARGET}#legacyPackages.${SYSTEM}" \
    --apply "$FILTER_EXPR"
else
  nix eval $NIX_FLAGS --json "${TARGET}#legacyPackages.${SYSTEM}" \
    --apply "$FILTER_EXPR" 2>/dev/null
fi | jq 'with_entries(select(.value != null))'
