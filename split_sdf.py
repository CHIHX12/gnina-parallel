import sys
import os

infile = sys.argv[1]
outdir = sys.argv[2]
n_gpu  = int(sys.argv[3])

os.makedirs(outdir, exist_ok=True)

records = []
current = []
with open(infile) as f:
    for line in f:
        current.append(line)
        if line.strip() == '$$$$':
            records.append(current)
            current = []

total   = len(records)
per_gpu = (total + n_gpu - 1) // n_gpu
print(f"    分割: {total} 配體 → {n_gpu} ファイル（各最大 {per_gpu} 個）")

for i in range(n_gpu):
    chunk = records[i*per_gpu:(i+1)*per_gpu]
    if not chunk:
        print(f"    split_{i+1:02d}.sdf: 0 配體（スキップ）")
        continue
    with open(f"{outdir}/split_{i+1:02d}.sdf", 'w') as out:
        for rec in chunk:
            out.writelines(rec)
    print(f"    split_{i+1:02d}.sdf: {len(chunk)} 配體")
