{
  makeGrammar,
  source,
  fetchgit,
  fetchFromGitHub,
}:

let
  nixpkgsFetcher =
    {
      narHash,
      type,
      owner ? null,
      repo ? null,
      rev ? null,
      shallow ? true,
      url ? null,
      ref ? "HEAD",
    }:
    if !shallow then
      throw "Not shallow is unsupported"
    else if ref != "HEAD" then
      throw "Unsupported ref"
    else if type == "github" then
      fetchFromGitHub {
        inherit owner repo rev;
        hash = narHash;
      }
    else if type == "git" then
      fetchgit {
        inherit url rev;
        name = "source";
        hash = narHash;
      }
    else
      throw "Unsupported type";
in
(makeGrammar {
  language = source.name;
  version = source.rev;
  src = nixpkgsFetcher (
    builtins.removeAttrs source [
      "name"
      "lastModified"
      "lastModifiedDate"
      "subpath"
    ]
  );
  location = source.subpath;
}).overrideAttrs
  (_prevAttrs: {
    # qmljs-grammar has broken symlinks
    dontCheckForBrokenSymlinks = true;
  })
