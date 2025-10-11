{
  coreutils,
  curl,
  findutils,
  git,
  jq,
  lib,
  nix,
  nix-prefetch-git,
  writeShellScript,
  ...
}:
let
  path = lib.makeBinPath [
    coreutils
    curl
    findutils
    git
    jq
    nix
    nix-prefetch-git
  ];
in
writeShellScript "update-firedragon-bin" ''
   set -euo pipefail
   PATH=${path}

   version_file="pkgs/firedragon-bin/version.json"

   err() { printf '%s\n' "$*" >&2; }

   # Read current version and whether sources already present
   current_version=""
   existing_sources=0
   if [[ -f "$version_file" ]]; then
  	    current_version="$(jq -r '.version // ""' "$version_file" 2>/dev/null || echo "")"
      	existing_sources="$(jq -r '.sources | length // 0' "$version_file" 2>/dev/null || echo 0)"
   fi

   err "Current: ''${current_version:-<none>}, existing sources: $existing_sources"

   # Obtain latest release tag from GitLab
   releases_api="https://gitlab.com/api/v4/projects/69949446/releases"
   err "Querying GitLab releases..."
   latest_tag="$(curl -fsS "$releases_api" | jq -r '.[0].tag_name // empty')" || {
      	err "Error: failed to query GitLab releases"
      	exit 1
   }
   if [[ -z "$latest_tag" || "$latest_tag" == "null" ]]; then
      	err "Error: could not determine latest release tag"
      	exit 1
   fi

   latest_version="''${latest_tag#v}"
   err "Latest release: $latest_version"

   # If already up-to-date and sources exist, do nothing
   if [[ "$current_version" == "$latest_version" && "$existing_sources" -gt 0 ]]; then
      	err "Up-to-date: $current_version and sources already present. No changes."
      	exit 0
   fi

   arch_keys=(aarch64-linux x86_64-linux aarch64-darwin x86_64-darwin)
   declare -A filenames=(
      	["aarch64-linux"]="firedragon-linux-arm64.tar.xz"
      	["x86_64-linux"]="firedragon-linux-x64.tar.xz"
      	["aarch64-darwin"]="firedragon-darwin-arm64.dmg"
      	["x86_64-darwin"]="firedragon-darwin-x64.dmg"
   )

   base_download="https://gitlab.com/garuda-linux/firedragon/firedragon12/-/releases/$latest_tag/downloads"

   declare -A urls
   declare -A shas

   for arch in "''${arch_keys[@]}"; do
      	fname="''${filenames[$arch]}"
      	url="''${base_download}/''${fname}"
      	err "Prefetching $arch -> $fname"

      	if ! raw_hash="$(nix-prefetch-url --type sha256 "$url" 2>/dev/null)"; then
         	err "Error: nix-prefetch-url failed for $url"
         	exit 1
      	fi

      	hash="$(tr -d '[:space:]' <<<"$raw_hash")"
      	if [[ -z "$hash" ]]; then
         	err "Error: received empty hash for $url"
         	exit 1
      	fi

      	urls[$arch]="$url"
      	shas[$arch]="$hash"
      	err " -> $arch sha: $hash"
   done

   tmpfile="$(mktemp)"
   {
      	echo "{"
      	printf '  "version": "%s",\n' "$latest_version"
      	echo '  "sources": {'
      	first=1

      	for arch in "''${arch_keys[@]}"; do
         	url="''${urls[$arch]:-}"
         	sha="''${shas[$arch]:-}"
         	if [[ -z "$url" || -z "$sha" ]]; then
        		continue
         	fi
         	if [[ $first -eq 0 ]]; then
        		echo "    ,"
         	fi

         	esc_url="''${url//\"/\\\"}"
         	esc_sha="''${sha//\"/\\\"}"
         	printf '    "%s": {"url":"%s","sha256":"%s"}' "$arch" "$esc_url" "$esc_sha"
         	first=0
      	done

      	echo
      	echo '  }'
      	echo '}'
   } >"$tmpfile"

   if jq -e . "$tmpfile" >/dev/null 2>&1; then
      	jq . "$tmpfile" >"$version_file"
      	rm -f "$tmpfile"
   else
      	err "Error: generated JSON is invalid; aborting."
      	rm -f "$tmpfile"
      	exit 1
   fi

   git add "$version_file"
   git commit -m "firedragon-bin: $current_version -> $latest_version"
''
