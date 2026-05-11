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

build target=`nix eval --impure --raw --expr '
  builtins.concatStringsSep "\n"
    (builtins.attrNames
      (builtins.getFlake (toString ./.))
        .packages.${builtins.currentSystem})
' | fzf`:
    NIXPKGS_ALLOW_UNSUPPORTED_SYSTEM=1 NIXPKGS_ALLOW_UNFREE=1 nix build \
        --impure \
        --keep-going \
        -L \
        --no-link \
        --accept-flake-config \
        .#{{target}}
