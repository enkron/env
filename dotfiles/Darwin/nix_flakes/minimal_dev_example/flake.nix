{
  description = "Minimal dev environment";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";

  outputs = { self, nixpkgs }:
    let
      system = "aarch64-darwin";
      pkgs = import nixpkgs { inherit system; };
    in {
      devShells.${system}.default = pkgs.mkShell {
        buildInputs = with pkgs; [
          git
          neovim
          ripgrep
          starship
        ];
      };

      packages.${system}.default = pkgs.buildEnv {
        name = "dev-tools";
        paths = with pkgs; [
          git
          neovim
          ripgrep
          starship
        ];
      };
    };
}
