{
  description = "Example of dev shells with different python versions";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
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
