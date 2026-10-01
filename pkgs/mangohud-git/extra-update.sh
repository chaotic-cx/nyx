#!/usr/bin/env bash

manifest="$_NYX_DIR/$_PKG_DIR/manifest.json"

pushd "$_LATEST_PATH" || exit 2

for wrap in subprojects/*.wrap; do
  [ -f "$wrap" ] || exit 3

  origin=$(basename "$wrap" .wrap)
  dir=$(sed -n 's/^directory[[:space:]]*=[[:space:]]*\(.*\)/\1/p' "$wrap" | tr -d '\r')
  s_url=$(sed -n 's/^source_url[[:space:]]*=[[:space:]]*\(.*\)/\1/p' "$wrap" | tr -d '\r')
  s_hash=$(sed -n 's/^source_hash[[:space:]]*=[[:space:]]*\(.*\)/\1/p' "$wrap" | tr -d '\r')
  p_url=$(sed -n 's/^patch_url[[:space:]]*=[[:space:]]*\(.*\)/\1/p' "$wrap" | tr -d '\r')
  p_hash=$(sed -n 's/^patch_hash[[:space:]]*=[[:space:]]*\(.*\)/\1/p' "$wrap" | tr -d '\r')

  if [ -n "$dir" ] && [ -n "$s_url" ] && [ -n "$s_hash" ]; then
    jq \
      --arg org "$origin" \
      --arg dir "$dir" \
      --arg su "$s_url" \
      --arg sh "$s_hash" \
      --arg pu "$p_url" \
      --arg ph "$p_hash" \
      '.subprojects = (.subprojects // {}) |
             .subprojects[$org] = { directory: $dir, src: { url: $su, hash: $sh } } +
             (if $pu != "" then { patch: { url: $pu, hash: $ph } } else {} end)' \
      "$manifest" >"${manifest}.tmp" && mv "${manifest}.tmp" "$manifest"
  fi
done

popd || exit 4

git add "$manifest"
