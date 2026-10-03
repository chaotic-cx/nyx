{
  flakes,
  flake-schemas ? flakes.flake-schemas,
}:
{
  inherit (flake-schemas.schemas)
    checks
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
  homeManagerModules = flake-schemas.schemas.homeModules // {
    doc = ''
      **DEPRECATED**. Use `homeModules` instead.
    '';
  };
  unrestrictedPackages = flake-schemas.schemas.legacyPackages // {
    doc = ''
      Same as legacyPackages, but with allowUnfree, allowUnsupported, and required licenses to build.
    '';
    inventory = _output: {
      shortDescription = "Building set (legacyPackages + allowUnfree + allowUnsupported)";
      what = "legacyPackages";
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
      }) (removeAttrs output [ "_description" ]);
    };
  };
  vendored = {
    version = 1;
    doc = ''
      Flake inputs we don't want in our users' flake lock.
    '';
    inventory = output: {
      children = builtins.mapAttrs (name: value: {
        shortDescription = "Vendored ${name}'s flake";
        what = value._type;
      }) output;
    };
  };
}
