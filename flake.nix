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
          python = pkgs.python311;
          extraPackages = ps: [ ps.notebook ps.jupyterlab ];
          overrides = overrides.withDefaults (final: prev: {
            blosc2 = prev.blosc2.override { preferWheel = true; };
            ffmpy = prev.ffmpy.override { preferWheel = true; };
            numexpr = prev.numexpr.override { preferWheel = true; };
            numba = prev.numba.override { preferWheel = true; };
            opencv-python = prev.opencv-python.override { preferWheel = true; };
            optree = prev.optree.override { preferWheel = true; };
            pyarrow = prev.pyarrow.override { preferWheel = true; };
            rpds-py = prev.rpds-py.override { preferWheel = true; };
            ruff = prev.ruff.override { preferWheel = true; };
            safetensors = prev.safetensors.override { preferWheel = true; };
            tables = prev.tables.override { preferWheel = true; };
            tokenizers = prev.tokenizers.override { preferWheel = true; };
            torcheval = prev.torcheval.override { preferWheel = true; };
            lxml = prev.lxml.override { preferWheel = true; };
            confection = prev.confection.overridePythonAttrs (old: {
              nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [
                prev.setuptools
              ];
            });
            fastdownload = prev.fastdownload.overridePythonAttrs (old: {
              nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [
                prev.setuptools
              ];
            });
            fsspec = prev.fsspec.overridePythonAttrs (old: {
              nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [
                prev.hatchling
                prev.hatch-vcs
              ];
            });
            jupyterlab-rise = prev.jupyterlab-rise.overridePythonAttrs (old: {
              nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [
                final.hatch-nodejs-version
                final.hatch-jupyter-builder
              ];
            });
            jupyterlab-server = prev.jupyterlab-server.overridePythonAttrs (old: {
              nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [
                final.pytest
              ];
            });
            jupyterlab-vim = prev.jupyterlab-vim.overridePythonAttrs (old: {
              nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [
                final.hatch-nodejs-version
                final.hatch-jupyter-builder
              ];
            });
            ndindex = prev.ndindex.overridePythonAttrs (old: {
              nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [
                prev.setuptools
              ];
            });
            timm = prev.timm.overridePythonAttrs (old: {
              nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [
                prev.pdm-backend
              ];
            });
            fastkaggle = prev.fastkaggle.overridePythonAttrs (old: {
              nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [
                prev.setuptools
              ];
            });
            namex = prev.namex.overridePythonAttrs (old: {
              nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [
                prev.setuptools
              ];
            });
            multivolumefile = prev.multivolumefile.overridePythonAttrs (old: {
              nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [
                prev.setuptools
              ];
            });
            pybcj = prev.pybcj.overridePythonAttrs (old: {
              nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [
                prev.setuptools
              ];
            });
            pyzstd = prev.pyzstd.overridePythonAttrs (old: {
              nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [
                prev.setuptools
              ];
            });
            inflate64 = prev.inflate64.overridePythonAttrs (old: {
              nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [
                prev.setuptools
              ];
            });
            pyppmd = prev.pyppmd.overridePythonAttrs (old: {
              nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [
                prev.setuptools
              ];
            });
            py7zr = prev.py7zr.overridePythonAttrs (old: {
              nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [
                prev.setuptools
              ];
            });
          });
        };
        # This name makes it the default kernel, any other (e.g. pythonml) preserves
        # the nixpkgs default python kernel
        definitions = {
          python3 = {
            displayName = "Python ML";
            language = "python";
            logo32 = "${python.pkgs.ipykernel}/lib/python*/site-packages/ipykernel/resources/logo-32x32.png";
            logo64 = "${python.pkgs.ipykernel}/lib/python*/site-packages/ipykernel/resources/logo-64x64.png";
            argv = [
              "${python}/bin/python"
              "-m"
              "ipykernel_launcher"
              "-f"
              "{connection_file}"
            ];
          };
        };
        jupyterKernel = pkgs.jupyter-kernel.override { python3 = python; };
        jupyterPath = jupyterKernel.create { inherit definitions; };
        # https://github.com/tweag/jupyenv/blob/0c86802aaa3ffd3e48c6f0e7403031c9168a8be2/lib/jupyter.nix#L174
        jupyter-wrapper = pkgs.runCommand "jupyter-wrapper"
          { nativeBuildInputs = [ pkgs.makeWrapper ]; }
          ''
            mkdir $out && ln -s ${python}/* $out/ && rm $out/bin && mkdir $out/bin
            for i in ${python}/bin/*; do
              filename=$(basename $i)
              ln -s ${python}/bin/$filename $out/bin/$filename
            done
            for i in $out/bin/jupyter*; do
            filename=$(basename $i)
            wrapProgram $out/bin/$filename \
              --prefix PATH : ${python}/bin \
              --set JUPYTER_PATH "${jupyterPath}"
            done
          '';
      in
      {
        packages = { inherit jupyter-wrapper; };
        packages.default = jupyter-wrapper;
        apps.default = {
          type = "app";
          program = "${jupyter-wrapper}/bin/jupyter-lab";
        };
        apps.jupyter = {
          type = "app";
          program = "${jupyter-wrapper}/bin/jupyter";
        };
        apps.python = {
          type = "app";
          program = "${jupyter-wrapper}/bin/python";
        };
        devShells.default = pkgs.mkShell {
          buildInputs = [
            jupyter-wrapper
          ];
          shellHook = ''
            CUSTOM_NIXSHELL=pythonml ${pkgs.zsh}/bin/zsh; exit
          '';
        };
      }
    );
}
