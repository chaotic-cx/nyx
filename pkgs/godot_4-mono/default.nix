# Taken from https://github.com/NixOS/nixpkgs/pull/285941 and updated to latest stable
# Thanks to ilikefrogs101 for the original PR!
{ lib
, stdenv
, fetchFromGitHub
, pkg-config
, autoPatchelfHook
, installShellFiles
, scons
, python3
, mkNugetDeps
, vulkan-loader
, libGL
, libX11
, libXcursor
, libXinerama
, libXext
, libXrandr
, libXrender
, libXi
, libXfixes
, libxkbcommon
, alsa-lib
, libpulseaudio
, dbus
, speechd
, fontconfig
, udev
, wayland-scanner
, withPlatform ? "linuxbsd"
, withTarget ? "editor"
, withPrecision ? "single"
, withPulseaudio ? true
, withDbus ? true
, withSpeechd ? true
, withFontconfig ? true
, withUdev ? true
, deps ? ./deps.nix
, mono
, callPackage
, dotnet-sdk_8
, dotnet-runtime_8
, makeWrapper
, msbuild
,
}:
assert lib.asserts.assertOneOf "withPrecision" withPrecision [ "single" "double" ];
stdenv.mkDerivation rec {
  pname = "godot_4-mono";
  version = "4.3-stable";
  commitHash = "77dcf97d82cbfe4e4615475fa52ca03da645dbd8";
  sourceHash = "sha256-v2lBD3GEL8CoIwBl3UoLam0dJxkLGX0oneH6DiWkEsM=";

  src = fetchFromGitHub {
    owner = "godotengine";
    repo = "godot";
    rev = commitHash;
    hash = sourceHash;
  };

  keepNugetConfig = deps == null;

  nativeBuildInputs = [
    pkg-config
    autoPatchelfHook
    installShellFiles
    python3
    speechd
    wayland-scanner
    makeWrapper
    mono
    dotnet-sdk_8
    dotnet-runtime_8
  ];

  buildInputs = [
    scons
  ] ++ lib.optional (deps != null)
    (mkNugetDeps { name = "deps"; nugetDeps = import deps; });

  runtimeDependencies =
    [
      vulkan-loader
      libGL
      libX11
      libXcursor
      libXinerama
      speechd
      libXext
      libXrandr
      libXrender
      libXi
      libXfixes
      libxkbcommon
      alsa-lib
      mono
      wayland-scanner
      dotnet-sdk_8
      dotnet-runtime_8
    ]
    ++ lib.optional withPulseaudio libpulseaudio
    ++ lib.optional withDbus dbus
    ++ lib.optional withDbus dbus.lib
    ++ lib.optional withSpeechd speechd
    ++ lib.optional withFontconfig fontconfig
    ++ lib.optional withFontconfig fontconfig.lib
    ++ lib.optional withUdev udev;

  enableParallelBuilding = true;

  # Set the build name which is part of the version. In official downloads, this
  # is set to 'official'. When not specified explicitly, it is set to
  # 'custom_build'. Other platforms packaging Godot (Gentoo, Arch, Flatpack
  # etc.) usually set this to their name as well.
  #
  # See also 'methods.py' in the Godot repo and 'build' in
  # https://docs.godotengine.org/en/stable/classes/class_engine.html#class-engine-method-get-version-info
  BUILD_NAME = "chaotic-nyx";

  # Required for the commit hash to be included in the version number.
  #
  # `methods.py` reads the commit hash from `.git/HEAD` and manually follows
  # refs. Since we just write the hash directly, there is no need to emulate any
  # other parts of the .git directory.
  #
  # See also 'hash' in
  # https://docs.godotengine.org/en/stable/classes/class_engine.html#class-engine-method-get-version-info
  preConfigure = ''
    mkdir -p .git
    echo ${commitHash} > .git/HEAD
  '';

  outputs = [ "out" "man" ];

  postConfigure = ''
    echo "Setting up buildhome."
    mkdir buildhome
    export HOME="$PWD"/buildhome
  '';

  buildPhase = ''
    echo "Starting Build"
    scons p=${withPlatform} target=${withTarget} precision=${withPrecision} module_mono_enabled=yes mono_glue=no

    echo "Generating Glue"
    if [[ ${withPrecision} == *double* ]]; then
        bin/godot.${withPlatform}.${withTarget}.${withPrecision}.x86_64.mono --headless --generate-mono-glue modules/mono/glue
    else
        bin/godot.${withPlatform}.${withTarget}.x86_64.mono --headless --generate-mono-glue modules/mono/glue
    fi

    echo "Building Assemblies"
    scons p=${withPlatform} target=${withTarget} precision=${withPrecision} module_mono_enabled=yes mono_glue=yes

    echo "Building C#/.NET Assemblies"
    python modules/mono/build_scripts/build_assemblies.py --godot-output-dir bin --precision=${withPrecision}
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/bin"
    cp bin/godot.* $out/bin/godot4-mono
    cp -r bin/GodotSharp/ $out/bin/

    installManPage misc/dist/linux/godot.6

    mkdir -p "$out"/share/{applications,icons/hicolor/scalable/apps}
    cp misc/dist/linux/org.godotengine.Godot.desktop "$out/share/applications/org.godotengine.Godot4-Mono.desktop"
    substituteInPlace "$out/share/applications/org.godotengine.Godot4-Mono.desktop" \
      --replace-quiet "Exec=godot" "Exec=$out/bin/godot4-mono" \
      --replace-quiet "Godot Engine" "Godot Engine ${version} (Mono, $(echo "${withPrecision}" | sed 's/.*/\u&/') Precision)"
    cp icon.svg "$out/share/icons/hicolor/scalable/apps/godot.svg"
    cp icon.png "$out/share/icons/godot.png"

    wrapProgram $out/bin/godot4-mono \
      --set DOTNET_ROOT ${dotnet-sdk_8} \
      --prefix PATH : "${lib.makeBinPath [
      dotnet-sdk_8
      dotnet-runtime_8
      mono
      msbuild
    ]}"
    runHook postInstall
  '';

  meta = {
    homepage = "https://godotengine.org";
    description = "Free and Open Source 2D and 3D game engine";
    license = lib.licenses.mit;
    platforms = [ "i686-linux" "x86_64-linux" "aarch64-linux" ];
    maintainers = with lib.maintainers; [ dr460nf1r3 ];
    mainProgram = "godot4-mono";
  };

  passthru = {
    make-deps = callPackage ./make-deps.nix { };
  };
}
