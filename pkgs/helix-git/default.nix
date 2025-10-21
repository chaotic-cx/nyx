{
  evil ? false,
  final,
  prev,
  gitOverride,
  flakes,
  ...
}:

let
  makeGrammar =
    final.callPackage "${flakes.nixpkgs}/pkgs/development/tools/parsing/tree-sitter/grammar.nix"
      { };

  # An IFD-free implementation of https://github.com/helix-editor/helix/blob/9f3b193743e6150a1d376d8ddcfb70625b8e2409/grammars.nix
  languages = final.lib.trivial.importJSON (if evil then ./languages-evil.json else ./languages.json);
  languagesFile = if evil then "languages-evil.json" else "languages.json";

  grammarArtifact = source: final.callPackage ./grammar-artifact.nix { inherit makeGrammar source; };

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
in
gitOverride (current: {
  nyxKey = if evil then "evil-helix_git" else "helix_git";
  prev = prev.helix;

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
    env = prevAttrs.env // {
      HELIX_NIX_BUILD_REV = current.rev;
      HELIX_DISABLE_AUTO_GRAMMAR_BUILD = "1";
    };
    postInstall =
      (builtins.replaceStrings [ "runtime/grammars/sources" ] [ "runtime/grammars" ]
        prevAttrs.postInstall
      )
      + ''
        ln -s ${grammars} $out/lib/runtime/grammars
      '';
    meta = if evil then final.evil-helix.meta else prevAttrs.meta;
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
