#!/bin/bash
#SBATCH --job-name=gnina_split
#SBATCH -p gpu
#SBATCH -N 3
#SBATCH --ntasks=3
#SBATCH --ntasks-per-node=1
#SBATCH --gres=gpu:4
#SBATCH --cpus-per-task=40
#SBATCH --mem=0
#SBATCH --output=/home/nibiohnproj9/cycheng/gnina_test/gnina_split_%j.log

module load singularity/3.5.2

# ========== 設定區 ==========
SIF=/home/nibiohnproj9/chenyian/dd/sif/gnina_v1.3.2.sif
RECEPTOR=/home/nibiohnproj9/chenyian/ogawa/sample_b/receptor.pdb
LIGAND=/home/nibiohnproj9/cycheng/gnina_test/test_121.sdf  # ← 換成你的大SDF
AUTOBOX=/home/nibiohnproj9/chenyian/ogawa/sample_b/ligand.pdb
OUTDIR=/home/nibiohnproj9/cycheng/gnina_test/output
N_GPU=12
# ============================

mkdir -p $OUTDIR/split $OUTDIR/result

echo "=== gnina 自動分割 + 12GPU 並行 $(date) ==="
echo "Nodes: $SLURM_NODELIST"
echo "Input: $LIGAND"

# Step 1: 計算總配體數 + 拆分
echo ""
echo "[1] SDF 拆分中..."
TOTAL=$(grep -c '\$\$\$\$' $LIGAND)
echo "    總配體數: $TOTAL"
echo "    GPU 數:   $N_GPU"
PER_GPU=$(( (TOTAL + N_GPU - 1) / N_GPU ))
echo "    各 GPU:   約 $PER_GPU 個配體"

python3 /home/nibiohnproj9/cycheng/gnina_test/split_sdf.py "$LIGAND" "$OUTDIR/split" $N_GPU

echo ""
echo "[2] 12GPU 並行実行中..."

# Step 2: 1ノードに1ステップ、内部で4GPU並行
NODES=($(scontrol show hostnames "$SLURM_NODELIST"))
N_NODES=${#NODES[@]}
GPU_PER_NODE=4

echo "    ノード: ${NODES[@]}"
mkdir -p $OUTDIR/result

for IDX in $(seq 0 $((N_NODES-1))); do
    NODE=${NODES[$IDX]}
    START=$(( IDX * GPU_PER_NODE + 1 ))
    echo "    $NODE → split_$(printf "%02d" $START)〜$(printf "%02d" $((START+GPU_PER_NODE-1)))"

    srun --ntasks=1 --gres=gpu:4 \
        --nodelist=$NODE \
        bash /home/nibiohnproj9/cycheng/gnina_test/node_runner.sh \
        $SIF $RECEPTOR $AUTOBOX $OUTDIR $OUTDIR/split $START $GPU_PER_NODE &
done

wait

echo ""
echo "[3] 完了 $(date)"
echo ""
echo "=== 結果確認 ==="
TOTAL_OUT=0
for i in $(seq 1 $N_GPU); do
    OUT_FILE=$OUTDIR/result/result_$(printf "%02d" $i).sdf
    if [ -f "$OUT_FILE" ]; then
        COUNT=$(grep -c '\$\$\$\$' $OUT_FILE 2>/dev/null || echo 0)
        echo "  result_$(printf "%02d" $i).sdf: $COUNT poses"
        TOTAL_OUT=$((TOTAL_OUT + COUNT))
    fi
done
echo "  合計: $TOTAL_OUT poses"
