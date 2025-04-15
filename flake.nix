{
  description = "Example profiles with development shells (platform-independent)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";

    # Pinned to commit with poetry 1.7.1
    nixpkgs-poetry171.url = "github:NixOS/nixpkgs/087f43a1fa052b17efd441001c4581813c34bc19";

    # Pinned to commit with kubectl 1.30.1
    nixpkgs-kubectl130.url = "github:NixOS/nixpkgs/6eb01a67e1fc558644daed33eaeb937145e17696";
  };

  outputs = { self, nixpkgs, nixpkgs-poetry171, nixpkgs-kubectl130 }:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];

      eachSystem = systems: f:
        nixpkgs.lib.genAttrs systems (system:
          f {
            inherit system;
            pkgs = import nixpkgs { inherit system; };
            pkgs-poetry171 = import nixpkgs-poetry171 { inherit system; };
            pkgs-kubectl130 = import nixpkgs-kubectl130 { inherit system; };
          });
    in

    eachSystem supportedSystems ({ system, pkgs, pkgs-poetry171, pkgs-kubectl130 }: {
      devShells.${system}.python310 = pkgs.mkShell {
        nativeBuildInputs = [
          (pkgs.python310.withPackages (p: [
            p.pip
            p.setuptools
            p.virtualenv
            p.wheel
          ]))
          pkgs-poetry171.poetry
        ];
      };

      packages.${system} = {
        base = pkgs.buildEnv {
          name = "Basic toolset";
          paths = with pkgs; [
            bat
            ripgrep
          ] ++ [
            pkgs-kubectl130.kubectl
          ];
        };

        exp = pkgs.buildEnv {
          name = "Experimental toolset";
          paths = [ ];
        };
      };
    });
}
