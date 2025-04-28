{
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
  languages = final.lib.trivial.importJSON ./languages.json;

  grammarLink =
    {
      name,
      rev,
      subpath,
      ...
    }@source:
    let
      artifact =
        (makeGrammar {
          language = name;
          version = rev;
          src = builtins.fetchTree (
            builtins.removeAttrs source [
              "name"
              "lastModified"
              "lastModifiedDate"
              "subpath"
            ]
          );
          location = subpath;
        }).overrideAttrs
          (_prevAttrs: {
            # qmljs-grammar has broken symlinks
            dontCheckForBrokenSymlinks = true;
          });
    in
    "ln -s ${artifact}/${name}.so $out/${name}.so";

  grammarLinks = builtins.map grammarLink languages;

  grammars = final.runCommand "consolidated-helix-grammars" { } ''
    mkdir -p $out
    ${builtins.concatStringsSep "\n" grammarLinks}
  '';
in
gitOverride (current: {
  nyxKey = "helix_git";
  prev = prev.helix;

  versionNyxPath = "pkgs/helix-git/version.json";
  fetcher = "fetchFromGitHub";
  fetcherData = {
    owner = "helix-editor";
    repo = "helix";
  };
  ref = "master";

  withExtraUpdateCommands = final.writeShellScript "bump-grammars" ''
    _TMPDIR=$(mktemp -d)
    cp -r "$_LATEST_PATH/." "$_TMPDIR/"

    pushd "$_TMPDIR"
    ${final.patch}/bin/patch -p1 -i "$_NYX_DIR/$_PKG_DIR/grammars.patch"
    ${final.nix}/bin/nix eval --impure --write-to ./languages.json --expr 'with import <nixpkgs> { }; callPackage ./grammars.nix { }'
    ${final.jq}/bin/jq . < ./languages.json > "$_NYX_DIR/$_PKG_DIR/languages.json"
    popd

    git add "$_PKG_DIR/languages.json"
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
  };
})
