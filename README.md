# ml_env

nix shell nixpkgs#python311
nix shell nixpkgs#python311 --command poetry --help
poetry add --lock package="*"
`nix shell nixpkgs#python311 --command poetry add --lock "transformers[torch]=*"`
poetry update --lock / poetry lock (--no-update)
nix build
nix run
nix flake update
./result/bin/jupyter notebook --no-browser

git lfs track "*.psd"

n.b. can't install nbextensions on newer versions of jupyter
(jupyter contrib nbextension install --user)

jupyter-lab: `nix run`; with args: `nix run . -- args`
nix run .#python
nix run .#jupyter -- notebook
nix develop
