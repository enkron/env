{
  description = "Example of dev shells with different python versions";

  inputs = {
    #nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";

    # Latest commit hash with the poetry v1.7.1
    nixpkgs.url = "github:NixOS/nixpkgs/087f43a1fa052b17efd441001c4581813c34bc19";
  };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
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
            pkgs.poetry
          ];
        };
      };
    };
}
