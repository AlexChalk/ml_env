INPUT=$(cat)
PORT=$(echo "$INPUT" | grep -oP '\-p\s+\K\d+')
ADDRESS=$(echo "$INPUT" | grep -oP '@\K[0-9.]+')

rsync -avz -e "ssh -p $PORT" --exclude-from='/home/adc/ml_env/.rsyncignore' /home/adc/ml_env/ root@"$ADDRESS":/workspace/ml_env
