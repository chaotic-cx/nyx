#!/usr/bin/env bash
set -euo pipefail

treefmt --ci
statix check .
deadnix --fail .

_SHORT_FILES=$(find . -type f -name '*.nix' -print0 | (xargs -0 rg -P '[^\w"-\/\{](?!_?xs|_?id|_?[kvx]:)(_?[a-zA-Z_][a-zA-Z_-]?:)(?!\w)' || true) )
if [[ -n "$_SHORT_FILES" ]]; then
  echo "Lambda parameters can't have two letters or less (except: x, xs, id, k, v):"
  echo "$_SHORT_FILES"
  exit 1
fi

prettier -c .
shfmt -l .

find . -type f -name '*.sh' -print0 | xargs -0 -r shellcheck -a
actionlint

tidy --show-body-only yes --mute MISSING_DOCTYPE -q -e README.md

echo "Finished successfully"
