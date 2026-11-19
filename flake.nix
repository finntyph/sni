{
  description = "SNI - Super Nintendo Interface (gRPC API for SNES devices)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        inherit (pkgs) lib stdenv;

        sni = pkgs.buildGoModule {
          pname = "sni";
          version = self.shortRev or self.dirtyShortRev or "unstable";
          src = self;

          # Run `nix build` once, then replace with the hash from the error.
          vendorHash = "sha256-o4CShxZ8HUL2zcIEcdhr7xTjuVUIPj86zyRTYgsC6dc=";

          subPackages = [ "cmd/sni" ];

          # If the build fails on Linux with missing gtk/appindicator headers,
          # add: nativeBuildInputs = [ pkgs.pkg-config ];
          #      buildInputs = [ pkgs.gtk3 pkgs.libayatana-appindicator ];

          # udev rule for the FX Pak Pro / SD2SNES (Linux only)
          postInstall = lib.optionalString stdenv.isLinux ''
            install -Dm644 linux/udev/rules.d/*.rules -t $out/lib/udev/rules.d
          '';

          meta = {
            description = "SNES Interface with gRPC API";
            homepage = "https://github.com/alttpo/sni";
            license = lib.licenses.mit;
            mainProgram = "sni";
            platforms = lib.platforms.linux ++ lib.platforms.darwin;
          };
        };
      in
      {
        packages = {
          inherit sni;
          default = sni;
        };

        apps.default = flake-utils.lib.mkApp { drv = sni; };

        devShells.default = pkgs.mkShell {
          inputsFrom = [ sni ];
          packages = [ pkgs.gopls pkgs.grpcui ];
        };
      });
}
