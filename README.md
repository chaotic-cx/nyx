<h1>Chaotic's Nyx</h1>

<img alt="Six frogs with capes, aligned like the NixOS logo, with intercalated shades of green" src="https://gist.githubusercontent.com/PedroHLC/f6eaa9dfcf190e18b753e98fd265c8d3/raw/nix-frog-with-capes-web.svg" width="35%" /><br/>

<img alt="GitHub's menu buttons re-ordered and re-labeled to say: Make Pull requests Not Issues. Sounding like Make Love Not War" src="https://gist.githubusercontent.com/PedroHLC/eba5644666a1f2f007319d566ab77a83/raw/91c6064eb0d5cd1e19ac76a48acda87996f330f9/make-pr-not-issues.svg" width="330" height="49" /><br/>

<p>Nix flake for "too much bleeding-edge" and unreleased packages (e.g., mesa_git, linux_cachyos, firefox_nightly, sway_git, gamescope_git). And experimental modules (e.g., HDR, duckdns).</p>

<p>From the <a href="https://github.com/chaotic-cx">Chaotic Linux User Group (LUG)</a>, the same one that maintains <a href="https://aur.chaotic.cx">Chaotic-AUR</a>! 🧑🏻‍💻</p>

<p><strong>This is a fork of <a href="https://github.com/chaotic-cx/nyx">Chaotic-Nyx</a>.</strong> I use <a href="https://garnix.io">Garnix CI</a> to provide binary cache for selected packages. See <a href="https://lonerorz.github.io/nyx-loner/">the documentation page</a> for the list of cached packages and usage instructions.</p>

<p>I bump packages daily. However, I don't use many of the applications myself. If you encounter any issues, please open an issue and I'll try to fix them.</p>

<p>The official source-code repository is available <a href="https://github.com/chaotic-cx/nyx">as "chaotic-cx/nyx" at GitHub</a>.</p>

<strong>For issues related to this fork, please open an issue on <a href="https://github.com/lonerOrz/nyx-loner/issues">this repository's issues page</a>.</strong>

<ul>
  <li>
    <a href="#how-to-use-it">How to use it</a><br/>
    <ul>
      <li><a href="#on-nixos-unstable">On NixOS unstable</a></li>
      <li><a href="#on-nixos-stable">On NixOS stable</a></li>
      <li><a href="#on-home-manager">On Home-Manager</a></li>
      <li><a href="#running-packages-without-installing">Running packages (without installing)</a></li>
      <li><a href="#binary-cache-notes">Binary Cache notes</a></li>
      <li><a href="#using-sched-ext-schedulers">Using linux-cachyos with sched-ext</a></li>
      <li><a href="#using-with-read-only-pkgs">Using with read-only pkgs</a></li>
    </ul>
  </li>
  <li><a href="#lists-of-options-and-packages">Lists of options and packages</a></li>
  <li><a href="#notes">Notes</a></li>
  <li><a href="#criteria-for-new-packages">Criteria for new packages</a></li>
  <li><a href="#why-am-i-building-a-kernel-basic-cache-troubleshooting">Troubleshooting</a></li>
</ul>

<h2 id="how-to-use-it">How to use it</h2>

<h3 id="on-nixos-unstable">On NixOS unstable</h3>

<p>This tutorial does not apply for users using NixOS 24.11 and other stable channels. This tutorial is for unstable users.</p>

<p>We recommend integrating this repo using Flakes:</p>

<pre lang="nix"><code class="language-nix">
# flake.nix
{
  description = "My configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nyx-loner.url = "github:lonerOrz/nyx-loner"; # IMPORTANT
  };

  outputs = { nixpkgs, nyx-loner, ... }: {
    nixosConfigurations = {
      hostname = nixpkgs.lib.nixosSystem { # Replace "hostname" with your system's hostname
        system = "x86_64-linux";
        modules = [
          ./configuration.nix
          nyx-loner.nixosModules.default # IMPORTANT
        ];
      };
    };
  };
}
</code></pre>

<p>In your <code>configuration.nix</code> enable the kernel you want:</p>

<pre lang="nix"><code class="language-nix">
# configuration.nix
{ pkgs, ... }:
{
  boot.kernelPackages = pkgs.linuxPackages_cachyos-lto;
  # or: pkgs.linuxPackages_cachyos-gcc
}
</code></pre>

<h3 id="on-nixos-stable">On NixOS stable</h3>

<p>This tutorial is for NixOS stable versions (24.11, 25.05, etc.).</p>

<p>We recommend integrating this repo using Flakes:</p>

<pre lang="nix"><code class="language-nix">
# flake.nix
{
  description = "My configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    nyx-loner.url = "github:lonerOrz/nyx-loner"; # IMPORTANT
  };

  outputs = { nixpkgs, nyx-loner, ... }: {
    nixosConfigurations = {
      hostname = nixpkgs.lib.nixosSystem { # Replace "hostname" with your system's hostname
        system = "x86_64-linux";
        modules = [
          ./configuration.nix
          nyx-loner.nixosModules.default # IMPORTANT
        ];
      };
    };
  };
}
</code></pre>

<p>In your <code>configuration.nix</code> enable the packages that you want:</p>

<pre lang="nix"><code class="language-nix">
# configuration.nix
{ pkgs, ... }:
{
  boot.kernelPackages = pkgs.linuxPackages_cachyos-lto;
}
</code></pre>

<h3 id="on-home-manager">On Home-Manager</h3>

