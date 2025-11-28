INPUT=$(cat) # Format from wl-paste | is ssh -p 00000 root@00.00.000.00 -L 8080:localhost:8080
PORT=$(echo "$INPUT" | grep -oP '\-p\s+\K\d+')
ADDRESS=$(echo "$INPUT" | grep -oP '@\K[0-9.]+')

rsync -avz -e "ssh -p $PORT" --exclude-from='/home/adc/ml_env/.rsyncignore' /home/adc/ml_env/ root@"$ADDRESS":/workspace/ml_env

ssh ${INPUT//ssh /} 'source /venv/main/bin/activate && /workspace/ml_env/install.sh' # n.b. I want word splitting here for ssh args.
