{ flakes
, flake-schemas ? flakes.flake-schemas
, nixpkgs ? flakes.nixpkgs
, self ? flakes.self
, baseSystem ? "x86_64-linux"
}:
{
  inherit (flake-schemas.schemas) devShells overlays schemas;
  _dev = {
    version = 1;
    doc = ''
      Pre-prepared values for CI/CD.
    '';
    inventory = _output: { what = "Pre-prepared values for CI/CD."; };
  };
  formatter = {
    version = 1;
    doc = ''
      Auto-format tool.
    '';
    inventory = _output: {
      children = {
        x86_64-linux = { what = "Auto-format tool"; forSystems = [ "x86_64-linux" ]; };
        aarch64-linux = { what = "Auto-format tool"; forSystems = [ "aarch64-linux" ]; };
      };
    };
  };
  homeManagerModules = {
    version = 1;
    doc = ''
      The `homeManagerModules` flake output contains the modules and options we support for Home-Manager setups.
    '';
    inventory = import ./home-manager-modules/inventory.nix {
      inherit flakes;
      pkgs = nixpkgs.legacyPackages.${baseSystem};
    };
  };
  nixosModules = {
    version = 1;
    doc = ''
      The `nixosModules` flake output contains the modules and options we support for NixOS setups.
    '';
    inventory = import ./nixos-modules/inventory.nix {
      nyxosConfiguration = self._dev.${baseSystem};
      pkgs = nixpkgs.legacyPackages.${baseSystem};
    };
  };
  packages = {
    version = 1;
    doc = ''
      The `packages` flake output contains packages that can be added to a shell using `nix shell`.
    '';
    inventory = import ./packages/inventory.nix { inherit nixpkgs; };
  };
}
