{
  flakes,
  flake-schemas ? flakes.flake-schemas,
}:
{
  inherit (flake-schemas.schemas)
    devShells
    formatter
    homeModules
    legacyPackages
    nixosModules
    overlays
    packages
    schemas
    ;
  nixConfig = {
    version = 1;
    doc = ''
      Exposes nixConfig as seen in Flakes.
    '';
    inventory = _output: {
      shortDescription = "Exposes nixConfig as seen in Flakes.";
      what = "attrset";
    };
  };
  homeManagerModules = flake-schemas.schemas.homeModules;
  unrestrictedPackages = {
    version = 1;
    doc = ''
      Same as legacyPackages, but with allowUnfree, allowUnsupported, and required licenses to build.
    '';
    inventory = _output: {
      shortDescription = "Buildable attrset for CI.";
      what = "attrset";
    };
  };
  utils = {
    version = 1;
    doc = ''
      Pack of functions that are useful for Chaotic-Nyx and might become useful for you too.
    '';
    inventory = output: {
      children = builtins.mapAttrs (_name: _value: {
        what = "function";
      }) (builtins.removeAttrs output [ "_description" ]);
    };
  };
}
