#! /usr/bin/env nix-shell
#! nix-shell -i bash -p cargo
set -eu

if ! [ -f common.nix ]; then
  echo 'Needs to run in pkgs/scx' >&2
  exit 1
fi

PKGROOT=$PWD

cd /tmp
if [ -d scx ]; then
  echo 'WARNING: Using an already cloned version of scx, the result might be outdated.'
else
  git clone --single-branch 'https://github.com/sched-ext/scx.git' scx
fi

cd /tmp/scx
CURRREV=$(git rev-parse HEAD)
rm Cargo.lock Cargo.toml

for s in bpfland lavd layered rlfifo rustland rusty; do
  target="scheds/rust/scx_$s"
  echo $target
  cargo -Z unstable-options -C "$target" generate-lockfile --verbose
  cp "$target/Cargo.lock" "$PKGROOT/${s}/Cargo.lock"
done

cargo  -Z unstable-options -C "rust/scx_stats" generate-lockfile --verbose
cp rust/scx_stats/Cargo.lock "$PKGROOT/stats/Cargo.lock"

echo "Updated to ${CURRREV}"
echo 'FINISHED SUCCESSFULLY'
