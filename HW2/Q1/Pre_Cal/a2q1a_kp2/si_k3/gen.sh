#!/bin/bash
# gen_kpoints.sh — Generate si_k1.sh ... si_k12.sh from si_en.sh template
# Only change PREFIX, results_folder, and K_POINTS automatic line

set -euo pipefail

rm -f main.sh
echo "#!/bin/bash" > main.sh
echo "" >> main.sh

TEMPLATE="si_kp.sh"
if [[ ! -f "$TEMPLATE" ]]; then
  echo "ERROR: Template $TEMPLATE not found!" >&2
  exit 1
fi

for k in {1..12}; do
    newfile="si_k${k}.sh"
    cp "$TEMPLATE" "$newfile"

    # 修改 PREFIX
    sed -E -i "s|([[:space:]]*PREFIX[[:space:]]*=[[:space:]]*)['\"]?[^'\"[:space:]]+['\"]?|\1\"Si_k${k}\"|I" "$newfile"

    # 修改 results_folder
    sed -E -i "s|(results_folder[[:space:]]*=[[:space:]]*)\\\$SCRATCH/[^[:space:]]+|\1\\\$SCRATCH/si_k${k}|I" "$newfile"

    # 修改 K_POINTS automatic 这一行
    sed -E -i "s/(K_POINTS[[:space:]]+automatic[[:space:]]*)[0-9]+[[:space:]]+[0-9]+[[:space:]]+[0-9]+/\1${k} ${k} ${k}/" "$newfile"

    # 追加提交命令
    echo "sbatch $newfile" >> main.sh
    echo "sleep 20" >> main.sh

    # 检查是否替换成功
    echo "Generated $newfile:"
    grep -E "PREFIX|results_folder|K_POINTS" "$newfile"
    echo "--------------------------------------"
done

chmod +x main.sh
echo "All si_k*.sh scripts generated and main.sh created."

