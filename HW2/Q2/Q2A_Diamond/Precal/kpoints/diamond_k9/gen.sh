#!/bin/bash
# gen_kpoints.sh — Generate si_k1.sh ... si_k12.sh from si_kp.sh template
# Modify PREFIX, results_folder, and force replace K_POINTS automatic line

set -euo pipefail

rm -f main.sh
echo "#!/bin/bash" > main.sh
echo "" >> main.sh

TEMPLATE="diamond.sh"
if [[ ! -f "$TEMPLATE" ]]; then
  echo "ERROR: Template $TEMPLATE not found!" >&2
  exit 1
fi

for k in {1..12}; do
    newfile="diamond_k${k}.sh"
    cp "$TEMPLATE" "$newfile"

    # 修改 PREFIX
    sed -E -i "s|([[:space:]]*PREFIX[[:space:]]*=[[:space:]]*)['\"]?[^'\"[:space:]]+['\"]?|\1\"Diamond_k${k}\"|I" "$newfile"

    # 修改 results_folder
    sed -E -i "s|(results_folder[[:space:]]*=[[:space:]]*)\\\$SCRATCH/[^[:space:]]+|\1\\\$SCRATCH/diamond_k${k}|I" "$newfile"

    # === 🔧 改进：处理 K_POINTS automatic 与数字在不同行的情况 ===
    awk -v k="$k" '
      BEGIN {inside=0}
      {
        if ($1=="K_POINTS" && $2=="automatic") {
          print "K_POINTS automatic"
          print "  " k, k, k, "0 0 0"
          inside=1
          next
        }
        if (inside && $1 ~ /^[0-9]/) next
        inside=0
        print
      }
    ' "$newfile" > "${newfile}.tmp" && mv "${newfile}.tmp" "$newfile"
    # === 🔧 结束 ===

    # 添加到 main.sh
    echo "sbatch $newfile" >> main.sh
    echo "sleep 20" >> main.sh

    echo "Generated $newfile:"
    grep -E "PREFIX|results_folder|K_POINTS" "$newfile"
    echo "--------------------------------------"
done

chmod +x main.sh
echo "✅ All si_k*.sh scripts generated and main.sh created."

