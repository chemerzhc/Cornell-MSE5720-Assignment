#!/bin/bash
set -euo pipefail

# gen_celldm_index.sh
# Vary celldm(1) around 7.3573 by ±5% with 12 points.
# Jobs are named by simple indices: 1..12

base_value=7.2015
num_points=20
start=-0.05
end=0.05

rm -f main.sh
> main.sh

# compute offsets and values
declare -a offsets values
for i in $(seq 0 $((num_points-1))); do
    offsets[$i]=$(awk -v i=$i -v n=$num_points -v s=$start -v e=$end \
        'BEGIN{printf "%.12f", s + (e - s)*i/(n-1)}')
    values[$i]=$(awk -v b=$base_value -v o="${offsets[$i]}" \
        'BEGIN{printf "%.7f", b*(1+o)}')
done

echo "Index  offset(%)      celldm(1)"
for i in $(seq 0 $((num_points-1))); do
    idx=$((i+1))
    printf "%2d   % .6f   % .7f\n" "$idx" "${offsets[$i]}" "${values[$i]}"
done
echo

# generate scripts
for i in $(seq 0 $((num_points-1))); do
    idx=$((i+1))
    val=${values[$i]}
    newfile="cto_module_${idx}.sh"

    cp cto.sh "$newfile"
    sed -i.bak -E "s/^[[:space:]]*celldm\\(1\\)[[:space:]]*=.*$/celldm(1)=${val}d0/" "$newfile"
    sed -i.bak "s/^PREFIX[[:space:]]*=.*/PREFIX=\"CTO_module_${idx}\"/" "$newfile"
    sed -i.bak "s|^results_folder[[:space:]]*=.*|results_folder=\\\$SCRATCH/cto_${idx}|" "$newfile"

    echo "sbatch $newfile" >> main.sh
    echo "sleep 60" >> main.sh
done

echo "Done. Generated $num_points jobs."
echo "main.sh created. To submit run: bash main.sh"
