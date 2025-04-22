{
  description = "Default profiles with the development shell";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    # Pinned to the commit where poetry v1.7.1 is available
    nixpkgs-poetry171.url = "github:NixOS/nixpkgs/087f43a1fa052b17efd441001c4581813c34bc19";
    # Pinned to the commit where kubectl v1.30.1 is available
    nixpkgs-kubectl130-linux.url = "github:NixOS/nixpkgs/6eb01a67e1fc558644daed33eaeb937145e17696";
    nixpkgs-kubectl130-darwin.url = "github:NixOS/nixpkgs/cca4f8e59e9479ced4f02f33530be367220d5826";
  };

  outputs = { self, nixpkgs, nixpkgs-poetry171, nixpkgs-kubectl130-linux, nixpkgs-kubectl130-darwin }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin" ];
      forAllSystems = f: nixpkgs.lib.genAttrs (systems) f;


      # pkgs = forAllSystems(system: import nixpkgs { inherit system; });
      # # Pinned packages repository to the poetry v1.7.1
      # pkgs-poetry171 = forAllSystems(system: import nixpkgs-poetry171 { inherit system; });
      # # Pinned packages repository to the kubectl v1.30.1
      # pkgs-kubectl130 = forAllSystems(system: import nixpkgs-kubectl130-linux { inherit system; });

      devShell = system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          poetryPkgs = nixpkgs-poetry171.legacyPackages.${system};
        in {
          work = pkgs.mkShell {
            nativeBuildInputs = [
              (pkgs.python310.withPackages (p: [
                p.pip
                p.setuptools
                p.virtualenv
                p.wheel
              ]))
              poetryPkgs.poetry
            ];
          };
        };

      sysPkgs = system:
        let
          # Allow packages with non-free licencing scheme
          pkgs = import nixpkgs { system = system; config.allowUnfree = true;  };
          kubectlPkgs =
            if pkgs.stdenv.isDarwin then
              nixpkgs-kubectl130-darwin.legacyPackages.${system}
            else
              nixpkgs-kubectl130-linux.legacyPackages.${system};
        in {
          base = pkgs.buildEnv {
            name = "Basic toolset";
            paths = with pkgs; [
              bat
              delta
              fzf
              kubectl
              ripgrep
              #terraform
              tmux
            ];
          };

          work = pkgs.buildEnv {
            name = "Work toolset";
            paths = with pkgs; [
              bat
              delta
              fzf
              ripgrep
              #terraform
              tmux
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
