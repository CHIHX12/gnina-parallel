# gnina-parallel

Slurm scripts for running [gnina](https://github.com/gnina/gnina) molecular docking in parallel across multiple nodes and GPUs.

**Language / 語言:** [English](README.md) | [中文](README_zh.md)

> **All scripts in this repository have been tested on a real HPC cluster (3 nodes × 4 GPUs = 12 GPUs, RHEL 7, Slurm 20.11).**

---

## What is this?

**gnina** is a deep learning-based molecular docking tool. This repository provides scripts to run gnina on a **Slurm HPC cluster** using multiple GPUs in parallel.

> **Beginner friendly!** You only need to change 5 lines to run your own docking job.

---

## How it works

You give it one large SDF file. It automatically splits it and sends each chunk to a different GPU — all at the same time.

```
Input SDF (e.g. 1,000,000 ligands)
        ↓
  Auto-split by Python
        ↓
Node1: GPU0 GPU1 GPU2 GPU3
Node2: GPU0 GPU1 GPU2 GPU3
Node3: GPU0 GPU1 GPU2 GPU3
        ↓
  Output: result_01.sdf ~ result_12.sdf
```

---

## Beginner's Guide

### Step 1 — Check your files

You need:
- A **receptor** file (protein, `.pdb` format)
- A **ligand** file (small molecules, `.sdf` format)
- A **reference ligand** for autobox (`.pdb` format, defines the docking box)
- A **gnina Singularity image** (`.sif` file)

### Step 2 — Edit `gnina_auto_split.sh`

Open the file and change only the settings section:

```bash
# ========== Settings ==========
SIF=/path/to/gnina.sif          # Path to your gnina .sif file
RECEPTOR=/path/to/receptor.pdb  # Your receptor (protein)
LIGAND=/path/to/ligands.sdf     # Your ligands (can be millions)
AUTOBOX=/path/to/autobox.pdb    # Reference ligand for docking box
OUTDIR=/path/to/output          # Where to save results
N_GPU=12                         # How many GPUs to use
# ==============================
```

### Step 3 — Submit the job

```bash
sbatch gnina_auto_split.sh
```

### Step 4 — Check progress

```bash
# Check job status
squeue -u $USER

# Watch the log in real time (log path is set in gnina_auto_split.sh --output)
tail -f /your/output/path/gnina_split_<JOBID>.log
```

### Step 5 — Check results

Results will be in `$OUTDIR/result/`:
```
result_01.sdf  result_02.sdf  ...  result_12.sdf
```

Count how many poses were generated:
```bash
for f in $OUTDIR/result/result_*.sdf; do
    echo "$f: $(grep -c '\$\$\$\$' $f) poses"
done
```

---

## Understanding the output scores

Each docked pose has 3 scores:

| Score | Meaning | Better when |
|-------|---------|-------------|
| `minimizedAffinity` | Binding free energy (kcal/mol) | More negative |
| `CNNscore` | CNN predicted binding probability (0–1) | Higher |
| `CNNaffinity` | CNN predicted binding affinity (pKd) | Higher |

---

## Files in this repo

| File | Description |
|------|-------------|
| `gnina_auto_split.sh` | Main sbatch script — splits SDF and dispatches to all nodes/GPUs |
| `node_runner.sh` | Per-node runner — assigns 1 gnina instance per GPU using `CUDA_VISIBLE_DEVICES` |
| `split_sdf.py` | Python script to split SDF file into N equal chunks |

---

## Resource Configuration

Tested on 3-node × 4-GPU cluster:

```bash
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

---

## Requirements

- Slurm workload manager
- Singularity
- gnina Singularity image (`gnina_v1.3.2.sif` or later)
- Python 3
