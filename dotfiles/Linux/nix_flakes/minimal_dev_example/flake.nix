{
  description = "Example of dev shells with different python versions";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    # last stable commit hash with python3.6 from nixos-21.05
    nixpkgs-python36.url = "github:NixOS/nixpkgs/903b8cc6f2045eadb0d7e58913447b0467a5d8a3";
    # last stable commit hash with python3.8 from nixos-24.05
    nixpkgs-python38.url = "github:NixOS/nixpkgs/5a83f6f984f387d47373f6f0c43b97a64e7755c0";
  };

  outputs = { self, nixpkgs, nixpkgs-python36, nixpkgs-python38 }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
      pkgs-python36 = import nixpkgs-python36 { inherit system; };
      pkgs-python38 = import nixpkgs-python38 { inherit system; };
    in {
      devShells.${system} = {
        python36 = pkgs.mkShell {
          nativeBuildInputs = [
            (pkgs-python36.python36.withPackages (p: [
              p.virtualenv
              p.pip
              p.setuptools
              p.wheel
            ]))
          ];
        };

        python38 = pkgs.mkShell {
          nativeBuildInputs = [
            (pkgs-python38.python38.withPackages (p: [
              p.virtualenv
              p.pip
              p.setuptools
              p.wheel
            ]))
          ];
        };

        python310 = pkgs.mkShell {
          nativeBuildInputs = [
            (pkgs.python310.withPackages (p: [
              p.virtualenv
              p.pip
              p.setuptools
              p.wheel
            ]))
          ];
        };
      };
    };
}
