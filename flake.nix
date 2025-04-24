{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs =
    { self, nixpkgs, ... }:
    let

      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems = f: nixpkgs.lib.genAttrs supportedSystems (system: f system);
      nixpkgsFor = forAllSystems (system: import nixpkgs { inherit system; });
    in
    {
      formatter = forAllSystems (system: nixpkgsFor.${system}.nixfmt-rfc-style);
      packages = forAllSystems (
        system:
        let
          ghostpcl =
            with nixpkgsFor.${system};
            stdenv.mkDerivation rec {
              pname = "ghostpcl";
              version = "10.05.0";

              src = fetchurl {
                url = "https://github.com/ArtifexSoftware/ghostpdl-downloads/releases/download/gs${
                  lib.replaceStrings [ "." ] [ "" ] version
                }/ghostpdl-${version}.tar.xz";
                hash = "sha256-8VQDk0W26ZV7B1D4cjdNiH12Mh1Su8ydO4VIeFXgjwI=";
              };
              enableParallelBuilding = true;
              makeFlags = [ "gpcl6" ];
            };
        in
        {
          default = ghostpcl;
        }
      );

      apps = forAllSystems (system: {
        default = {
          type = "app";
          program = "${self.packages.${system}.default}/bin/gpcl6";
        };
      });
    };
}
