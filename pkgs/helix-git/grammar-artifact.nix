{ makeGrammar, source }:

(makeGrammar {
  language = source.name;
  version = source.rev;
  src = builtins.fetchTree (
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