<p>This method is for home-manager setups <strong>without NixOS</strong>.</p>

<p>We recommend integrating this repo using Flakes:</p>

<pre lang="nix"><code class="language-nix">
# flake.nix
{
  description = "My configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nyx-loner.url = "github:lonerOrz/nyx-loner"; # IMPORTANT
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, nyx-loner, ... }: {
    homeConfigurations = {
      configName = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
        modules = [
          ./home-manager/default.nix
          nyx-loner.homeManagerModules.default # IMPORTANT
        ];
      };
    };
  };
}
</code></pre>

<p>In your <code>home-manager/default.nix</code> add a <code>nix.package</code>, and enable the desired packages:</p>

<pre lang="nix"><code class="language-nix">
{ pkgs, ... }:
{
  nix.package = pkgs.nix;
  home.packages = [ pkgs.linux_cachyos-lto ];
}
</code></pre>

<h3 id="running-packages-without-installing">Running packages (without installing)</h3>

<p>Besides using our module/overlay, you can run packages (without installing them) using:</p>

<pre lang="sh"><code class="language-sh">
nix run github:lonerOrz/nyx-loner#linux_cachyos-lto
</code></pre>

<h3 id="binary-cache-notes">Binary Cache notes</h3>

<p>This fork uses <a href="https://garnix.io">Garnix CI</a> to provide binary cache for selected packages.
The cache is automatically built and deployed for the following architectures:</p>

<ul>
  <li><code>x86_64-linux</code></li>
</ul>

<p>To use the cache, add the following to your <code>/etc/nix/nix.conf</code>:</p>

<pre lang="text"><code class="language-text">
extra-substituters = https://cache.garnix.io
extra-trusted-public-keys = cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g=
</code></pre>

<p>Or if you use flakes, the cache will be automatically available when you add this flake to your inputs and enable the overlay as described in the <a href="#how-to-use-it">How to use it</a> section.</p>

<p>For the list of cached packages and detailed usage instructions, see <a href="https://lonerorz.github.io/nyx-loner/">the documentation page</a>.</p>

<h3 id="using-sched-ext-schedulers">Using sched-ext schedulers</h3>

<p> From version 6.12 onwards, sched-ext support is officially available on the upstream kernel. You can use the latest kernel (<code>pkgs.linuxPackages_latest</code>) or our provided CachyOS kernel (<code>pkgs.linuxPackages_cachyos</code>). </p>

<p>Just add this to your configuration:</p>

<pre lang="nix"><code class="language-nix">
# configuration.nix
{
  boot.kernelPackages = pkgs.linuxPackages_cachyos;
  services.scx.enable = true; # by default uses scx_rustland scheduler
}
</code></pre>

<p> Then, reboot with the new configuration, check if the scheduler is running: </p>

<pre lang="text"><code class="language-text">
╰─λ systemctl status scx.service
</code></pre>

<p> If this is not working, check if the current kernel support <code>sched-ext</code> feature. </p>

<pre lang="text"><code class="language-text">
╰─λ ls /sys/kernel/sched_ext/
enable_seq  hotplug_seq  nr_rejected  root  state  switch_all
</code></pre>

<p> You can also manually start a scheduler like: </p>

<pre lang="text"><code class="language-text">
╰─λ sudo scx_rusty
21:38:53 [INFO] CPUs: online/possible = 24/32
21:38:53 [INFO] DOM[00] cpumask 00000000FF03F03F (20 cpus)
21:38:53 [INFO] DOM[01] cpumask 0000000000FC0FC0 (12 cpus)
21:38:53 [INFO] Rusty Scheduler Attached
</code></pre>

<p>You can choose a different scheduler too.</p>
<pre lang="nix"><code class="language-nix">
# configuration.nix
{
  services.scx.scheduler = "scx_rusty";
}
</code></pre>

<p> We also provide a git version of scx to stay up to date on the latest features. </p>

<pre lang="nix"><code class="language-nix">
# configuration.nix
{
  services.scx.package = pkgs.scx_git.full;
}
</code></pre>

<p>There are other scx_* binaries for you to play with, or head to <a href="https://github.com/sched-ext/scx" target="_blank">github.com/sched-ext/scx</a> for instructions on how to write one of your own.</p>

<h3 id="using-with-read-only-pkgs">Using with read-only pkgs</h3>

<h2 id="lists-of-options-and-packages">Lists of options and packages</h2>

<!-- cut here --><p>An always up-to-date list of all our options and packages is available at: <a href="https://lonerorz.github.io/nyx-loner/">the documentation page</a>.</p><!-- cut here -->

<h2 id="notes">Notes</h2>

<h3>Branches</h3>

<p><code>main</code> branch is the primary target for contribution.</p>

<h3>Upstream to nixpkgs</h3>

<p>If you are interested in pushing any of these packages to the upstream nixpkgs, you have our blessing.</p>

<h3>Suggestions</h3>

<p>If you have any suggestion to enhance our packages, modules, or even the CI's codes, let us know through the GitHub repo's issues.</p>

<h2 id="why-am-i-building-a-kernel-basic-cache-troubleshooting">Troubleshooting</h2>

<p>If you encounter any issues, please open an issue on <a href="https://github.com/lonerOrz/nyx-loner/issues">the issues page</a>.</p>

<h2 id="special-thanks">Special Thanks</h2>

<p>Special thanks to the original <a href="https://github.com/chaotic-cx/nyx">Chaotic-Nyx</a> project and its contributors.</p>
