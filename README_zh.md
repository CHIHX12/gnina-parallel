# gnina-parallel 並行分子對接

使用 Slurm 在多節點多GPU上並行執行 [gnina](https://github.com/gnina/gnina) 分子對接的腳本。

## 概念

自動將大型SDF配體檔案拆分，分配到多個GPU並行執行對接：

```
輸入SDF（例如：100萬個配體）
        ↓
  Python 自動拆分
        ↓
節點1: GPU0 GPU1 GPU2 GPU3
節點2: GPU0 GPU1 GPU2 GPU3
節點3: GPU0 GPU1 GPU2 GPU3
        ↓
  各自輸出結果檔
```

## 檔案說明

| 檔案 | 說明 |
|------|------|
| `gnina_auto_split.sh` | 主腳本 — 自動拆分SDF並分配到各節點/GPU |
| `node_runner.sh` | 每節點執行腳本 — 用 `CUDA_VISIBLE_DEVICES` 指定每個gnina使用哪張GPU |
| `split_sdf.py` | Python拆分程式 — 將SDF切成N等份 |

## 使用方法

### 1. 修改 `gnina_auto_split.sh` 設定區

```bash
SIF=/path/to/gnina.sif          # Singularity映像檔路徑
RECEPTOR=/path/to/receptor.pdb  # 受體檔案
LIGAND=/path/to/ligands.sdf     # 輸入配體SDF（任意大小）
AUTOBOX=/path/to/autobox.pdb    # Autobox配體
OUTDIR=/path/to/output          # 輸出目錄
N_GPU=12                         # 總GPU數
```

### 2. 提交工作

```bash
sbatch gnina_auto_split.sh
```

### 3. 結果

輸出檔案位於 `$OUTDIR/result/`：
```
result_01.sdf  result_02.sdf  ...  result_12.sdf
```

每個檔案包含對接姿勢與分數：
- `minimizedAffinity` — 結合自由能（kcal/mol），越負越好
- `CNNscore` — CNN預測結合機率（0–1），越高越好
- `CNNaffinity` — CNN預測結合親和力（pKd），越高越好

## 資源配置

以3節點 × 4GPU叢集測試：

```bash
#SBATCH -N 3
#SBATCH --ntasks=3
#SBATCH --ntasks-per-node=1
#SBATCH --gres=gpu:4
#SBATCH --cpus-per-task=40
```

### CPU數量基準測試結果（單GPU）

| --cpu | 時間（10個配體） | 加速倍率 |
|-------|----------------|--------|
| 1     | 770秒          | 1.0倍  |
| 4     | 251秒          | 3.1倍  |
| 8     | 158秒          | **4.9倍** |
| 10    | 161秒          | 4.8倍  |

**建議使用 `--cpu 8`**（超過8顆CPU後效益遞減）

## 環境需求

- Slurm 工作排程系統
- Singularity
- gnina Singularity映像檔（`gnina_v1.3.2.sif` 或更新版本）
- Python 3
