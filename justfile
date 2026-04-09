@update-custom-package target:
    nix develop --impure ./maintenance#updater -c bash -c 'script=$(nix eval --raw .#{{ target }}.updateScript 2>/dev/null); NYX_NO_GPG_SIGN=1 bash -c "$script"' -L

@cachix target:
  nix run nixpkgs#cachix -- push loneros $(nix path-info .#{{ target }})
