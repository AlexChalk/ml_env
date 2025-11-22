# curl -fsSL https://install.determinate.systems/nix | sh -s -- install --determinate
# curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install linux --init none --no-confirm

# Pytorch (Vast) Template
#ssh -p 46974 root@213.181.123.90 -L 8080:localhost:8080

# rsync -avz -e "ssh -p 46441" --exclude-from='/home/adc/ml_env/.rsyncignore' /home/adc/ml_env/ root@38.247.78.2:/workspace/ml_env

# rsync -avz -e "ssh -p 46441" root@38.247.78.2:/workspace/ml_env/miniai/ /home/adc/ml_env/miniai
# rsync -avz -e "ssh -p 46441" root@38.247.78.2:/workspace/ml_env/nbs/14_augment.ipynb /home/adc/ml_env/nbs/14_augment.ipynb
# rsync -avz -e "ssh -p 46441" root@38.247.78.2:/workspace/ml_env/nbs/models/ /home/adc/ml_env/nbs/models

export PYTHON_VERSION=3.12
export PYTORCH_CUDA_VERSION=12.4
eval "$(mamba shell hook --shell bash)"
mamba create -y -n ml -c fastai -c pytorch -c nvidia -c conda-forge python="$PYTHON_VERSION"
mamba activate ml
mamba install -y -c fastai -c pytorch -c nvidia -c conda-forge pytorch pytorch-cuda="$PYTORCH_CUDA_VERSION" rise opencv pytables fastai gradio watchfiles nbdev numpy ipykernel ipywidgets pandas matplotlib lxml beautifulsoup4 html5lib openpyxl requests sqlalchemy seaborn scipy statsmodels patsy scikit-learn pyarrow numba timm fastkaggle gast transformers[torch] py7zr diffusers datasets # tensorflow
pip install -Uq torcheval
pip install ./ml_env/miniai
python -m ipykernel install --user --name ml --display-name "Python (ML)"
