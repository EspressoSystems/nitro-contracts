{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  inputs.utils.url = "github:numtide/flake-utils";
  inputs.foundry.url = "github:shazow/foundry.nix/monthly"; # Use monthly branch for permanent releases
  inputs.solc.url = "github:EspressoSystems/nix-solc-bin";
  inputs.dregs.url = "github:EspressoSystems/dregs";

  outputs = { self, nixpkgs, utils, foundry, solc, dregs }:
    utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs
          {
            inherit system;
            overlays = [
              foundry.overlay
              solc.overlays.default
              dregs.overlays.default
              (final: prev: {
                # Overlaying nodejs here to ensure nodePackages use the desired
                # version of nodejs use by the upstream CI.
                nodejs = prev.nodejs-18_x;
                pnpm = prev.nodePackages.pnpm;
                yarn = prev.nodePackages.yarn;
              })
            ];
          };
      in
      {
        devShells.default = with pkgs; mkShell {
          buildInputs = [
            foundry-bin
            nodejs
            yarn
            solc-bin."0.8.30"
            pkgs.dregs
          ];
          shellHook = ''
            # Add node executables (incl. hardhat) to PATH
            export PATH=$PWD/node_modules/.bin:$PATH
          '';

        };

      });
}
