{ flakes, nixConfig, utils, self ? flakes.self }: flakes.yafas.withAllSystems { }
  (universals: { system, ... }:
  let
    nixPkgs = import flakes.nixpkgs {
      inherit system;
      config = {
        allowUnfree = true;
        allowUnsupportedSystem = true;
        nvidia.acceptLicense = true;
      };
    };
    nyxPkgs = utils.applyOverlay { pkgs = nixPkgs; };
  in
  with universals; {
    packages = nyxPkgs;
    nixpkgs = nixPkgs;
    mergedPkgs = utils.applyOverlay {
      pkgs = nixPkgs;
      merge = true;
      replace = true;
    };
    system = flakes.nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [ self.nixosModules.default ];
    };
  })
{
  inherit nixConfig;
}
