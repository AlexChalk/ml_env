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

        systemLibs = [
          pkgs.rdma-core
          pkgs.ucx
          pkgs.libfabric
          pkgs.pmix
          pkgs.mpi
        ];

        pyprojectOverrides = final: prev:
          let
            searchPaths = ps: lib.concatMapStrings
              (p: ''
                addAutoPatchelfSearchPath "${p}"
              '')
              ps;

            cudaWheelSearchPaths = searchPaths (with final; [
              nvidia-cublas
              nvidia-cuda-cupti
              nvidia-cuda-nvrtc
              nvidia-cuda-runtime
              nvidia-cudnn-cu13
              nvidia-cufft
              nvidia-cufile
              nvidia-curand
              nvidia-cusolver
              nvidia-cusparse
              nvidia-cusparselt-cu13
              nvidia-nccl-cu13
              nvidia-nvjitlink
              nvidia-nvshmem-cu13
              nvidia-nvtx
            ]);
          in
          {
            numba = prev.numba.overrideAttrs (old: {
              buildInputs = (old.buildInputs or [ ]) ++ [
                pkgs.tbb_2022
                pkgs.stdenv.cc.cc.lib
              ];
            });
            nvidia-cufile = prev.nvidia-cufile.overrideAttrs (old: {
              buildInputs = (old.buildInputs or [ ]) ++ [ pkgs.rdma-core ];
            });
            nvidia-cusparse = prev.nvidia-cusparse.overrideAttrs (old: {
              postFixup = (old.postFixup or "") + searchPaths [ final.nvidia-nvjitlink ];
            });
            nvidia-cusolver = prev.nvidia-cusolver.overrideAttrs (old: {
              postFixup = (old.postFixup or "") + searchPaths (with final; [ nvidia-nvjitlink nvidia-cusparse nvidia-cublas ]);
            });
            nvidia-nvshmem-cu13 = prev.nvidia-nvshmem-cu13.overrideAttrs (old: {
              buildInputs = (old.buildInputs or [ ]) ++ systemLibs;
            });
            torch = prev.torch.overrideAttrs (old: {
              nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ pkgs.autoAddDriverRunpath ];
              buildInputs = (old.buildInputs or [ ]) ++ systemLibs;
              autoPatchelfIgnoreMissingDeps = (old.autoPatchelfIgnoreMissingDeps or [ ]) ++ [
                "libcuda.so.1"
              ];
              postFixup = (old.postFixup or "") + cudaWheelSearchPaths;
            });
            torch-xla = prev.torch-xla.overrideAttrs (old: {
              buildInputs = (old.buildInputs or [ ]) ++ systemLibs;
              postFixup = (old.postFixup or "") + searchPaths [ final.torch ];
            });
            torchvision = prev.torchvision.overrideAttrs
              (old: {
                buildInputs = (old.buildInputs or [ ]) ++ systemLibs;
                postFixup = (old.postFixup or "") + searchPaths [ final.torch ];
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
        jupyter-wrapper = pkgs.symlinkJoin {
          name = "jupyter-wrapper";
          paths = [ pythonEnv ];
          nativeBuildInputs = [ pkgs.makeWrapper ];
          postBuild = ''
            for i in $out/bin/jupyter*; do
              wrapProgram "$i" \
                --prefix PATH : ${pythonEnv}/bin \
                --set JUPYTER_PATH "${jupyterPath}"
            done
          '';
        };
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


