export PASSWORD="$1"
export ADDRESS="$2"
rsync -avz -e "ssh -p $PASSWORD" --exclude-from='/home/adc/ml_env/.rsyncignore' /home/adc/ml_env/ root@"$ADDRESS":/workspace/ml_env
