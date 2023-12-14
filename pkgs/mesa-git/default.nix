{ final
, flakes
, nyxUtils
, prev
, gitOverride
, gbmDriver ? false
, gbmBackend ? "dri_git"
, mesaTestAttrs ? final
, ...
}:

let
  inherit (final.stdenv) is32bit;

  cargoDeps = {
    proc-macro2 = { version = "1.0.56"; hash = "sha256-K2O9sM0G8fTe32myVHNPm0WvZuSgMeQqdIAlfZiYtDU="; };
    quote = { version = "1.0.25"; hash = "sha256-UwjoIIcpw+FQSmz60NXarMRhTJouZdHqMSo0tcsA/oQ="; };
    syn = { version = "2.0.15"; hash = "sha256-o0/PPotg9X5qFDAaLpFtMjr5iw6mPFmUQe7IVYZgyCI="; };
    unicode-ident = { version = "1.0.6"; hash = "sha256-hKIrnyGLQGFK3LP0/wi3A3c61E+pQj5ODTRtXbhuTrw="; };
  };
in
gitOverride (current: {
  newInputs = if is32bit then { } else with final; {
    meson = meson_1_3;
    # We need to mention those besides "all", because of the usage of nix's `lib.elem` in
    # the original derivation.
    galliumDrivers = [ "all" "zink" "d3d12" ];
    vulkanDrivers = [ "all" "microsoft-experimental" ];
    # Instead, we enable the new option in `mesonFlags`
    enablePatentEncumberedCodecs = false;
  };

  nyxKey = if is32bit then "mesa32_git" else "mesa_git";
  prev = prev.mesa;

  versionNyxPath = "pkgs/mesa-git/version.json";
  fetcher = "fetchFromGitHub";
  fetcherData = {
    owner = "chaotic-cx";
    repo = "mesa-mirror";
  };
  withUpdateScript = !is32bit;
  version = builtins.substring 0 (builtins.stringLength prev.mesa.version) current.rev;

  postOverride = prevAttrs: {
    mesonFlags =
      builtins.map
        (builtins.replaceStrings [ "virtio-experimental" ] [ "virtio" ])
        prevAttrs.mesonFlags
      ++ final.lib.optional (!is32bit) "-D video-codecs=all";

    patches =
      (nyxUtils.removeByBaseName
        "disk_cache-include-dri-driver-path-in-cache-key.patch"
        (nyxUtils.removeByBaseName
          "opencl.patch"
          prevAttrs.patches
        )
      ) ++ [
        ./opencl.patch
        ./disk_cache-include-dri-driver-path-in-cache-key.patch
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
      + (cargoSubproject "unicode-ident");

    # move new backend to its own output (if necessary)
    postInstall =
      if gbmDriver then prevAttrs.postInstall + ''
        mkdir -p $gbm/lib/gbm
        ln -s $out/lib/libgbm.so $gbm/lib/gbm/${gbmBackend}_gbm.so
      '' else prevAttrs.postInstall;

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
