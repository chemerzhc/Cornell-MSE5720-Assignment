#!/bin/bash
set -euo pipefail

base_value=7.3573
num_points=20
start=-0.05
end=0.05

rm -f main.sh
> main.sh

for i in $(seq 0 $((num_points-1))); do
    idx=$((i+1))
    offset=$(awk -v i=$i -v n=$num_points -v s=$start -v e=$end 'BEGIN{printf "%.6f", s + (e - s)*i/(n-1)}')
    val=$(awk -v b=$base_value -v o=$offset 'BEGIN{printf "%.7f", b*(1+o)}')

    newfile="cto_module_${idx}.sh"
    cp cto.sh "$newfile"

    sed -i -E "s/^[[:space:]]*celldm\(1\)[[:space:]]*=.*$/celldm(1)=${val}d0/" "$newfile"
    sed -i -E "s/^PREFIX[[:space:]]*=.*/PREFIX=\"CTO_module_${idx}\"/" "$newfile"
    sed -i -E "s|^results_folder[[:space:]]*=.*|results_folder=\$SCRATCH/CTO_module_${idx}|" "$newfile"
    sed -i -E "s|pw.x -in (.*) > .*|pw.x -in \1 > cto_module_${idx}.out|" "$newfile"

    echo "sbatch $newfile" >> main.sh
    echo "sleep 60" >> main.sh
done
