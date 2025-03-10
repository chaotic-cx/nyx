#! /usr/bin/env nix-shell
#! nix-shell -i bash -p coreutils moreutils curl jq nix-prefetch-git cargo gnugrep gawk
# shellcheck shell=bash

set -euo pipefail

versionJson="$(realpath "./pkgs/scx-git/version.json")"
nixFolder="$(dirname "$versionJson")"

localRev=$(jq -r .scx.rev <$versionJson)

scxRepoRes=$(nix-prefetch-git --fetch-submodules --quiet 'https://github.com/sched-ext/scx.git')

latestRev=$(echo "$scxRepoRes" | jq -r .rev)
if [ "$localRev" == "$latestRev" ]; then
  exit 0
fi

latestDate=$(date -u --date=$(echo $scxRepoRes | jq -r .date) '+%Y%m%d%H%M%S')
latestVer="unstable-$latestDate-${latestRev:0:7}"
latestHash=$(echo "$scxRepoRes" | jq -r .hash)

tmp=$(mktemp -d)
trap 'rm -rf -- "${tmp}"' EXIT

git clone https://github.com/sched-ext/scx.git "$tmp/scx"

pushd "$tmp/scx"
git checkout "$latestRev"

bpftoolRev=$(grep 'bpftool_commit =' ./meson.build | awk -F"'" '{print $2}')
bpftoolHash=$(nix-prefetch-git https://github.com/libbpf/bpftool.git --rev $bpftoolRev --fetch-submodules --quiet | jq -r .hash)

libbpfRev=$(grep 'libbpf_commit =' ./meson.build | awk -F"'" '{print $2}')
libbpfHash=$(nix-prefetch-git https://github.com/libbpf/libbpf.git --rev $libbpfRev --fetch-submodules --quiet | jq -r .hash)

jq \
  --arg latestVer "$latestVer" --arg latestRev "$latestRev" --arg latestHash "$latestHash" \
  --arg bpftoolRev "$bpftoolRev" --arg bpftoolHash "$bpftoolHash" \
  --arg libbpfRev "$libbpfRev" --arg libbpfHash "$libbpfHash" \
  ".scx.version = \$latestVer | .scx.rev = \$latestRev | .scx.hash = \$latestHash |\
  .bpftool.rev = \$bpftoolRev | .bpftool.hash = \$bpftoolHash |\
  .libbpf.rev = \$libbpfRev | .libbpf.hash = \$libbpfHash" \
  "$versionJson" | sponge $versionJson

popd

cargoHash=$((nix-build --attr scx_git.rustscheds 2>&1 || true) | awk '/got/{print $2}')

jq \
  --arg cargoHash "$cargoHash" \
  ".scx.cargoHash = \$cargoHash" \
  "$versionJson" | sponge $versionJson

git add "$nixFolder"
git commit -m "scx_git: $localRev -> $latestRev"
