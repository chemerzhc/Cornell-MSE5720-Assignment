#!/bin/bash
# gen_k.sh — Generate cto_k2.sh to cto_k12.sh from cto.sh template
# This script will:
# 1. Copy cto.sh to cto_k${k}.sh (2 ≤ k ≤ 12, step 1)
# 2. Update K_POINTS automatic (k k k 0 0 0)
# 3. Update PREFIX and results_folder
# 4. Create main.sh that submits all jobs with a 3-second delay

# Remove old main.sh if it exists
rm -f main.sh

for k in {2..12}; do
    newfile="cto_k${k}.sh"
    cp cto.sh "$newfile"

    # Update K_POINTS line
    sed -i "s/K_POINTS automatic.*/K_POINTS automatic\\n  ${k} ${k} ${k} 0 0 0/" "$newfile"

    # Update PREFIX
    sed -i "s/PREFIX *= *\"CTO_[0-9a-zA-Z_]\+\"/PREFIX=\"CTO_K${k}\"/" "$newfile"

    # Update results_folder path
    sed -i "s|results_folder *= *\$SCRATCH/cto_[0-9a-zA-Z_]\+|results_folder=\$SCRATCH/cto_k${k}|" "$newfile"

    # Append submission command and delay to main.sh
    echo "sbatch $newfile" >> main.sh
    echo "sleep 10" >> main.sh
done
