# ml_env

poetry add --lock
poetry update --lock / poetry lock (--no-update)
nix build
nix run
nix flake update
./result/bin/jupyter notebook --no-browser

nix run .#python
nix run . -- notebook
nix develop
