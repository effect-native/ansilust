{
  description = "ansilust - next-generation text art processing";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }: 
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        version = "0.0.1";
        
        # Map Nix systems to release artifact names
        systemToReleaseArch = {
          "x86_64-linux" = "linux-x64-gnu";
          "aarch64-linux" = "linux-arm64-gnu";
          "x86_64-darwin" = "darwin-x64";
          "aarch64-darwin" = "darwin-arm64";
        };
        
        releaseArch = systemToReleaseArch.${system};
      in {
        packages = {
          default = pkgs.stdenv.mkDerivation {
            pname = "ansilust";
            inherit version;
            
            # Download pre-built binary from GitHub releases
            src = pkgs.fetchurl {
              url = "https://github.com/effect-native/ansilust/releases/download/v${version}/ansilust-${releaseArch}.tar.gz";
              # Placeholder checksum - will be updated by release script
              sha256 = "PLACEHOLDER_CHECKSUM_${releaseArch}";
            };
            
            # No build needed - we're using pre-compiled binaries
            phases = [ "unpackPhase" "installPhase" ];
            
            unpackPhase = ''
              mkdir -p $out/bin
              tar -xzf $src -C $out/bin --strip-components=1
            '';
            
            installPhase = ''
              # Binary should be in place from unpackPhase
              test -f $out/bin/ansilust || exit 1
              chmod +x $out/bin/ansilust
            '';
            
            meta = with pkgs.lib; {
              description = "Next-generation text art processing system";
              homepage = "https://github.com/effect-native/ansilust";
              license = licenses.mit;
              platforms = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
              mainProgram = "ansilust";
            };
          };
        };

        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            zig
            nodejs
            gnumake
            pkg-config
          ];
        };
      }
    );
}

