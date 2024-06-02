{
  description = "Application packaged using poetry2nix";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    poetry2nix = {
      url = "github:nix-community/poetry2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, poetry2nix }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      inherit (poetry2nix.lib.mkPoetry2Nix { inherit pkgs; }) mkPoetryEnv overrides;
    in
    {
      packages.${system} = {
        bear-classifier = mkPoetryEnv {
          projectDir = self;
          preferWheels = false;
          overrides = overrides.withDefaults (final: prev: {
            ruff = prev.ruff.override { preferWheel = true; };
            fastdownload = prev.fastdownload.overridePythonAttrs (
              old: {
                nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [
                  prev.setuptools
                ];
              }
            );
            fsspec = prev.fsspec.overridePythonAttrs (
              old: {
                nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [
                  prev.hatchling
                  prev.hatch-vcs
                ];
              }
            );
          });
        };
        default = self.packages.${system}.bear-classifier;
      };

      devShells.${system} = {
        # Shell for app dependencies.
        #
        #     nix develop
        #
        # Use this shell for developing your app.
        default = pkgs.mkShell {
          inputsFrom = [ self.packages.${system}.bear-classifier ];
        };
        # Shell for poetry.
        #
        #     nix develop .#poetry
        #
        # Use this shell for changes to pyproject.toml and poetry.lock.
        poetry = pkgs.mkShell {
          packages = [ pkgs.poetry ];
        };
      };
    };
}
