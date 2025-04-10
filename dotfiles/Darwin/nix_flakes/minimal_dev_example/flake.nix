{
  description = "Minimal dev environment";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";

  outputs = { self, nixpkgs }:
    let
      system = "aarch64-darwin"; # Or "x86_64-darwin"
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
    };
}
