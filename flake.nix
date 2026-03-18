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

        # This flake is a secondary distribution channel. Keep release metadata
        # unset until a published GitHub release provides evidence-backed values.
        release = {
          version = null;
          checksums = {
            "x86_64-linux" = null;
            "aarch64-linux" = null;
            "x86_64-darwin" = null;
            "aarch64-darwin" = null;
          };
        };
        
        # Map Nix systems to release artifact names
        systemToReleaseArch = {
          "x86_64-linux" = "linux-x64-gnu";
          "aarch64-linux" = "linux-arm64-gnu";
          "x86_64-darwin" = "darwin-x64";
          "aarch64-darwin" = "darwin-arm64";
        };
        
        releaseArch = systemToReleaseArch.${system};
        releaseVersion = release.version;
        releaseSha256 = release.checksums.${system};
        hasReleaseArtifact = releaseVersion != null and releaseSha256 != null;
      in {
        packages = {
          default = if hasReleaseArtifact then pkgs.stdenv.mkDerivation {
            pname = "ansilust";
            version = releaseVersion;

            src = pkgs.fetchurl {
              url = "https://github.com/effect-native/ansilust/releases/download/v${releaseVersion}/ansilust-${releaseArch}.tar.gz";
              sha256 = releaseSha256;
            };

            phases = [ "unpackPhase" "installPhase" ];

            unpackPhase = ''
              mkdir -p $out/bin
              tar -xzf $src -C $out/bin --strip-components=1
            '';

            installPhase = ''
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
          } else pkgs.runCommandNoCC "ansilust-release-metadata-unset" {} ''
            echo "ansilust flake packaging is aspirational until release version and checksums are recorded." >&2
            echo "Run ./scripts/update-nix-flake.sh <version> <sha256sums-file> after publishing release artifacts." >&2
            exit 1
          '';
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
