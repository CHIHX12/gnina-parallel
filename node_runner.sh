#!/bin/bash
# 1ノードで4 GPU を使って gnina を並行実行するラッパー
# 引数: SIF RECEPTOR AUTOBOX OUTDIR SPLIT_BASE START_IDX GPU_PER_NODE

SIF=$1
RECEPTOR=$2
AUTOBOX=$3
OUTDIR=$4
SPLIT_BASE=$5
START_IDX=$6
GPU_PER_NODE=$7

module load singularity/3.5.2

echo "  [$(hostname)] GPU 0〜$((GPU_PER_NODE-1)) 開始 $(date '+%H:%M:%S')"

for GPU in $(seq 0 $((GPU_PER_NODE-1))); do
    TASK_NUM=$(( START_IDX + GPU ))
    SPLIT_FILE=$(printf "%s/split_%02d.sdf" $SPLIT_BASE $TASK_NUM)
    OUT_FILE=$(printf "%s/result/result_%02d.sdf" $OUTDIR $TASK_NUM)
    LOG_FILE=$(printf "%s/result/result_%02d.log" $OUTDIR $TASK_NUM)

    if [ ! -f "$SPLIT_FILE" ]; then
        echo "  [$(hostname)] GPU $GPU: ファイルなし（スキップ）"
        continue
    fi

    CUDA_VISIBLE_DEVICES=$GPU singularity exec --nv --bind /home/nibiohnproj9 \
        $SIF gnina \
        -r $RECEPTOR \
        -l $SPLIT_FILE \
        --autobox_ligand $AUTOBOX \
        -o $OUT_FILE \
        --device 0 \
        --cpu 8 \
        >> $LOG_FILE 2>&1 &

    echo "  [$(hostname)] GPU $GPU: split_$(printf "%02d" $TASK_NUM).sdf 開始"
done

wait
echo "  [$(hostname)] 全GPU完了 $(date '+%H:%M:%S')"
