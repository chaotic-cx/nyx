{ final
, final64 ? final
, flakes
, prev
, gitOverride
, nyxUtils
, gbmDriver ? false
, gbmBackend ? "dri_git"
, mesaTestAttrs ? final
, ...
}:

let
  inherit (final.stdenv) is32bit;

  cargoDeps = {
    proc-macro2 = { version = "1.0.86"; hash = "sha256-XnGejfZl3w0cj7/SOAFXRHNhUdREXsCDa45iiq4QO3c="; };
    quote = { version = "1.0.33"; hash = "sha256-Umf8pElgKGKKlRYPxCOjPosuavilMCV54yLktSApPK4="; };
    syn = { version = "2.0.68"; hash = "sha256-kB+nDYi51smAIuI7QTb58+VORmLDvBvR2EpCqaDwwek="; };
    unicode-ident = { version = "1.0.12"; hash = "sha256-M1S5rD+uH/Z1XLbbU2g622YWNPZ1V5Qt6k+s6+wP7ks="; };
    paste = { version = "1.0.14"; hash = "sha256-3jFFrwgCTeqfqZFPOBoXuPxgNN+wDzqEAT9/9D8p7Uw="; };
  };
in
gitOverride (current: {
  newInputs =
    {
      wayland-protocols = final64.wayland-protocols_git;
      galliumDrivers = [ "all" ];
      directx-headers = final.directx-headers.overrideAttrs (_prevAttrs: rec {
        version = "1.614.1";

        src = final.fetchFromGitHub {
            owner = "microsoft";
            repo = "DirectX-Headers";
            rev = "v${version}";
            hash = "sha256-CDmzKdV40EExLpOHPAUnytqG9x1+IGW4AZldfYs5YJk=";
        };
      });
    } // (if is32bit then with final64; {
      libdrm = libdrm32_git;
    } else with final; {
      libdrm = libdrm_git;
    });

  nyxKey = if is32bit then "mesa32_git" else "mesa_git";
  prev = prev.mesa;

  versionNyxPath = "pkgs/mesa-git/version.json";
  fetcher = "fetchFromGitHub";
  fetcherData = {
    owner = "chaotic-cx";
    repo = "mesa-mirror";
  };
  withUpdateScript = !is32bit;

  # Matching the drvName length to use with replaceRuntime
  version = builtins.substring 0 (builtins.stringLength prev.mesa.version) current.rev;

  postOverride = prevAttrs: {
    nativeBuildInputs = with final; [ rustfmt python3Packages.pyyaml ] ++ prevAttrs.nativeBuildInputs;

    mesonFlags = nyxUtils.removeByPrefixes [ "-Domx-libs-path=" "-Ddri-search-path=" ] prevAttrs.mesonFlags;

    patches = prevAttrs.patches ++ [ ./gbm-backend.patch ];

    postPatch =
      let
        cargoFetch = who: final.fetchurl {
          url = "https://crates.io/api/v1/crates/${who}/${cargoDeps.${who}.version}/download";
          inherit (cargoDeps.${who}) hash;
        };

        cargoSubproject = who: ''
          ln -s ${cargoFetch who} subprojects/packagecache/${who}-${cargoDeps.${who}.version}.tar.gz
        '';

        # allow renaming the new backend name
        backendRename =
          if gbmBackend != "dri_git" then ''
            sed -i"" 's/"dri_git"/"${gbmBackend}"/' src/gbm/backends/dri/gbm_dri.c src/gbm/main/backend.c
          '' else "";
      in
      prevAttrs.postPatch
      + backendRename
      + ''
        mkdir subprojects/packagecache
      ''
      + (cargoSubproject "proc-macro2")
      + (cargoSubproject "quote")
      + (cargoSubproject "syn")
      + (cargoSubproject "unicode-ident")
      + (cargoSubproject "paste");

    # move new backend to its own output (if necessary)
    postInstall =
      let
        addGbmRename = prevStr:
          if gbmDriver then prevStr + ''
            mv $drivers/lib/gbm/dri_gbm.so $drivers/lib/gbm/${gbmBackend}_gbm.so
          '' else prevStr;

        update24_2 =
          builtins.replaceStrings [
            ''moveToOutput "lib/lib*_mesa*" $drivers''
          ] [
            ''moveToOutput "lib/lib*_mesa*" $drivers; moveToOutput "lib/gbm" $drivers; moveToOutput "lib/libglapi*" $drivers''
          ]
            prevAttrs.postInstall;
      in
      addGbmRename update24_2;

    # test and accessible information
    passthru = prevAttrs.passthru // {
      inherit gbmBackend;
      tests.smoke-test = import ./test.nix
        {
          inherit (flakes) nixpkgs;
          chaotic = flakes.self;
        }
        mesaTestAttrs;
    };
  };
})
