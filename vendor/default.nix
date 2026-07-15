let
  fetchFlake =
    {
      lock,
      ...
    }:
    builtins.getFlake (builtins.unsafeDiscardStringContext lock);

  forEachFlake =
    name: _directory_or_regular:
    fetchFlake (builtins.fromJSON (builtins.readFile ./flakes/${name}/version.json));
in
builtins.mapAttrs forEachFlake (builtins.readDir ./flakes)
