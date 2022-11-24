{
  description = "Haskell development environment";

  inputs.flake-utils.url = "github:numtide/flake-utils";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self
    , flake-utils
    , nixpkgs
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        haskellPackageNames = [
          "hvega"
        ];
        ghcVersion = "ghc924";
        haskellMkPackage = hps: nm: hps.callCabal2nix nm (./. + "/${nm}") { };
        haskellOverlay = (
          selfn: supern: {
            haskellPackages = supern.haskell.packages.${ghcVersion}.override {
              overrides = selfh: superh:
                {
                  hvega = selfh.callCabal2nix "hvega" ./. rec { };
                };
            };
          }
        );
        overlays = [ haskellOverlay ];
        pkgs = import nixpkgs {
          inherit system;
          inherit overlays;
        };
        hpkgs = pkgs.haskellPackages;
        hvegaPkgs = nixpkgs.lib.genAttrs haskellPackageNames (n: hpkgs.${n});
        hvegaPkgsDev = builtins.mapAttrs (_: x: pkgs.haskell.lib.doBenchmark x) hvegaPkgs;
      in
      {
        packages = hvegaPkgs // { hvegaPkgs.default = hvegaPkgs.hvega; };

        devShells.default = hpkgs.shellFor {
          # shellHook =
          #   let
          #     scripts = ./scripts;
          #   in
          #   ''
          #     export PATH="${scripts}:$PATH"
          #   '';
          packages = _: (builtins.attrValues hvegaPkgsDev);
          nativeBuildInputs = with pkgs; [
            # See https://github.com/NixOS/nixpkgs/issues/59209.
            bashInteractive

            # Haskell toolchain.
            hpkgs.cabal-fmt
            hpkgs.cabal-install
            hpkgs.haskell-language-server
          ];
          buildInputs = with pkgs; [
          ];
          doBenchmark = true;
          # withHoogle = true;
        };
      }
    );
}
