{ flakes
, flake-schemas ? flakes.flake-schemas
, nixpkgs ? flakes.nixpkgs
, self ? flakes.self
, baseSystem ? "x86_64-linux"
}:
{
  inherit (flake-schemas.schemas) devShells overlays schemas nixosModules homeModules;
  nixConfig = {
    version = 1;
    doc = ''
      Exposes nixConfig as seen in Flakes.
    '';
    inventory = _output: {
      shortDescription = "Exposes nixConfig as seen in Flakes.";
      what = "attrset";
      #evalChecks.isDerivation = false;
    };
  };
  formatter = {
    version = 1;
    doc = ''
      Auto-format tool.
    '';
    inventory = output: {
      children =
        let
          forSystem = sys: {
            forSystems = [ sys ];
            shortDescription = "Auto-format tool";
            #evalChecks.isDerivation = true;
            derivation = output.${sys};
            what = "package";
          };
        in
        {
          x86_64-linux = forSystem "x86_64-linux";
          aarch64-linux = forSystem "aarch64-linux";
        };
    };
  };
  homeManagerModules = flake-schemas.schemas.homeModules;
  packages = {
    version = 1;
    doc = ''
      The `packages` flake output contains packages that can be added to a shell using `nix shell`.
    '';
    inventory = import ./packages/inventory.nix { inherit nixpkgs; };
  };
  utils = {
    version = 1;
    doc = ''
      Pack of functions that are useful for Chaotic-Nyx and might become useful for you too.
    '';
    inventory = output: {
      children = builtins.mapAttrs
        (_name: _value: {
          what = "lambda";
          #evalChecks.isDerivation = false;
        })
        (builtins.removeAttrs output [ "_description" ]);
    };
  };
}
