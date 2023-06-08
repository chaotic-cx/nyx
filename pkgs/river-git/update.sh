#!/usr/bin/env nix-shell
#!nix-shell -i bash -p  busybox curl jq moreutils nix-prefetch-git
set -eo pipefail

# Define the file path
json_file=./src.json

# Define the repository information
repositories=(
  "ifreund/zig-wayland"
  "ifreund/zig-pixman"
  "ifreund/zig-xkbcommon"
  "swaywm/zig-wlroots"
)

# Loop through repositories
for repo_info in "${repositories[@]}"; do
  # Split repository information into name and URL
  IFS='/' read -ra repo <<< "$repo_info"
  repo_name=${repo[1]}

  # Fetch repository information
  repo_data=$(nix-prefetch-git https://github.com/$repo_info --quiet)
  repo_rev=$(jq -r '.rev' <<< "$repo_data")
  repo_hash=$(nix-hash --type sha256 --to-sri $(jq -r '.sha256' <<< "$repo_data"))

  # Update JSON file using jq
  jq --arg name "$repo_name" --arg rev "$repo_rev" --arg hash "$repo_hash" \
    '.[$name] = { "rev": $rev, "hash": $hash }' "$json_file" | sponge "$json_file"
done
