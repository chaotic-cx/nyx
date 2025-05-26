{
  final,
  final64 ? final,
  flakes,
  prev,
  gitOverride,
  nyxUtils,
  mesaTestAttrs ? final,
  ...
}:

let
  inherit (final.stdenv) is32bit;

  rustDeps = [
    {
      pname = "rustc-hash";
      version = "2.1.1";
      hash = "sha256-3rQidUAExJ19STn7RtKNIpZrQUne2VVH7B1IO5UY91k=";
    }
  ];

  copyRustDep = dep: ''
    cp -R --no-preserve=mode,ownership ${final.fetchCrate dep} subprojects/${dep.pname}-${dep.version}
    cp -R subprojects/packagefiles/${dep.pname}/* subprojects/${dep.pname}-${dep.version}/
  '';

  copyRustDeps = final.lib.concatStringsSep "\n" (builtins.map copyRustDep rustDeps);
in
gitOverride (current: {
  newInputs =
    if final.stdenv.isLinux then
      {
        wayland-protocols = final64.wayland-protocols_git;
        galliumDrivers = [ "all" ];
        directx-headers =
          # https://gitlab.freedesktop.org/mesa/mesa/-/issues/13126
          final.directx-headers.overrideAttrs (_prevAttrs: {
            src = final.fetchFromGitHub {
              owner = "microsoft";
              repo = "DirectX-Headers";
              rev = "v1.614.1";
              hash = "sha256-CDmzKdV40EExLpOHPAUnytqG9x1+IGW4AZldfYs5YJk=";
            };
          });
      }
      // (
        if is32bit then
          with final64;
          {
            libdrm = libdrm32_git;
          }
        else
          with final;
          {
            libdrm = libdrm_git;
          }
      )
    else
      { };

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
    patches = [
      ./opencl.patch
    ];

    postPatch =
      if final.stdenv.isLinux then
        prevAttrs.postPatch
        + ''
          ${copyRustDeps}
        ''
      else
        prevAttrs.postPatch or "";

    mesonFlags = nyxUtils.removeByPrefixes [ "-Dosmesa" "-Dgallium-opencl" "-Dgallium-nine" "-Dgallium-xa" ] prevAttrs.mesonFlags;

    # test and accessible information
    passthru = prevAttrs.passthru // {
      tests.smoke-test = import ./test.nix {
        inherit (flakes) nixpkgs;
        chaotic = flakes.self;
      } mesaTestAttrs;
    };
  };
})
