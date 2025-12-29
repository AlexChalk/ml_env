# curl -fsSL https://install.determinate.systems/nix | sh -s -- install --determinate
# curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install linux --init none --no-confirm

# Pytorch (Vast) Template
# ssh -p 21555 root@213.181.123.20 -L 8080:localhost:8080

# rsync -avz -e "ssh -p 21555" --exclude-from='/home/adc/ml_env/.rsyncignore' /home/adc/ml_env/ root@213.181.123.20:/workspace/ml_env

# rsync -avz -e "ssh -p 21555" root@213.181.123.20:/workspace/ml_env/miniai/ /home/adc/ml_env/miniai
# rsync -avz -e "ssh -p 21555" root@213.181.123.20:/workspace/ml_env/nbs/14_augment.ipynb /home/adc/ml_env/nbs/14_augment.ipynb
# rsync -avz -e "ssh -p 21555" root@213.181.123.20:/workspace/ml_env/nbs/models/ /home/adc/ml_env/nbs/models

export PYTHON_VERSION=3.12
eval "$(mamba shell hook --shell bash)"
mamba create -y -n ml -c fastai -c nvidia -c conda-forge python="$PYTHON_VERSION"
mamba activate ml
mamba install -y -c fastai -c nvidia -c conda-forge pytorch torchaudio librosa rise opencv pytables fastai gradio watchfiles nbdev numpy ipykernel ipywidgets pandas matplotlib lxml beautifulsoup4 html5lib openpyxl requests sqlalchemy seaborn scipy statsmodels patsy scikit-learn pyarrow numba timm fastkaggle gast transformers[torch] py7zr diffusers datasets accelerate einops wandb # tensorflow
pip install -Uq torcheval pytorch-fid k-diffusion
rm /workspace/ml_env/pyproject.toml
pip install -e /workspace/ml_env
python -m ipykernel install --user --name ml --display-name "Python (ML)"
