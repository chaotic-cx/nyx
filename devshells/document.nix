{ allPackages
, homeManagerConfiguration
, homeManagerModule
, lib
, nixosModule
, nixosSystem
, nixpkgs
, nyxRecursionHelper
, pkgs
, self
, system
, writeText
}:
let
  derivationMap = k: v:
    let
      description =
        if (builtins.stringLength (v.meta.longDescription or "") > 0) then
          v.meta.longDescription
        else v.meta.description or "-";
      homepage =
        if (builtins.stringLength (v.meta.homepage or "") > 0) then
          "<a href=\"${v.meta.homepage}\" target=\"_blank\">${v.meta.homepage}</a>"
        else "";
    in
    ''
      <tr>
        <td><code>${k}</code></td>
        <td><code>${v.version or "-"}</code></td>
        <td>${description}<br/>${homepage}</td>
      </tr>
    '';

  derivationWarn = k: v: message:
    if message == "unfree" then derivationMap k v
    else if message == "not a derivation" && ((v._description or null) == null) then null
    else ''
      <tr>
        <td><code>${k}</code></td>
        <td><code>-</code></td>
        <td>${v._description or "(${message})"}</td>
      </tr>
    '';

  packagesEval = nyxRecursionHelper.derivationsLimited "explicit" derivationWarn derivationMap allPackages;

  packagesEvalFlat =
    lib.lists.remove null (lib.lists.flatten packagesEval);

  loadedNixOSModule = nixosSystem {
    modules = [ nixosModule ];
    system = "x86_64-linux";
  };
  loadedHomeManagerModule = homeManagerConfiguration {
    modules = [
      {
        nix.package = pkgs.nix;
        home = {
          stateVersion = "23.11";
          username = "player";
          homeDirectory = "/tmp";
        };
      }
      homeManagerModule
    ];
    inherit pkgs;
  };

  optionMap = k: v:
    let
      htmlify = builtins.replaceStrings [ "\n" " " ] [ "<br/>" "&nbsp;" ];
      prettify = src:
        htmlify (lib.generators.toPretty { multiline = true; } src);
      exampleValue =
        if (v.example or null) == null then ""
        else if (v.example._type or null) == "literalExpression"
        then htmlify v.example.text
        else prettify v.example;
      example =
        if (builtins.stringLength exampleValue > 0) then
          "<br/><b>Example:</b> <code>${exampleValue}</code><br/>"
        else "";
      typeDescription =
        if v.type.name == "enum" then
          "<br/><b>Enum:</b> <code>${v.type.description}</code><br/>"
        else "";
    in
    ''
      <tr>
        <td><code>chaotic.${k}</code></td>
        <td><code>${prettify v.default}</code></td>
        <td>${htmlify v.description}
          ${typeDescription}
          ${example}
        </td>
      </tr>
    '';

  optionWarn = k: _v: message:
    ''
      <tr>
        <td><code>chaotic.${k}</code></td>
        <td><code>-</code></td>
        <td>(${message})</td>
      </tr>
    '';

  nixosEval = nyxRecursionHelper.options optionWarn optionMap loadedNixOSModule.options.chaotic;

  nixosEvalFlat =
    lib.lists.flatten nixosEval;

  homeManagerEval = nyxRecursionHelper.options optionWarn optionMap loadedHomeManagerModule.options.chaotic;

  homeManagerEvalFlat =
    lib.lists.flatten homeManagerEval;

  tables = {
    t1-packages = {
      title = "Packages";
      headers = [ "Name" "Version" "Description" ];
      rows = packagesEvalFlat;
      overflow = false;
    };
    t2-nixos = {
      title = "NixOS Options";
      headers = [ "Key" "Default" "Description" ];
      rows = nixosEvalFlat;
    };
    t3-home-manager = {
      title = "Home-Manager Options";
      headers = [ "Key" "Default" "Description" ];
      rows = homeManagerEvalFlat;
    };
  };

  renderHeader = x: "<th>${x}</th>";
  renderHeaders = xs:
    lib.strings.concatStrings (lib.lists.map renderHeader xs);

  renderTable = id: { title, headers, rows, ... }: ''
    <h3 id="t-${id}">${title}</h2>
    <table id="${id}" class="noscript-table" border="1">
      <thead>${renderHeaders headers}</thead>
      <tbody>${lib.strings.concatStrings rows}</tbody>
    </table>
    <div id="js-${id}"></div>
  '';
  renderTables = xs:
    lib.strings.concatStrings (lib.attrsets.mapAttrsToList renderTable xs);

  renderGrid = id: { overflow ? false, ... }: ''
    new Grid({
      from: document.getElementById("${id}"),
      search: true,
      sort: true ${if overflow then
        ", style: { table: { 'overflow-wrap': 'break-word' } }"
      else ""}
    }).render(document.getElementById("js-${id}"));
  '';
  renderGrids = xs:
    lib.strings.concatStrings (lib.attrsets.mapAttrsToList renderGrid xs);

  renderIndexElem = id: { title, ... }:
    "<li><a href=\"#t-${id}\">${title}</a></li>";
  renderIndex = xs:
    lib.strings.concatStrings (lib.attrsets.mapAttrsToList renderIndexElem xs);

  readme =
    lib.strings.splitString "<!-- cut here -->" (builtins.readFile ../README.md);
