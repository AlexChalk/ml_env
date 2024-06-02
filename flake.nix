{
  description = "Application packaged using poetry2nix";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    poetry2nix = {
      url = "github:nix-community/poetry2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, poetry2nix, flake-utils }:
    flake-utils.lib.eachSystem [ flake-utils.lib.system.x86_64-linux ] (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        inherit (poetry2nix.lib.mkPoetry2Nix { inherit pkgs; }) mkPoetryEnv overrides;
        python = mkPoetryEnv {
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
        # This name makes it the default kernel, any other (e.g. pythonml) preserves
        # the nixpkgs default python kernel
        definitions = {
          python3 = {
            displayName = "Python ML";
            language = "python";
            logo32 = "${pkgs.jupyter.sitePackages}/ipykernel/resources/logo-32x32.png";
            logo64 = "${pkgs.jupyter.sitePackages}/ipykernel/resources/logo-64x64.png";
            argv = [
              "${python}/bin/python"
              "-m"
              "ipykernel_launcher"
              "-f"
              "{connection_file}"
            ];
          };
        };
        jupyter = pkgs.jupyter.override { inherit definitions; };
      in
      {
        packages = { inherit python jupyter; };
        packages.default = jupyter;
        apps.default = {
          type = "app";
          program = "${jupyter}/bin/jupyter";
        };
        apps.python = {
          type = "app";
          program = "${python}/bin/python";
        };
        devShells.default = pkgs.mkShell {
          buildInputs = [
            python
            jupyter
            pkgs.python3.pkgs.jupyterlab
          ];
          shellHook = ''
            CUSTOM_NIXSHELL=pythonml ${pkgs.zsh}/bin/zsh; exit
          '';
        };
      }
    );
}
