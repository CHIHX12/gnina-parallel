#!/bin/bash
# ========== 只需要改這裡 ==========
N_GPU=12   # 4 / 8 / 12 / 16 / 20 / 24 / 28
# ===================================

N_NODES=$(( N_GPU / 4 ))

echo "提交: ${N_GPU} GPU / ${N_NODES} 節點"

sbatch \
    -N $N_NODES \
    --ntasks=$N_NODES \
    gnina_auto_split.sh $N_GPU
