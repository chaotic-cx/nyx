if [ -z "$CACHIX_AUTH_TOKEN" ] && [ -z "$CACHIX_SIGNING_KEY" ]; then
  echo_error "No key for cachix -- failing to deploy."
  exit 23
elif [ -n "''${NYX_RESYNC:-}" ] || [ -s push.txt ]; then
  # Let nix digest store paths first
  sleep 10

  # Push all new deriations with compression
  cat push.txt | cachix push chaotic-nyx \
    --compression-method zstd

  # Pin packages
  if [ -e to-pin.txt ]; then
    cat to-pin.txt | xargs -n 2 \
      cachix -v pin chaotic-nyx
  fi
else
  echo_error "Nothing to push."
  exit 42
fi