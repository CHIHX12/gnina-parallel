# gnina-parallel

Slurm scripts for running [gnina](https://github.com/gnina/gnina) molecular docking in parallel across multiple nodes and GPUs.

## Overview

Automatically splits a large SDF ligand file and distributes docking jobs across multiple GPUs on multiple nodes using Slurm.

```
Input SDF (e.g. 1,000,000 ligands)
        ↓
  Auto-split by Python
        ↓
Node1: GPU0 GPU1 GPU2 GPU3
Node2: GPU0 GPU1 GPU2 GPU3
Node3: GPU0 GPU1 GPU2 GPU3
        ↓
  Merge results
```

## Files

| File | Description |
|------|-------------|
| `gnina_auto_split.sh` | Main sbatch script — splits SDF and dispatches to all nodes/GPUs |
| `node_runner.sh` | Per-node runner — assigns 1 gnina instance per GPU using `CUDA_VISIBLE_DEVICES` |
| `split_sdf.py` | Python script to split SDF file into N equal chunks |

## Usage

### 1. Edit settings in `gnina_auto_split.sh`

```bash
SIF=/path/to/gnina.sif          # Singularity image
RECEPTOR=/path/to/receptor.pdb  # Receptor file
LIGAND=/path/to/ligands.sdf     # Input ligand SDF (any size)
AUTOBOX=/path/to/autobox.pdb    # Autobox ligand
OUTDIR=/path/to/output          # Output directory
N_GPU=12                         # Total number of GPUs
```

### 2. Submit

```bash
sbatch gnina_auto_split.sh
```

### 3. Results

Output files will be in `$OUTDIR/result/`:
```
result_01.sdf  result_02.sdf  ...  result_12.sdf
```

Each file contains docked poses with scores:
- `minimizedAffinity` — Binding free energy (kcal/mol), lower is better
- `CNNscore` — CNN predicted binding probability (0–1), higher is better
- `CNNaffinity` — CNN predicted binding affinity (pKd), higher is better

## Resource Configuration

Tested on 3-node × 4-GPU cluster:

```
#SBATCH -N 3
#SBATCH --ntasks=3
#SBATCH --ntasks-per-node=1
#SBATCH --gres=gpu:4
#SBATCH --cpus-per-task=40
```

### CPU Benchmark Results (per GPU)

| --cpu | Time (10 ligands) | Speedup |
|-------|-------------------|---------|
| 1     | 770s              | 1.0x    |
| 4     | 251s              | 3.1x    |
| 8     | 158s              | **4.9x** |
| 10    | 161s              | 4.8x    |

**Recommended: `--cpu 8`** (diminishing returns beyond 8)

## Requirements

- Slurm workload manager
- Singularity
- gnina Singularity image (`gnina_v1.3.2.sif` or later)
- Python 3
