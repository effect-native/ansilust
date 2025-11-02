{
  description = "ansilust - next-generation text art processing";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }: {
    packages = nixpkgs.lib.genAttrs 
      [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ] 
      (system:
        let pkgs = nixpkgs.legacyPackages.${system};
        in {
          default = pkgs.stdenv.mkDerivation {
            pname = "ansilust";
            version = "0.0.1";
            src = ./.;
            # TODO: Complete flake implementation with build phases (Phase 4)
            installPhase = ''
              echo "Nix flake - coming soon"
            '';
          };
        }
      );

    devShells = nixpkgs.lib.genAttrs
      [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ]
      (system:
        let pkgs = nixpkgs.legacyPackages.${system};
        in pkgs.mkShell {
          buildInputs = with pkgs; [
            zig
            nodejs
          ];
        }
      );
  };
}
