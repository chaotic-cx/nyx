{ allPackages
, defaultModule
, nyxRecursionHelper
, lib
, nyxUtils
, system
, writeText
}:
let
  evalResult = k: v:
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
        <td>${k}</td>
        <td>${v.version or "-"}</td>
        <td>${description}<br/>${homepage}</td>
      </tr>
    '';

  warn = k: v: message:
    if message == "unfree" then evalResult k v
    else ''
      <tr>
        <td>${k}</td>
        <td>-</td>
        <td>${v._description or "(${message})"}</td>
      </tr>
    '';

  packagesEval = nyxRecursionHelper.evalLimited 1 warn evalResult allPackages;

  packagesEvalFlat =
    lib.lists.flatten packagesEval;

  loadedModule = lib.nixosSystem { modules = [ defaultModule ]; system = "x86_64-linux"; };

  chaoticOptions = loadedModule.options.chaotic;
in
writeText "chaotic-documented.html" ''
  <!DOCTYPE html><html>
  <head>
    <meta charset="UTF-8" />
    <title>Chaotic-Nyx - Nix flake for bleeding-edge and unreleased packages.</title>
    <link href="https://unpkg.com/gridjs/dist/theme/mermaid.min.css" rel="stylesheet" />
    <link rel="stylesheet" href="https://rsms.me/inter/inter.css">
    <style>
      .noscript-table { display: none; }
      :root { font-family: 'Inter', sans-serif; }
      @supports (font-variation-settings: normal) {
        :root { font-family: 'Inter var', sans-serif; }
      }
    </style>
    <noscript><style>.noscript-table { display: table; }</style></noscript>
  </head><body>
    <h1>Chaotic-Nyx</h1>
    <h2>Packages</h2>
    <table id="packages" class="noscript-table" border="1">
      <thead>
        <th>Name</th>
        <th>Version</th>
        <th>Description</th>
      </thead>
      <tbody>${lib.strings.concatStrings packagesEvalFlat}</tbody>
    </table>
    <div id="js-packages"></div>
    <script type="module">
      import {
        Grid,
        html
      } from "https://unpkg.com/gridjs?module";

      new Grid({
        from: document.getElementById("packages"),
        search: true,
        sort: true
      }).render(document.getElementById("js-packages"));
    </script>
  </body></html>
''
