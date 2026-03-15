{
  evil ? false,
  final,
  prev,
  gitOverride,
  flakes,
  ...
}:

let
  makeGrammar = final.tree-sitter.buildGrammar;

  rawLanguages = final.lib.trivial.importJSON (
    if evil then ./languages-evil.json else ./languages.json
  );
  languagesFile = if evil then "languages-evil.json" else "languages.json";

  languages = builtins.map (
    source:
    let
      # The fetcher logic was moved here from the old grammar-artifact.nix
      src =
        if source.type == "github" then
          final.fetchFromGitHub {
            inherit (source) owner repo rev;
            hash = source.narHash;
          }
        else if source.type == "git" then
          final.fetchgit {
            inherit (source) url rev;
            # fetchgit requires a name
            name = "source";
            hash = source.narHash;
          }
        else
          throw "Unsupported grammar source type: ''${source.type}''; expected 'github' or 'git'";
    in
    (source // { inherit src; })
    // (if source ? subpath && source.subpath != null then { location = source.subpath; } else { })
  ) rawLanguages;

  grammarArtifact =
    source:
    (final.callPackage ./grammar-artifact.nix { inherit makeGrammar source; }).overrideAttrs (
      _ignored:
      final.lib.optionalAttrs (source.name == "qmljs") {
        dontCheckForBrokenSymlinks = true;
      }
    );

  grammarLink =
    {
      name,
      ...
    }@source:
    "ln -s ${grammarArtifact source}/parser $out/${name}.so";

  grammarLinks = builtins.map grammarLink languages;

  grammars = final.runCommand "consolidated-helix-grammars" { } ''
    mkdir -p $out
    ${builtins.concatStringsSep "\n" grammarLinks}
  '';

  # Base package to override - use helix-unwrapped from nixpkgs
  basePkg = prev.helix-unwrapped;
in
gitOverride (current: {
  nyxKey = if evil then "evil-helix_git" else "helix_git";
  prev = basePkg;

  versionNyxPath = if evil then "pkgs/helix-git/version-evil.json" else "pkgs/helix-git/version.json";
  fetcher = "fetchFromGitHub";
  fetcherData =
    if evil then
      {
        owner = "usagi-flow";
        repo = "evil-helix";
      }
    else
      {
        owner = "helix-editor";
        repo = "helix";
      };
  ref = if evil then "main" else "master";

  withExtraUpdateCommands = final.writeShellScript "bump-grammars" ''
    _TMPDIR=$(mktemp -d)
    cp -r "$_LATEST_PATH/." "$_TMPDIR/"

    pushd "$_TMPDIR"
    ${
      if evil then
        "rm -f grammars.nix && ${final.wget}/bin/wget 'https://raw.githubusercontent.com/helix-editor/helix/refs/heads/master/grammars.nix'"
      else
        ""
    }
    ${final.patch}/bin/patch -p1 -i "$_NYX_DIR/$_PKG_DIR/grammars.patch"
    NIX_PATH="nixpkgs=${flakes.nixpkgs}:$NIX_PATH" \
      ${final.nix}/bin/nix eval --impure --write-to ./languages.json --expr 'with import <nixpkgs> { }; callPackage ./grammars.nix { }'
    ${final.jq}/bin/jq . < ./languages.json > "$_NYX_DIR/$_PKG_DIR/${languagesFile}"
    popd

    git add "$_PKG_DIR/${languagesFile}"
  '';

  postOverride = prevAttrs: {
    dontVersionCheck = true;
    nativeBuildInputs = (prevAttrs.nativeBuildInputs or basePkg.nativeBuildInputs or [ ]) ++ [
      final.makeBinaryWrapper
    ];
    # env is passed to cargo build - must disable auto grammar fetch at compile time
    env = (basePkg.env or { }) // {
      HELIX_NIX_BUILD_REV = current.rev;
      HELIX_DISABLE_AUTO_GRAMMAR_BUILD = "1";
    };
    postInstall = (basePkg.postInstall or "") + ''
      runtimeDir=$out/lib/runtime
      mkdir -p $runtimeDir

      # 1. Copy complete runtime files (themes, tutor, queries, etc.)
      cp -r --no-preserve=mode ${prevAttrs.src}/runtime/* $runtimeDir/

      # 2. Remove source grammar directory and link our pre-built grammars
      rm -rf $runtimeDir/grammars
      ln -s ${grammars} $runtimeDir/grammars

      # 3. Wrap binary with runtime path and disable auto grammar build at runtime
      wrapProgram $out/bin/hx \
        --set HELIX_RUNTIME "$runtimeDir" \
        --set HELIX_DISABLE_AUTO_GRAMMAR_BUILD "1"
    '';
    meta = if evil then final.evil-helix.meta else (prev.helix.meta or prevAttrs.meta or basePkg.meta);
  };

  extraPassthru = {
    grammars = builtins.listToAttrs (
      builtins.map (source: {
        inherit (source) name;
        value = grammarArtifact source;
      }) languages
    );
  };
})
