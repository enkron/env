{
  description = "Example profiles with the development shells";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    # Pinned to the commit where poetry v1.7.1 is available
    nixpkgs-poetry171.url = "github:NixOS/nixpkgs/087f43a1fa052b17efd441001c4581813c34bc19";
    # Pinned to the commit where kubectl v1.30.1 is available
    nixpkgs-kubectl130.url = "github:NixOS/nixpkgs/6eb01a67e1fc558644daed33eaeb937145e17696";
  };

  outputs = { self, nixpkgs, nixpkgs-poetry171, nixpkgs-kubectl130 }:
    let
      system = "x86_64-linux";

      # Standard packages repository for the python 3.10 and other tools
      pkgs = import nixpkgs { inherit system; };
      # Pinned packages repository to the poetry v1.7.1
      pkgs-poetry171 = import nixpkgs-poetry171 { inherit system; };
      # Pinned packages repository to the kubectl v1.30.1
      pkgs-kubectl130 = import nixpkgs-kubectl130 { inherit system; };
    in {
      devShells.${system} = {
        python310 = pkgs.mkShell {
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
          paths = with pkgs; [
            # Other experimental tools
          ];
        };
      };
    };
}
