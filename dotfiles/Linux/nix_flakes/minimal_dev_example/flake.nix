{
  description = "Example of dev shells with different python versions";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";

    # Pinned to the commit where poetry v1.7.1 is available
    nixpkgs-poetry171.url = "github:NixOS/nixpkgs/087f43a1fa052b17efd441001c4581813c34bc19";
  };

  outputs = { self, nixpkgs, nixpkgs-poetry171 }:
    let
      system = "x86_64-linux";

      # Standard packages repository for the python 3.10 and other tools
      pkgs = import nixpkgs { inherit system; };

      # Pinned packages repository to the poetry v1.7.1
      pkgs-poetry171 = import nixpkgs-poetry171 { inherit system; };
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

      packages.${system}.default = pkgs.buildEnv {
        name = "Basic toolset";
        paths = with pkgs; [
          bat
        ];
      };
    };
}
