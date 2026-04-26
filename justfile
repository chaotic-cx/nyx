@update-custom-package target:
    nix develop --impure ./maintenance#updater -c bash -c 'script=$(nix eval --raw .#{{ target }}.updateScript 2>/dev/null); bash -c "$script"' -L

@cachix target:
  nix run nixpkgs#cachix -- push loneros $(nix path-info .#{{ target }})

@fast-build-package target:
    nix run github:Mic92/nix-fast-build -- \
      --flake .#{{ target }} \
      --skip-cached \
      --eval-workers 2 \
      --eval-max-memory-size 15360

@build target:
    NIXPKGS_ALLOW_UNFREE=1 nix build \
                     --impure \
                     --keep-going \
                     -L \
                     --no-link \
                     --accept-flake-config \
                     .#{{ target }}
