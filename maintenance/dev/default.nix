{ flakes, nixConfig, utils, self ? flakes.self }: flakes.yafas.withAllSystems { }
  (universals: { system, ... }:
  let
    pkgs = import flakes.nixpkgs {
      inherit system;
      config = {
        allowlistedLicenses = [ flakes.nixpkgs.lib.licenses.unfreeRedistributable ];
        nvidia.acceptLicense = true;
      };
    };
  in
  with universals; {
    packages = utils.applyOverlay { inherit pkgs; };
    nixpkgs = pkgs;
    system = flakes.nixpkgs.lib.nixosSystem {
      modules = [ self.nixosModules.default ];
      system = "x86_64-linux";
    };
  })
{
  inherit nixConfig;
}
