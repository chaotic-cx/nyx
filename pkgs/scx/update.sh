#! /usr/bin/env nix-shell
#! nix-shell -i bash -p cargo
set -eu

if ! [ -f common.nix ]; then
  echo 'Needs to run in pkgs/scx' >&2
  exit 1
fi

PKGROOT=$PWD
pushd /tmp

if [ -d scx ]; then
  echo 'WARNING: Using an already cloned version of scx, the result might be outdated.'
else
  git clone --single-branch 'https://github.com/sched-ext/scx.git'
fi

pushd scx
CURRREV=$(git rev-parse HEAD)

pushd scheds/rust
for s in bpfland lavd layered rlfifo rustland rusty; do
  pushd "scx_${s}"

  cargo generate-lockfile
  cp Cargo.lock "$PKGROOT/${s}/Cargo.lock"

  popd
done

popd
popd
popd

echo "Updated to ${CURRREV}"
echo 'FINISHED SUCCESSFULLY'
