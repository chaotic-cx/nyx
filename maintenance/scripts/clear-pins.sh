#!/usr/bin/env bash
set -euo pipefail

NIKS3=$(nix build .#niks3_nyx --no-link --print-out-paths)
export PATH="$NIKS3/bin:$PATH"

mkdir -p ./tmp

EXPECTED_PINS=$(nix build ./maintenance#chaotic-nyx.expected-pins --no-link --print-out-paths)
sort -u "$EXPECTED_PINS" >tmp/expected-pins.txt

niks3 pins list | awk 'NR > 1 {print $1}' | sort -u >tmp/actual-pins.txt

test -s tmp/expected-pins.txt && test -s tmp/actual-pins.txt || {
  echo "Pins list empty, aborting." >&2
  exit 2
}

comm -13 tmp/expected-pins.txt tmp/actual-pins.txt | tee tmp/orphan-pins.txt

ORPHAN_PINS_SIZE=$(wc -c <tmp/orphan-pins.txt)
if ((ORPHAN_PINS_SIZE < $(wc -c <tmp/actual-pins.txt) && ORPHAN_PINS_SIZE < $(wc -c <tmp/expected-pins.txt))); then
  xargs -r -n 1 niks3 pins delete <tmp/orphan-pins.txt
else
  echo "Trying to delete all pins or something which are not pins" >&2
  exit 1
fi
