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

gitOverride (current: {
  nyxKey = if final.stdenv.is32bit then "mesa32_git" else "mesa_git";
  prev = prev.mesa;

  versionNyxPath = "pkgs/mesa-git/version.json";
  fetcher = "fetchFromGitHub";
  fetcherData = {
    owner = "chaotic-cx";
    repo = "mesa-mirror";
  };
  withUpdateScript = !final.stdenv.is32bit;
  version = builtins.substring 0 (builtins.stringLength prev.mesa.version) current.rev;

  postOverride = prevAttrs: {
    patches =
      prevAttrs.patches
       ++ [
        ./gbm-backend.patch
      ];
    # expose gbm backend and rename vendor (if necessary)
    outputs =
      if gbmDriver
      then prevAttrs.outputs ++ [ "gbm" ]
      else prevAttrs.outputs;
    # allow renaming the new backend name
    postPatch =
      if gbmBackend != "dri_git" then prevAttrs.postPatch + ''
        sed -i"" 's/"dri_git"/"${gbmBackend}"/' src/gbm/backends/dri/gbm_dri.c src/gbm/main/backend.c
      '' else prevAttrs.postPatch;
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
