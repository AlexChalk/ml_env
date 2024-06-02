# ml_env

poetry add --lock
poetry update --lock / poetry lock (--no-update)
nix build
nix run
nix flake update
./result/bin/jupyter notebook --no-browser

n.b. can't install nbextensions on newer versions of jupyter
(jupyter contrib nbextension install --user)

nix run .#python
nix run . -- notebook
nix develop
