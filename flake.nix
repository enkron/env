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

  outputs = { self, nixpkgs, nixpkgs-poetry171, nixpkgs-kubectl132, nixpkgs-sphinx747 }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin" ];
      forAllSystems = f: nixpkgs.lib.genAttrs (systems) f;


      # pkgs = forAllSystems(system: import nixpkgs { inherit system; });
      # # Pinned packages repository to the poetry v1.7.1
      # pkgs-poetry171 = forAllSystems(system: import nixpkgs-poetry171 { inherit system; });
      # # Pinned packages repository to the kubectl v1.30.1
      # pkgs-kubectl130 = forAllSystems(system: import nixpkgs-kubectl132 { inherit system; });

      devShell = system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          poetryPkgs = nixpkgs-poetry171.legacyPackages.${system};
          sphinxPkgs = nixpkgs-sphinx747.legacyPackages.${system};
        in {
          work = pkgs.mkShell {
            nativeBuildInputs = with pkgs; [
              ruff
              poetryPkgs.poetry
              (sphinxPkgs.python310.withPackages (p: [
                p.pip
                p.setuptools
                p.virtualenv
                p.wheel
              ]))
            ];

            # ruff & poetry dependencies are pulled from the 'pkgs' where they built with the default
            # python version (which is currently 3.12 on macOS nixpkgs).
            # When the dev shell is built it's pointing to the latest python interpreter, we want the
            # default python version set to 3.10 (by the project requirements) thus apply the shell hook
            # to set the PATH to the needed version.
            shellHook = ''
              export PATH=${sphinxPkgs.python310}/bin:$PATH
              export PYTHONPATH=${sphinxPkgs.python310}/lib/python3.10/site-packages:$PYTHONPATH
            '';
          };
        };

      sysPkgs = system:
        let
          # Allow packages with non-free licensing scheme
          pkgs = import nixpkgs { system = system; config.allowUnfree = true;  };
          kubectlPkgs =
            if pkgs.stdenv.isDarwin then
              nixpkgs-kubectl132.legacyPackages.${system}
            else
              nixpkgs-kubectl132.legacyPackages.${system};
        in {
          base = pkgs.buildEnv {
            name = "Basic toolset";
            paths = with pkgs; [
              bat
              delta
              fzf
              kubectl
              kubernetes-helm
              nmap
              ripgrep
              terraform
              tmux
              zig
            ];
          };

          work = pkgs.buildEnv {
            name = "Work toolset";
            paths = with pkgs; [
              awscli2
              bat
              delta
              fzf
              git-lfs
              groovy
              kubernetes-helm
              nmap
              podman
              ripgrep
              terraform
              tmux
              zig
            ] ++ [
              kubectlPkgs.kubectl
            ];
          };
        };
    in {
      devShells = forAllSystems devShell;
      packages = forAllSystems sysPkgs;
    };
}
