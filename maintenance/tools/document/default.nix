{
  allPackages,
  homeManagerConfiguration,
  homeManagerModule,
  lib,
  nixpkgs,
  nyxosConfiguration,
  nyxRecursionHelper,
  pkgs,
  self,
  writeText,
}:
let
  # Parse cached package names from garnix.yaml (only uncommented lines)
  garnixConfig = builtins.readFile ../../../garnix.yaml;
  garnixIncludes =
    let
      lines = lib.strings.splitString "\n" garnixConfig;
      # Filter: must start with "    - \"" and not be commented (not start with "#")
      activeIncludeLines = lib.lists.filter
        (line: lib.strings.hasPrefix "    - \"" line && !(lib.strings.hasPrefix "    #" line))
        lines;
      extractName = line:
        let
          matched = builtins.match ".*\"packages\\.[^\"]+\\.([^\"]+)\"" line;
        in
        if matched != null then builtins.head matched else null;
    in
    lib.lists.filter (name: name != null) (map extractName activeIncludeLines);

  derivationMap =
    k: v:
    let
      description = v.meta.description or "-";
      homepage =
        if (builtins.stringLength (v.meta.homepage or "") > 0) then
          "<a href=\"${v.meta.homepage}\" target=\"_blank\">${v.meta.homepage}</a>"
        else
          "";
    in
    ''
      <tr>
        <td><code>${k}</code></td>
        <td><code>${v.version or "-"}</code></td>
        <td>${description}<br/>${homepage}</td>
      </tr>
    '';

  derivationWarn =
    k: v: message:
    if message == "unfree" then
      derivationMap k v
    else if message == "not a derivation" && ((v._description or null) == null) then
      null
    else if message == "eval broken" then
      null
    else
      ''
        <tr>
          <td><code>${k}</code></td>
          <td><code>${v._version or "-"}</code></td>
          <td>${v._description or "(${message})"}</td>
        </tr>
      '';

  packagesEval =
    nyxRecursionHelper.derivationsLimited "explicit" derivationWarn derivationMap
      allPackages;

  packagesEvalFlat = lib.lists.remove null (lib.lists.flatten packagesEval);

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

  optionMap =
    k: v:
    let
      htmlify = builtins.replaceStrings [ "\n" " " ] [ "<br/>" "&nbsp;" ];
      prettify = src: htmlify (lib.options.renderOptionValue src).text;
      exampleValue = if v ? example then prettify v.example else "";
      example =
        if (builtins.stringLength exampleValue > 0) then
          "<br/><b>Example:</b> <code>${exampleValue}</code><br/>"
        else
          "";
      typeDescription =
        if v.type.name == "enum" then "<br/><b>Enum:</b> <code>${v.type.description}</code><br/>" else "";
      prettyDefault =
        if v ? defaultText then
          prettify v.defaultText
        else if v ? default then
          prettify v.default
        else
          "N/A";
    in
    if (v.visible or true) then
      ''
        <tr>
          <td><code>chaotic.${k}</code></td>
          <td><code>${prettyDefault}</code></td>
          <td>${htmlify v.description}
            ${typeDescription}
            ${example}
          </td>
        </tr>
      ''
    else
      ''
        <!-- INVISIBLE OPTION chaotic.${k} -->
      '';

  optionWarn = k: _v: message: ''
    <tr>
      <td><code>chaotic.${k}</code></td>
      <td><code>-</code></td>
      <td>(${message})</td>
    </tr>
  '';

  nixosEval = nyxRecursionHelper.options optionWarn optionMap nyxosConfiguration.options.chaotic;

  nixosEvalFlat = lib.lists.flatten nixosEval;

  homeManagerEval =
    nyxRecursionHelper.options optionWarn optionMap
      loadedHomeManagerModule.options.chaotic;

  homeManagerEvalFlat = lib.lists.flatten homeManagerEval;

  # Generate cached packages table rows from garnix.yaml
  getCachedPackage = name:
    if allPackages ? ${name} then
      let
        pkg = allPackages.${name};
        description = pkg.meta.description or "-";
        homepage =
          if (builtins.stringLength (pkg.meta.homepage or "") > 0) then
            "<a href=\"${pkg.meta.homepage}\" target=\"_blank\">${pkg.meta.homepage}</a>"
          else
            "";
      in
      ''
        <tr>
          <td><code>${name}</code></td>
          <td><code>${pkg.version or "-"}</code></td>
          <td>${description}<br/>${homepage}</td>
        </tr>
      ''
    else
      "";

  cachedPackagesRows = map getCachedPackage garnixIncludes;

  tables = {
    t0-cached-packages = {
      title = "Cached Packages";
      headers = [
        "Name"
        "Version"
        "Description"
      ];
      rows = cachedPackagesRows;
      overflow = false;
    };
    t1-packages = {
      title = "All Packages (Reference)";
      headers = [
        "Name"
        "Version"
        "Description"
      ];
      rows = packagesEvalFlat;
      overflow = false;
    };
    t2-nixos = {
      title = "NixOS Options";
      headers = [
        "Key"
        "Default"
        "Description"
      ];
      rows = nixosEvalFlat;
    };
    t3-home-manager = {
      title = "Home-Manager Options";
      headers = [
        "Key"
        "Default"
        "Description"
      ];
      rows = homeManagerEvalFlat;
    };
  };

  renderHeader = x: "<th>${x}</th>";
  renderHeaders = xs: lib.strings.concatStrings (lib.lists.map renderHeader xs);

  renderTable =
    id:
    {
      title,
      headers,
      rows,
      ...
    }:
    ''
      <h3 id="t-${id}">${title}</h2>
      <table id="${id}" class="noscript-table" border="1">
        <thead>${renderHeaders headers}</thead>
        <tbody>${lib.strings.concatStrings rows}</tbody>
      </table>
      <div id="js-${id}"></div>
    '';
  renderTables = xs: lib.strings.concatStrings (lib.attrsets.mapAttrsToList renderTable xs);

  renderGrid =
    id:
    {
      overflow ? false,
      ...
    }:
    ''
      renderGrid("${id}", "js-${id}", ${if overflow then "true" else "false"});
    '';
  renderGrids = xs: lib.strings.concatStrings (lib.attrsets.mapAttrsToList renderGrid xs);

  renderIndexElem = id: { title, ... }: "<li><a href=\"#t-${id}\">${title}</a></li>";
  renderIndex = xs: lib.strings.concatStrings (lib.attrsets.mapAttrsToList renderIndexElem xs);

  readme = lib.strings.splitString "<!-- cut here -->" (builtins.readFile ../../../README.md);

  getVersion =
    flake:
    if flake ? revCount then
      "version <code>0.1.${toString flake.revCount}</code>"
    else if flake ? lastModifiedDate then
      "<code>${flake.lastModifiedDate}Z</code>"
    else
      "bad rev";
