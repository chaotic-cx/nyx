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
    nativeBuildInputs = with final; [ python3Packages.pyyaml rustfmt ] ++ prevAttrs.nativeBuildInputs;

    patches = prevAttrs.patches ++ [
      ./gbm-backend.patch
    ];

    # expose gbm backend and rename vendor (if necessary)
    outputs =
      if gbmDriver
      then prevAttrs.outputs ++ [ "gbm" ]
      else prevAttrs.outputs;

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
    # NOTE: Deleting gbm from $out became necessary after 20240722 bump
    postInstall =
      if gbmDriver then prevAttrs.postInstall + ''
        mkdir -p $gbm/lib/gbm
        mv $out/lib/libgbm.so.1.0.0 $gbm/lib/gbm/${gbmBackend}_gbm.so.1.0.0
        rm $out/lib/libgbm.so.1 $out/lib/libgbm.so
        pushd $gbm/lib/gbm/
        ln -s ${gbmBackend}_gbm.so.1.0.0 ${gbmBackend}_gbm.so.1
        ln -s ${gbmBackend}_gbm.so.1.0.0 ${gbmBackend}_gbm.so
        popd
      '' else prevAttrs.postInstall + ''
        rm $out/lib/libgbm.so{,.1.0.0,.1}
      '';

    # lib/dri/zink_dri.so is no more...
    postFixup =
      (nyxUtils.filterLines
        (line: !(final.lib.strings.hasSuffix "lib/dri/zink_dri.so" line))
        prevAttrs.postFixup);

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