in
writeText "chaotic-documented.html" ''
  <!DOCTYPE html><html style="font-size: 12px;">
  <head lang="en">
    <meta charset="UTF-8" />
    <title>Chaotic-Nyx</title>
    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">
    <meta name="description" property="og:description"
      content="Nix flake for bleeding-edge and unreleased packages." />
    <meta property="og:url" content="https://www.nyx.chaotic.cx" />
    <meta property="og:type" content="website" />
    <meta property="og:title" content="Chaotic-Nyx" />
    <meta property="og:image" content="https://gist.githubusercontent.com/PedroHLC/f6eaa9dfcf190e18b753e98fd265c8d3/raw/nix-frog-with-capes-web.svg" />
    <link rel="icon" href="https://avatars.githubusercontent.com/u/130499842?v=4" type="image/jpeg" />
    <link href="https://unpkg.com/gridjs/dist/theme/mermaid.min.css" rel="stylesheet" />
    <link rel="stylesheet" href="https://rsms.me/inter/inter.css">
    <style>
      .noscript-table { display: none; }
      :root { font-family: 'Inter', sans-serif; }
      @supports (font-variation-settings: normal) {
        :root { font-family: 'Inter var', sans-serif; }
      }
      body .gridjs-search, body .gridjs-search-input { width: 100%; }
      pre { overflow: auto; }
      img { max-width: 100%; }
    </style>
    <noscript><style>.noscript-table { display: table; }</style></noscript>
  </head><body><div style="max-width: 1100px; margin: 0 auto">
    ${builtins.head readme}
    <p>Built and cached against <a href="https://github.com/NixOS/nixpkgs/tree/${nixpkgs.rev}" target="_blank"><code>github:nixos/nixpkgs/${nixpkgs.rev}</code></a> from <code>${nixpkgs.lastModifiedDate}Z</code>.</p>
    <ul>${renderIndex tables}</ul>
    ${renderTables tables}
    ${lib.lists.last readme}
    <h2>About this page</h2>
    <p>Generated for <a href="https://github.com/chaotic-cx/nyx/tree/${self.rev or "nyxpkgs-unstable"}"><code>github:chaotic-cx/nyx/${self.rev or "nyxpkgs-unstable"}</code></a> from <code>${self.lastModifiedDate}Z</code>.</p>
    <script type="module">
      import {
        Grid,
        html
      } from "https://unpkg.com/gridjs?module";

      ${renderGrids tables}
    </script>
  </div></body></html>
''
