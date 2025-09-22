#!/bin/bash
# gen_bn.sh — Generate bn_20.sh to bn_100.sh from bn_10.sh template
# This script will:
# 1. Copy bn_10.sh to bn_${para}.sh (20 ≤ para ≤ 100, step 10)
# 2. Update parameters (ecutwfc, ecutrho, PREFIX, results_folder)
# 3. Create main.sh that submits all jobs with a 3-second delay

# Remove old main.sh if it exists
rm -f main.sh

for para in {20..100..10}; do
    newfile="cto_${para}.sh"
    cp cto.sh "$newfile"

    # Update ecutwfc to current parameter
    sed -i "s/ecutwfc *= *[0-9]\+/ecutwfc=${para}/" "$newfile"

    # Update ecutrho to 10 × ecutwfc
    sed -i "s/ecutrho *= *[0-9]\+/ecutrho=$((para*10))/" "$newfile"

    # Update PREFIX to match the parameter
    sed -i "s/PREFIX *= *\"CTO_[0-9]\+\"/PREFIX=\"CTO_${para}\"/" "$newfile"

    # Update results_folder path
    sed -i "s|results_folder *= *\$SCRATCH/cto_[0-9]\+|results_folder=\$SCRATCH/cto_${para}|" "$newfile"

    # Append submission command and delay to main.sh
    echo "sbatch $newfile" >> main.sh
    echo "sleep 3" >> main.sh
done
