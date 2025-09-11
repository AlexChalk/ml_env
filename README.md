# ml_env

nix shell nixpkgs#python313
nix shell nixpkgs#python313 --command uv --help
uv add "package" --no-sync --raw
(--no-sync prevents venv creation/modification, --raw adds as specified, here without version pinning)
`nix shell nixpkgs#python313 --command uv add "transformers[torch]" --no-sync --raw`
poetry update --lock / poetry lock (--no-update)
uv lock --upgrade / uv lock (no version update)
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
