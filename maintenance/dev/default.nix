{
  flakes,
  nixConfig,
  utils,
  self ? flakes.self,
}:
flakes.yafas.withAllSystems { }
  (
    universals:
    { system, ... }:
    let
      nixPkgsConfig = {
        allowUnfree = true;
        allowUnsupportedSystem = true;
        nvidia.acceptLicense = true;
      };
      nixPkgs = import flakes.nixpkgs {
        inherit system;
        config = nixPkgsConfig;
      };
      nyxPkgs = utils.applyOverlay { pkgs = nixPkgs; };
    in
    with universals;
    {
      legacyPackages = nyxPkgs;
      nixpkgs = nixPkgs;
      mergedPkgs = utils.applyOverlay {
        pkgs = nixPkgs;
        merge = true;
        replace = true;
      };
      system = flakes.nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          self.nixosModules.default
          { boot.isContainer = true; }
        ];
      };
      readOnlySystem = flakes.nixpkgs.lib.nixosSystem {
        modules = [
          {
            nixpkgs.pkgs = import flakes.nixpkgs {
              inherit system;
              config = nixPkgsConfig;
              overlays = [ self.overlays.cache-friendly ];
            };
            chaotic.nyx.overlay.enable = false;
            boot.isContainer = true;
          }
          flakes.nixpkgs.nixosModules.readOnlyPkgs
          self.nixosModules.default
        ];
      };
    }
  )
  {
    inherit nixConfig;
  }
