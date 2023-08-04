<h1>Chaotic's Nyx ❄️</h1>

<p>Flake-compatible Nixpkgs overlay for bleeding-edge and unreleased packages. The first child of chaos.</p>

<p>From the <a href="https://github.com/chaotic-cx">Chaotic Linux User Group (LUG)</a>, the same one that maintains <a href="https://github.com/chaotic-aur">Chaotic-AUR</a>! 🧑🏻‍💻</p>

<ul>
  <li><a href="#News">News</a></li>
  <li><a href="#How to use it">How to use it</a></li>
  <li><a href="#Lists of options and packages">Lists of options and packages</a></li>
  <li><a href="#Running packages">Running packages</a></li>
  <li><a href="#Notes">Notes</a></li>
  <li><a href="#Maintainence">Maintainence</a></li>
</ul>

<h2 id="News">News</h2>

<p>A news channel can be found <a href="https://t.me/s/chaotic_nyx">on Telegram</a>.</p>

<h2 id="How to use it">How to use it</h2>

<h3>NixOS</h3>

<p>We recommend integrating this repo using Flakes:</p>

<pre lang="nix"><code>
{
  description = "My configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";
  };

  outputs = { nixpkgs, chaotic, ... }: {
    nixosConfigurations = {
      hostname = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./configuration.nix # Your system configuration.
          chaotic.nixosModules.default # OUR DEFAULT MODULE
        ];
      };
    };
  };
}
</code></pre>

<p>In your <code>configuration.nix</code> enable the packages and options that you prefer:</p>

<pre lang="nix"><code>
{ pkgs, ... }:
{
  environment.systemPackages = [ pkgs.input-leap-git ];
  chaotic.mesa-git.enable = true;
}
</code></pre>

<h3>Home Manager</h3>

<p>We recommend integrating this repo using Flakes:</p>

<pre lang="nix"><code>
{
  description = "My configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, chaotic, ... }: {
    homeConfigurations = {
      hostname = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
        modules = [
          ./home-manager/default.nix
          chaotic.homeManagerModules.default # OUR DEFAULT MODULE
        ];
      };
    };
  };
}
</code></pre>

<p>In your <code>home-manager/default.nix</code> enable the packages:</p>

<pre lang="nix"><code>
{ pkgs, ... }:
{
  home.packages = [ pkgs.input-leap-git ];
}
</code></pre>

<h3>Binary Cache</h3>

<p>You'll get the binary cache added to your configuration as soon as you add our default module.
We do this automatically, so we can gracefully update the cache's address and keys without prompting you for manual work.</p>

<p>If you dislike this behavior for any reason, you can disable it with <code>chaotic.nyx.cache.enable = false</code>.</p>

<p><strong>Remember</strong>: If you want to fetch derivations from our cache, you'll need to enable our module and rebuild your system <strong>before</strong> adding these derivations to your configuration.</p>

<p>Commands like <code>nix run ...</code>, <code>nix develop ...</code>, and others, when using our flake as input, will ask you to add the cache interactively when missing from your user's nix settings.</p>

<h2 id="Lists of options and packages">Lists of options and packages</h2>

<!-- cut here --><p>An always up-to-date list of all our options and packages is available at: <a href="https://chaotic-cx.github.io/nyx/#Lists%20of%20options%20and%20packages">List page</a>.</p><!-- cut here -->

<h2 id="Running packages">Running packages</h2>

<p>Besides using our module/overlay, you can run packages (without installing them) using:</p>

<pre lang="sh"><code>
nix run github:chaotic-cx/nyx/nyxpkgs-unstable#yuzu-early-access_git
</code></pre>

<h2 id="Notes">Notes</h2>

<h3>Our branches</h3>

<p>:godmode: Our <code>nyxpkgs-unstable</code> branch is the one that's always cached.</p>

<p>:shipit: Sometimes the <code>main</code> branch is too, check it through this badge: <img alt="Cache Badge" src="https://github.com/chaotic-cx/nyx/actions/workflows/build.yml/badge.png"></p>

<h3>Contributions</h3>

<p>We do accept third-party authored PRs.</p>

<h3>Upstream to nixpkgs</h3>

<p>If you are interested in pushing any of these packages to the upstream nixpkgs, you have our blessing.</p>

<p>If one of our contributors is mentioned in the deveriation's mantainers list (in this repository) please keep it when pushing to nixpkgs. But, please, tag us on the PR so we can participate in the reviewing.</p>

<h3>Forks and partial code-taking</h3>

<p>You are free to use our code, or portions of our code, following the MIT license restrictions.</p>

<h3>Suggestions</h3>

<p>If you have any suggestion to enhance our packages, modules, or even the CI's codes, let us know through the GitHub repo's issues.</p>

<h4>Building over the user's pkgs</h4>

<p>For cache reasons, Chaotic-Nyx now defaults to always use nixpkgs as provider of its dependencies.</p>

<p>If you need to change this behavior, set <code>chaotic.nyx.onTopOf = "user-pkgs".</code>. Be warned that you mostly won't be able to benefit from our binary cache after this change.</p>

<p>You can also disable our overlay entirely by configuring <code>chaotic.nyx.overlay.enable</code>;</p>

<h2 id="Maintainence">Maintainence</h2>

<p>The code in the <code>devshells</code> directory is used to automate our CIs and maintainence processes.</p>

<h3>Build them all</h3>

<p>To build all the packages and push their cache usptream, use:</p>

<pre lang="sh"><code>
nix develop . -c build-chaotic-nyx
</code></pre>

<p>This commands will properly skip already-known failures, evaluation failures, building failures, and even skip any chain of failures caused by internal-dependecies. It will also avoid to download what it's already in our cache and in the upstream nixpkgs' cache.</p>

<p>A list of what successfully built, failed to build, hashes of all failures, paths to push to cache and logs will be available at the <code>/tmp/nix-shell.*/tmp.*/</code> directory. This directory can be specified with the <code>NYX_WD</code> envvar.</p>

<h3>Check for evaluation differerences</h3>

<p>You can compare a branch with another like this:</p>

<pre lang="bash"><code>
machine=$(uname -m)-linux
A='github:chaotic-cx/nyx/branch-a'
B='github:chaotic-cx/nyx/branch-b'

nix build --impure --expr \
  "(builtins.getFlake \"$A\").devShells.$machine.comparer.passthru.any \"$B\""
</code></pre>

<p>After running, you'll find all the derivations that changed in the <code>result</code> file.</p>

<h4>Known failures</h4>

<p>All the hashes that are known to produce build-time failures are kept in <code>devshells/failures.nix</code>.</p>

<p>Our builder produces a <code>new-failures.nix</code> that must be used to update this file in every PR.</p>

<h4>Banished and rejected packages</h4>

<p>There are none (so far).</p>
