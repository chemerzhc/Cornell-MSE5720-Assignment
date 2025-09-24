#!/bin/bash
# gen_k.sh — Generate cto_k2.sh to cto_k12.sh from cto.sh template
# This script will:
# 1. Copy cto.sh to ct_dis_k${k}.sh (2 ≤ k ≤ 12, step 1)
# 2. Update K_POINTS automatic (k k k 0 0 0)
# 3. Update PREFIX and results_folder
# 4. Create main.sh that submits all jobs with a 3-second delay

rm -f main.sh

for k in {2..12}; do
    newfile="cto_dis_k${k}.sh"
    cp cto.sh "$newfile"

    new_prefix="CTO_DIS_K${k}"
    new_folder="\$SCRATCH/${new_prefix}"

    sed -i "s/^K_POINTS automatic.*/K_POINTS automatic\n  ${k} ${k} ${k} 0 0 0/" "$newfile"

    sed -i "s/^PREFIX *= *.*/PREFIX=\"${new_prefix}\"/" "$newfile"

    sed -i "s|^results_folder *= *.*|results_folder=${new_folder}|" "$newfile"

    echo "sbatch $newfile" >> main.sh
    echo "sleep 60" >> main.sh
done
