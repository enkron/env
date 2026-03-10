{
  description = "Default profiles with the development shell";

  inputs = {
    #nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05"; # Stable channel
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable"; # Nightly channel

    # Pinned to the commit where poetry v1.7.1 is available
    nixpkgs-poetry171.url = "github:NixOS/nixpkgs/087f43a1fa052b17efd441001c4581813c34bc19";

    # In order for python310 package to work correctly `sphinx` dependency must be < 8.2.3 version
    # (this version doesn't support python3.10). Therefore pinning nixpkgs url to the previous hash
    nixpkgs-sphinx747.url = "github:NixOS/nixpkgs/a684c58d46ebbede49f280b653b9e56100aa3877";
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-poetry171,
      nixpkgs-sphinx747,
    }:
    let
      # Use the standard set of platforms that flakes expose by default.
      # lib.systems.flakeExposed keeps outputs consistent across common systems
      # without hardcoding a manual list.
      systems = nixpkgs.lib.systems.flakeExposed;
      forAllSystems = f: nixpkgs.lib.genAttrs systems f;

      # Provide a default dev shell and avoid PATH/PYTHONPATH shims.
      # Best practice: use `packages` with an explicit Python 3.10 derivation so
      # `python` resolves predictably without a shellHook.
      devShellsFor =
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          poetryPkgs = nixpkgs-poetry171.legacyPackages.${system};
          sphinxPkgs = nixpkgs-sphinx747.legacyPackages.${system};
          py310 = sphinxPkgs.python310;
        in
        {
          default = pkgs.mkShell {
            packages = with pkgs; [
              (py310.withPackages (p: [
                p.pip
                p.setuptools
                p.virtualenv
                p.wheel
              ]))
              ruff
              poetryPkgs.poetry
            ];
          };
        };

      sysPkgs =
        system:
        let
          # Allow packages with non-free licensing scheme
          pkgs = import nixpkgs {
            system = system;
            config.allowUnfree = true;
            overlays = [
              (_final: prev: {
                # libc++ 20 rejects function-reference deleters in this code path.
                newsboat = prev.newsboat.overrideAttrs (old: {
                  postPatch =
                    (old.postPatch or "")
                    + prev.lib.optionalString prev.stdenv.hostPlatform.isDarwin ''
                      substituteInPlace src/ocnewsapi.cpp \
                        --replace-fail 'decltype(*json_object_put)' 'decltype(&json_object_put)'
                    '';
                });
              })
            ];
          };
        in
        {
          enk-coreutils = pkgs.buildEnv {
            name = "Personal toolbox";
            paths =
              with pkgs;
              [
                awscli2
                bat
                btop
                cdrtools
                cilium-cli
                claude-code
                codex
                delta
                dust
                fd
                fzf
                git-lfs
                gnupg
                go
                gofumpt
                gopls
                groovy
                hubble
                jujutsu
                k9s
                kubectl
                kubernetes-helm
                newsboat
                nmap
                nodejs_24
                podman
                qemu
                ripgrep
                rumdl
                rustup
                sd
                socat
                terraform
                terraform-ls
                tmux
                yq-go
                zig
                zls
                zstd
              ]
              ++ pkgs.lib.optionals (system == "aarch64-darwin") [
                container
              ];
          };

          enk-coreutils-dev = pkgs.buildEnv {
            name = "Experemental and/or temporary toolchains";
            paths = with pkgs; [
              chafa
            ];
          };
        };
    in
    {
      # Enter with `nix develop` (defaults to the `default` shell).
      devShells = forAllSystems devShellsFor;
      packages = forAllSystems sysPkgs;

      # Formatter used by `nix fmt`.
      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt-tree);

      # Lightweight checks suitable for CI: ensure bootstrap script parses.
      checks = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          bootstrap-sh-syntax = pkgs.runCommand "bootstrap-sh-syntax" { } ''
            set -euo pipefail
            sh -n ${self}/dotfiles/bootstrap.sh >/dev/null
            mkdir -p "$out"
            touch "$out"/passed
          '';
        }
      );
    };
}
