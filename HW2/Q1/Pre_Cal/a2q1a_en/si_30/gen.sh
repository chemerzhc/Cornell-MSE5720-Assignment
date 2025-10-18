#!/bin/bash
# gen_bn.sh — Generate si_20.sh ... si_100.sh from si_en.sh template

set -euo pipefail

# Remove old main.sh if it exists
rm -f main.sh
echo "#!/bin/bash" > main.sh
echo "" >> main.sh

TEMPLATE="si_en.sh"
if [[ ! -f "$TEMPLATE" ]]; then
  echo "ERROR: template $TEMPLATE not found" >&2
  exit 1
fi

for para in {20..100..10}; do
    newfile="si_${para}.sh"
    cp "$TEMPLATE" "$newfile"

    # Replace ecutwfc = <number>
    sed -E -i "s/([[:space:]]*ecutwfc[[:space:]]*=[[:space:]]*)[0-9]+/\1${para}/I" "$newfile"

    # Replace ecutrho = <number>  (here using para*15 as in your script; change if needed)
    sed -E -i "s/([[:space:]]*ecutrho[[:space:]]*=[[:space:]]*)[0-9]+/\1$((para*15))/I" "$newfile"

    # Replace PREFIX = "..."  (handles single or double quotes or no quotes)
    sed -E -i "s|([[:space:]]*PREFIX[[:space:]]*=[[:space:]]*)['\"]?[^'\"[:space:]]+['\"]?|\1\"Si_${para}\"|I" "$newfile"

    # Replace results_folder = $SCRATCH/whatever  (handles paths with underscores)
    sed -E -i "s|(results_folder[[:space:]]*=[[:space:]]*)\\\$SCRATCH/[^[:space:]]+|\1\\\$SCRATCH/si_${para}|I" "$newfile"

    # Make the generated script executable
    chmod +x "$newfile"

    # Append submission command and small delay to main.sh (3s)
    echo "sbatch $newfile" >> main.sh
    echo "sleep 3" >> main.sh

    # --- quick checks: print a short snippet to confirm replacements (can be commented out later) ---
    echo "Generated $newfile :"
    grep -E "ecutwfc|ecutrho|PREFIX|results_folder" "$newfile" || true
    echo "----------------------------------------"
done

chmod +x main.sh
echo "Done. Generated main.sh and si_*.sh files."
