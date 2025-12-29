{
  description = "Application packaged using uv2nix";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    pyproject-nix = {
      url = "github:pyproject-nix/pyproject.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    uv2nix = {
      url = "github:pyproject-nix/uv2nix";
      inputs.pyproject-nix.follows = "pyproject-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    pyproject-build-systems = {
      url = "github:pyproject-nix/build-system-pkgs";
      inputs.pyproject-nix.follows = "pyproject-nix";
      inputs.uv2nix.follows = "uv2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  # https://pyproject-nix.github.io/uv2nix/usage/hello-world.html
  outputs = { self, nixpkgs, uv2nix, pyproject-nix, pyproject-build-systems, flake-utils }:
    flake-utils.lib.eachSystem [ flake-utils.lib.system.x86_64-linux ] (
      system:
      let
        inherit (nixpkgs) lib;
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
        workspace = uv2nix.lib.workspace.loadWorkspace { workspaceRoot = ./.; };

        overlay = workspace.mkPyprojectOverlay {
          sourcePreference = "wheel"; # or sourcePreference = "sdist";
        };

        python = pkgs.python313;

        cudaLibs = [
          pkgs.cudaPackages.cuda_cccl
          pkgs.cudaPackages.cuda_cudart
          pkgs.cudaPackages.cuda_cupti
          pkgs.cudaPackages.cuda_nvcc
          pkgs.cudaPackages.cuda_nvml_dev
          pkgs.cudaPackages.cuda_nvrtc
          pkgs.cudaPackages.cuda_nvtx
          pkgs.cudaPackages.cuda_profiler_api
          pkgs.cudaPackages.cudnn
          pkgs.cudaPackages.libcublas
          pkgs.cudaPackages.libcufft
          pkgs.cudaPackages.libcufile
          pkgs.cudaPackages.libcurand
          pkgs.cudaPackages.libcusolver
          pkgs.cudaPackages.libcusparse
          pkgs.cudaPackages.libcusparse_lt
          pkgs.cudaPackages.libcutensor
          pkgs.cudaPackages.nccl
          pkgs.rdma-core
        ];

        pyprojectOverrides = final: prev: {
          numba = prev.numba.overrideAttrs (old: {
            buildInputs = (old.buildInputs or [ ]) ++ [ pkgs.tbb_2022 ];
          });
          nvidia-cufile-cu12 = prev.nvidia-cufile-cu12.overrideAttrs (old: {
            buildInputs = (old.buildInputs or [ ]) ++ cudaLibs;
          });
          nvidia-cusparse-cu12 = prev.nvidia-cusparse-cu12.overrideAttrs (old: {
            buildInputs = (old.buildInputs or [ ]) ++ cudaLibs;
          });
          nvidia-cusolver-cu12 = prev.nvidia-cusolver-cu12.overrideAttrs (old: {
            buildInputs = (old.buildInputs or [ ]) ++ cudaLibs;
          });
          torch = prev.torch.overrideAttrs (old: {
            buildInputs = (old.buildInputs or [ ]) ++ cudaLibs;
            autoPatchelfIgnoreMissingDeps = (old.autoPatchelfIgnoreMissingDeps or [ ]) ++ [
              "libcuda.so.1"
              "libnvrtc.so"
            ];
          });
          torchaudio = prev.torchaudio.overrideAttrs (old: {
            buildInputs = (old.buildInputs or [ ]) ++ cudaLibs ++ [
              pkgs.sox
              pkgs.ffmpeg_4
              pkgs.ffmpeg_6
            ];
            autoPatchelfIgnoreMissingDeps = (old.autoPatchelfIgnoreMissingDeps or [ ]) ++ [
              "libcuda.so.1"
              "libnvrtc.so"
              # Ignore FFmpeg 5 libraries (not available in nixpkgs)
              "libavutil.so.57"
              "libavcodec.so.59"
              "libavformat.so.59"
              "libavdevice.so.59"
              "libavfilter.so.8"
            ];
            postFixup = ''
              addAutoPatchelfSearchPath "${final.torch}"
            '';
          });
          torch-xla = prev.torch-xla.overrideAttrs (old: {
            buildInputs = (old.buildInputs or [ ]) ++ cudaLibs;
            postFixup = ''
              addAutoPatchelfSearchPath "${final.torch}"
            '';
          });
          torchvision = prev.torchvision.overrideAttrs (old: {
            buildInputs = (old.buildInputs or [ ]) ++ cudaLibs;
            postFixup = ''
              addAutoPatchelfSearchPath "${final.torch}"
            '';
          });
        };

        pythonSet =
          (pkgs.callPackage pyproject-nix.build.packages {
            inherit python;
          }).overrideScope
            (
              lib.composeManyExtensions [
                pyproject-build-systems.overlays.default
                overlay
                pyprojectOverrides
              ]
            );

        pythonEnv = pythonSet.mkVirtualEnv "ml-env" workspace.deps.default;
        # All would include other dependency groups like dev
        # pythonEnv = pythonSet.mkVirtualEnv "ml-env" workspace.deps.all;

        # This name makes it the default kernel, any other (e.g. pythonml) preserves
        # the nixpkgs default python kernel
        definitions = {
          python3 = {
            displayName = "Python ML";
            language = "python";
            logo32 = "${pythonSet.ipykernel}/lib/python*/site-packages/ipykernel/resources/logo-32x32.png";
            logo64 = "${pythonSet.ipykernel}/lib/python*/site-packages/ipykernel/resources/logo-64x64.png";
            argv = [
              "${pythonEnv}/bin/python"
              "-m"
              "ipykernel_launcher"
              "-f"
              "{connection_file}"
            ];
          };
        };
        jupyterKernel = pkgs.jupyter-kernel.override { python3 = pythonEnv; };
        jupyterPath = jupyterKernel.create { inherit definitions; };
        # https://github.com/tweag/jupyenv/blob/0c86802aaa3ffd3e48c6f0e7403031c9168a8be2/lib/jupyter.nix#L174
        jupyter-wrapper = pkgs.runCommand "jupyter-wrapper"
          { nativeBuildInputs = [ pkgs.makeWrapper ]; }
          ''
            mkdir $out && ln -s ${pythonEnv}/* $out/ && rm $out/bin && mkdir $out/bin
            for i in ${pythonEnv}/bin/*; do
              filename=$(basename $i)
              ln -s ${pythonEnv}/bin/$filename $out/bin/$filename
            done
            for i in $out/bin/jupyter*; do
            filename=$(basename $i)
            wrapProgram $out/bin/$filename \
              --prefix PATH : ${pythonEnv}/bin \
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
          packages = [
            jupyter-wrapper
            pkgs.uv
          ];

          env = {
            # Don't create venv using uv
            UV_NO_SYNC = "1";
            # Force uv to use nixpkgs Python interpreter
            UV_PYTHON = python.interpreter;
            # Prevent uv from downloading managed Pythons
            UV_PYTHON_DOWNLOADS = "never";
          };

          shellHook = ''
            unset PYTHONPATH # Undo dependency propagation by nixpkgs.
            CUSTOM_NIXSHELL=pythonml ${pkgs.zsh}/bin/zsh; exit
          '';
        };
      }
    );
}
