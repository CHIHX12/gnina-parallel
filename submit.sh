#!/bin/bash
# ========== 只需要改這裡 ==========
N_GPU=12   # 4 / 8 / 12 / 16 / 20 / 24 / 28
# ===================================

N_NODES=$(( N_GPU / 4 ))
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

echo "提交: ${N_GPU} GPU / ${N_NODES} 節點"

sbatch \
    -N $N_NODES \
    --ntasks=$N_NODES \
    $SCRIPT_DIR/gnina_auto_split.sh $N_GPU $SCRIPT_DIR
