{
  description = "Default profiles with the development shell";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";

    # Pinned to the commit where poetry v1.7.1 is available
    nixpkgs-poetry171.url = "github:NixOS/nixpkgs/087f43a1fa052b17efd441001c4581813c34bc19";

    # Pinned to the commit where kubectl v1.30.1 is available
    nixpkgs-kubectl132.url = "github:NixOS/nixpkgs/f8918a1e3ea5e5549b2c78996842c6c3b47da2a8";

    # In order for python310 package to work correctly `sphinx` dependency must be < 8.2.3 version
    # (this version doesn't support python3.10). Therefore pinning nixpkgs url to the previous hash
    nixpkgs-sphinx747.url = "github:NixOS/nixpkgs/a684c58d46ebbede49f280b653b9e56100aa3877";
  };

  outputs = {
    self,
    nixpkgs,
    nixpkgs-poetry171,
    nixpkgs-kubectl132,
    nixpkgs-sphinx747,
  }: let
    # Use the standard set of platforms that flakes expose by default.
    # lib.systems.flakeExposed keeps outputs consistent across common systems
    # without hardcoding a manual list.
    systems = nixpkgs.lib.systems.flakeExposed;
    forAllSystems = f: nixpkgs.lib.genAttrs systems f;

    # pkgs = forAllSystems(system: import nixpkgs { inherit system; });
    # # Pinned packages repository to the poetry v1.7.1
    # pkgs-poetry171 = forAllSystems(system: import nixpkgs-poetry171 { inherit system; });
    # # Pinned packages repository to the kubectl v1.30.1
    # pkgs-kubectl130 = forAllSystems(system: import nixpkgs-kubectl132 { inherit system; });

    # Provide a default dev shell and avoid PATH/PYTHONPATH shims.
    # Best practice: use `packages` with an explicit Python 3.10 derivation so
    # `python` resolves predictably without a shellHook.
    devShellsFor = system: let
      pkgs = nixpkgs.legacyPackages.${system};
      poetryPkgs = nixpkgs-poetry171.legacyPackages.${system};
      sphinxPkgs = nixpkgs-sphinx747.legacyPackages.${system};
      py310 = sphinxPkgs.python310;
    in {
      default = pkgs.mkShell {
        packages = with pkgs; [
          (py310.withPackages (p: [p.pip p.setuptools p.virtualenv p.wheel]))
          ruff
          poetryPkgs.poetry
        ];
      };
    };

    sysPkgs = system: let
      # Allow packages with non-free licensing scheme
      pkgs = import nixpkgs {
        system = system;
        config.allowUnfree = true;
      };

      # Pin kubectl to a specific nixpkgs revision and use it consistently
      # across all systems to avoid cross-platform hash drift.
      kubectlPkgs = nixpkgs-kubectl132.legacyPackages.${system};
    in {
      base = pkgs.buildEnv {
        name = "Basic toolset";
        paths =
          (with pkgs; [
            bat
            delta
            fzf
            kubernetes-helm
            nmap
            nodejs_24
            ripgrep
            terraform
            tmux
            zig
          ])
          ++ [kubectlPkgs.kubectl];
      };

      work = pkgs.buildEnv {
        name = "Work toolset";
        paths = with pkgs;
          [
            #codex
            awscli2
            bat
            delta
            fd
            fzf
            git-lfs
            groovy
            kubernetes-helm
            nmap
            nodejs_24
            podman
            ripgrep
            terraform
            tmux
            zig
            zstd
          ]
          ++ [
            kubectlPkgs.kubectl
          ];
      };
    };
  in {
    # Enter with `nix develop` (defaults to the `default` shell).
    devShells = forAllSystems devShellsFor;
    packages = forAllSystems sysPkgs;

    # Formatter used by `nix fmt`.
    formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.alejandra);

    # Lightweight checks suitable for CI: ensure bootstrap script parses.
    checks = forAllSystems (
      system: let
        pkgs = nixpkgs.legacyPackages.${system};
      in {
        bootstrap-sh-syntax = pkgs.runCommand "bootstrap-sh-syntax" {} ''
          set -euo pipefail
          sh -n ${self}/dotfiles/bootstrap.sh >/dev/null
          mkdir -p "$out"
          touch "$out"/passed
        '';
      }
    );
  };
}
