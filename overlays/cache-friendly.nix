{ flakes }: userFinal: _userPrev:
let
  inherit (userFinal) stdenv;
  isCross = stdenv.buildPlatform != stdenv.hostPlatform;

  prev =
    if isCross then
      import "${flakes.nixpkgs}"
        {
          inherit (cfg.flakeNixpkgs) config;
          localSystem = stdenv.buildPlatform;
          crossSystem = stdenv.hostPlatform;
        }
    else
      import "${flakes.nixpkgs}" {
        inherit (cfg.flakeNixpkgs) config;
        localSystem = flakes.nixpkgs.legacyPackages."${userFinal.stdenv.hostPlatform.system}".stdenv.hostPlatform;
      };
in
flakes.self.utils.applyOverlay { pkgs = prev; }
