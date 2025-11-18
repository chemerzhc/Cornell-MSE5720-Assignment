#!/bin/bash
# gen.sh — generate QE scripts for all 6 elastic T matrices × η sweep

set -euo pipefail

TEMPLATE="pto.sh"
if [[ ! -f "$TEMPLATE" ]]; then
  echo "❌ ERROR: Template $TEMPLATE not found!"
  exit 1
fi

# η sweep values
etas=(-0.006 -0.004 -0.002 0.0 0.002 0.004 0.006)

# =============================================================
# 6 T MATRICES FROM TABLE (YOU CAN EDIT ANY OF THEM)
# =============================================================
declare -A Tmats

# T1
Tmats[T1]="1 0 0  0 0 0  0 0 0"
# T2
Tmats[T2]="1 0 0  0 -1 0  0 0 0"
# T3
Tmats[T3]="0 0 0  0 0 0  0 0 1"
# T4
Tmats[T4]="1 0 0  0 0 0  0 0 -1"
# T5
Tmats[T5]="0 0 0.5   0 0.5 0   0.5 0 0"
# T6
Tmats[T6]="0 0.5 0   0.5 0 0   0 0 0"
# =============================================================

# Format output as QE "d0"
fmt() { awk -v v="$1" 'BEGIN{printf "%.12fd0", v}'; }

# Extract original CELL_PARAMETERS
read_original_cell() {
  awk '
    BEGIN{found=0; c=0}
    /^CELL_PARAMETERS[[:space:]]*angstrom/ {found=1; next}
    found && NF>0 && c<3 {print; c++}
    c==3{exit}
  ' "$TEMPLATE"
}

orig=()
while IFS= read -r L; do orig+=("$L"); done < <(read_original_cell)

# Parse original A0 A1 A2
for i in 0 1 2; do
    read -r ax ay az <<< "$(awk '{printf "%f %f %f",$1,$2,$3}' <<< "${orig[$i]}")"
    eval "A${i}x=$ax"
    eval "A${i}y=$ay"
    eval "A${i}z=$az"
done

# Create main.sh
rm -f main.sh
echo "#!/bin/bash" > main.sh
echo >> main.sh

# =============================================================
# MAIN LOOPS: T1–T6 and all η
# =============================================================
for Tname in T1 T2 T3 T4 T5 T6; do
    
    echo "Processing $Tname ..."

    read -r T00 T01 T02 T10 T11 T12 T20 T21 T22 <<< "${Tmats[$Tname]}"

    for eta in "${etas[@]}"; do

        eta_dir=$(echo "$eta" | sed 's/-/m/; s/\./p/')
        newfile="pto_${Tname}_eta${eta_dir}.sh"
        script_base="${newfile%.sh}"

        cp "$TEMPLATE" "$newfile"

        # Compute A' = A + ηT
        new_block=""
        for i in 0 1 2; do
            ax=$(eval echo "\$A${i}x")
            ay=$(eval echo "\$A${i}y")
            az=$(eval echo "\$A${i}z")

            Tx=$(eval echo "\$T${i}0")
            Ty=$(eval echo "\$T${i}1")
            Tz=$(eval echo "\$T${i}2")

            nx=$(awk -v a="$ax" -v t="$Tx" -v e="$eta" 'BEGIN{print a + e*t}')
            ny=$(awk -v a="$ay" -v t="$Ty" -v e="$eta" 'BEGIN{print a + e*t}')
            nz=$(awk -v a="$az" -v t="$Tz" -v e="$eta" 'BEGIN{print a + e*t}')

            new_block+="$(fmt "$nx") $(fmt "$ny") $(fmt "$nz")"$'\n'
        done

        # Replace CELL_PARAMETERS
        awk -v block="$new_block" '
          BEGIN{skip=0; c=0}
          {
            if ($0 ~ /^CELL_PARAMETERS/) {
              print "CELL_PARAMETERS angstrom"
              split(block, L, "\n")
              for (i in L) if (L[i]!="") print L[i]
              skip=1; c=0; next
            }
            if (skip) {
              if (NF>0) {c++; if(c>=3) skip=0}
              next
            }
            print
          }
        ' "$newfile" > tmp && mv tmp "$newfile"

        # Fix ibrav
        sed -i -E 's/ibrav *= *[^,]*,/ibrav=0,/' "$newfile"

        # Replace PREFIX
        sed -i -E "s|^(PREFIX=).*|\1\"${script_base}\"|" "$newfile"

        # Replace output folder
        sed -i -E "s|^(results_folder=).*$|\1\$SCRATCH/${script_base}|" "$newfile"

        # Add job to main.sh
        echo "sbatch $newfile" >> main.sh
        echo "sleep 60" >> main.sh

        echo "Generated  $newfile"

    done
done

chmod +x main.sh
echo "✅ All scripts created. Run ./main.sh to submit!"