in
writeText "chaotic-documented.html" ''
  <!DOCTYPE html><html>
  <head lang="en">
    <meta charset="UTF-8" />
    <title>Nyx Loner - CachyOS Kernel Cache</title>
    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">
    <meta name="description" property="og:description"
      content="A minimal fork of Chaotic-Nyx, providing pre-built CachyOS kernel packages via Garnix CI." />
    <meta property="og:url" content="https://github.com/lonerOrz/nyx-loner" />
    <meta property="og:type" content="website" />
    <meta property="og:title" content="Nyx Loner" />
    <link rel="icon" href="https://avatars.githubusercontent.com/u/130499842?v=4" type="image/jpeg" />
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/gridjs@6.2.0/dist/theme/mermaid.min.css" />
    <link rel="stylesheet" href="https://lab.pedrohlc.com/bucket/gridjs-mermaid-auto.css" />
    <link rel="stylesheet" href="https://rsms.me/inter/inter.css">
    <link rel="stylesheet" media="(prefers-color-scheme: light), (prefers-color-scheme: no-preference)" href="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/styles/github.min.css">
    <link rel="stylesheet" media="(prefers-color-scheme: dark)" href="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/styles/github-dark.min.css">
    <style>
      :root { font-family: 'Inter', sans-serif; font-size: 8px; }
      @media only screen and (min-width: 1280px) {
        :root { font-size: 0.625vw; }
      }
      @supports (font-variation-settings: normal) {
        :root { font-family: 'Inter var', sans-serif; }
      }
      body { font-size: 1.5rem; }
      @media (prefers-color-scheme: dark) {
        body { background-color: #151522; color: white; }
        a { color: #ffff10; }
        a:visited { color: #5bc629; }
        body .gridjs-search, body .gridjs-search-input { color: white; }
      }
      body .gridjs-search, body .gridjs-search-input { width: 100%; font-size: 1.5rem; }
      pre { overflow: auto; }
      img { max-width: 100%; }
      :not(pre) > code { color: #8a2be2; }
    </style>
  </head><body><div style="max-width: 140rem; margin: 0 auto">
    ${builtins.head readme}
    <p>Built with Garnix CI against <a href="https://github.com/NixOS/nixpkgs/tree/${nixpkgs.rev}" target="_blank"><code>github:nixos/nixpkgs/${nixpkgs.rev}</code></a> (${getVersion nixpkgs}).</p>
    <ul>${renderIndex tables}</ul>
    ${renderTables tables}
    ${lib.lists.last readme}
    <h2>About this page</h2>
    <p>Generated for <a href="https://github.com/lonerOrz/nyx-loner/tree/${self.rev or "main"}"><code>github:lonerOrz/nyx-loner/${self.rev or "main"}</code></a> from (${getVersion self}).</p>
    <script type="module">
      import {
        Grid,
        html
      } from "https://cdn.jsdelivr.net/npm/gridjs@6.2.0/+esm";

      function renderGrid(originalId, newId, overflow) {
        const from = document.getElementById(originalId);
        const to = document.getElementById(newId);
        return new Grid({
          from,
          search: true,
          sort: true,
          style: (overflow ? { table: { 'overflow-wrap': 'break-word' } } : { })
        }).render(to);
      }

      ${renderGrids tables}
    </script>
    <script type="module">
      import hljs from 'https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/es/highlight.min.js';
      import nix from 'https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/es/languages/nix.min.js';
      import bash from 'https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/es/languages/bash.min.js';
      import plaintext from 'https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/es/languages/plaintext.min.js';

      hljs.registerLanguage('nix', nix);
      hljs.registerLanguage('bash', bash);
      hljs.registerLanguage('sh', bash);
      hljs.registerLanguage('text', plaintext);
      hljs.highlightAll();
    </script>
  </div></body></html>
''
