{ final
, final64 ? final
, flakes
, prev
, gitOverride
, gbmDriver ? false
, gbmBackend ? "dri_git"
, mesaTestAttrs ? final
, ...
}:

let
  inherit (final.stdenv) is32bit;
in
gitOverride (current: {
  newInputs =
    {
      wayland-protocols = final64.wayland-protocols_git;
      # We need to mention those besides "all", because of the usage of nix's `lib.elem` in
      # the original derivation.
      galliumDrivers = [ "all" "i915" ];
      vulkanDrivers = [ "all" ];
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
    nativeBuildInputs = with final; [ rust-cbindgen python3Packages.pycparser ] ++ prevAttrs.nativeBuildInputs;
    buildInputs = with final; [ rust-cbindgen ] ++ prevAttrs.buildInputs;

    mesonFlags =
      builtins.map
        (builtins.replaceStrings [ "virtio-experimental" ] [ "virtio" ])
        prevAttrs.mesonFlags
      ++ final.lib.optional is32bit "-D intel-rt=disabled";

    patches = [
      ./gbm-backend.patch
    ];

    # expose gbm backend and rename vendor (if necessary)
    outputs =
      if gbmDriver
      then prevAttrs.outputs ++ [ "gbm" ]
      else prevAttrs.outputs;

    postPatch =
      let
        # allow renaming the new backend name
        backendRename =
          if gbmBackend != "dri_git" then ''
            sed -i"" 's/"dri_git"/"${gbmBackend}"/' src/gbm/backends/dri/gbm_dri.c src/gbm/main/backend.c
          '' else "";
      in
      prevAttrs.postPatch
      + backendRename;

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
