export PASSWORD="$1"
export ADDRESS="$2"

rsync -avz -e "ssh -p $PASSWORD" --exclude-from='/home/adc/ml_env/.rsyncignore' root@"$ADDRESS":/workspace/ml_env/ /home/adc/ml_env
