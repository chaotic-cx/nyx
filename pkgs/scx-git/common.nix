{ lib, fetchFromGitHub, }:
let
  versionInfo = lib.importJSON ./version.json;
in
{
  inherit (versionInfo.scx) version cargoHash;

  src = fetchFromGitHub {
    owner = "sched-ext";
    repo = "scx";
    inherit (versionInfo.scx) rev hash;
    fetchSubmodules = true;
  };

  patches = [

  ];

  # grep 'bpftool_commit =' ./meson.build
  bpftools_src = fetchFromGitHub {
    owner = "libbpf";
    repo = "bpftool";
    inherit (versionInfo.bpftool) rev hash;
    fetchSubmodules = true;
  };
  # grep 'libbpf_commit = ' ./meson.build
  libbpf_src = fetchFromGitHub {
    owner = "libbpf";
    repo = "libbpf";
    inherit (versionInfo.libbpf) rev hash;
    fetchSubmodules = true;
  };
}
