#!/bin/bash
# gen.sh — generate tetragonal-deformed job scripts by replacing CELL_PARAMETERS (angstrom)
# - Reads original CELL_PARAMETERS angstrom (3 lines) from TEMPLATE
# - Applies tetragonal strain: sx = 1+eta (applied to x & y), sz = 1-2*eta (applied to z)
# - Replaces the original 3 lines with the strained ones (in Å)
# - Ensures ibrav=0 (explicit CELL_PARAMETERS requires ibrav=0)
# - Produces one pto_tetragonal_eta...sh and appends its "sbatch ..." to main.sh

set -euo pipefail

TEMPLATE="pto.sh"
if [[ ! -f "$TEMPLATE" ]]; then
  echo "❌ ERROR: Template $TEMPLATE not found!"
  exit 1
fi

# strains (tetragonal)
etas=(-0.006 -0.004 -0.002 0.0 0.002 0.004 0.006)

# helper: format to QE style with d0 suffix and 12 decimal places
fmt() {
  awk -v v="$1" 'BEGIN{printf "%.12fd0", v}'
}

# extract original CELL_PARAMETERS angstrom (3 numeric lines) from template
# This will read the first occurrence of "CELL_PARAMETERS" followed by three non-empty lines
read_original_cell() {
  awk '
    BEGIN{found=0; cnt=0}
    /^CELL_PARAMETERS[[:space:]]*angstrom/ { found=1; next }
    found && NF>0 && cnt<3 { print; cnt++ }
    found && cnt==3 { exit }
  ' "$TEMPLATE"
}

orig_cell_lines=()
while IFS= read -r line; do
  orig_cell_lines+=("$line")
done < <(read_original_cell)

if [[ "${#orig_cell_lines[@]}" -ne 3 ]]; then
  echo "❌ Could not find 3 CELL_PARAMETERS lines in $TEMPLATE. Aborting."
  exit 1
fi

# parse the 3 vectors into arrays (as decimal numbers)
for i in 0 1 2; do
  read -r ax ay az <<< "$(awk '{printf "%0.12f %0.12f %0.12f", $1, $2, $3}' <<< "${orig_cell_lines[$i]}")"
  eval "a${i}x=$ax"
  eval "a${i}y=$ay"
  eval "a${i}z=$az"
done

# create main.sh
rm -f main.sh
echo "#!/bin/bash" > main.sh
echo "" >> main.sh

for eta in "${etas[@]}"; do
  eta_dir=$(echo "$eta" | sed 's/-/m/; s/\./p/')
  newfile="pto_tetragonal_eta${eta_dir}.sh"

  # copy template
  cp "$TEMPLATE" "$newfile"

  # compute strain factors
  sx=$(awk -v e="$eta" 'BEGIN{printf "%.12f", 1+e}')
  sz=$(awk -v e="$eta" 'BEGIN{printf "%.12f", 1-2*e}')

  # compute new lattice vectors
  v0x=$(awk -v ax="$a0x" -v sx="$sx" 'BEGIN{printf "%.12f", ax*sx}')
  v0y=$(awk -v ay="$a0y" -v sx="$sx" 'BEGIN{printf "%.12f", ay*sx}')
  v0z=$(awk -v az="$a0z" -v sz="$sz" 'BEGIN{printf "%.12f", az*sz}')

  v1x=$(awk -v ax="$a1x" -v sx="$sx" 'BEGIN{printf "%.12f", ax*sx}')
  v1y=$(awk -v ay="$a1y" -v sx="$sx" 'BEGIN{printf "%.12f", ay*sx}')
  v1z=$(awk -v az="$a1z" -v sz="$sz" 'BEGIN{printf "%.12f", az*sz}')

  v2x=$(awk -v ax="$a2x" -v sx="$sx" 'BEGIN{printf "%.12f", ax*sx}')
  v2y=$(awk -v ay="$a2y" -v sx="$sx" 'BEGIN{printf "%.12f", ay*sx}')
  v2z=$(awk -v az="$a2z" -v sz="$sz" 'BEGIN{printf "%.12f", az*sz}')

  new_block="$(fmt "$v0x") $(fmt "$v0y") $(fmt "$v0z")"$'\n'"$(fmt "$v1x") $(fmt "$v1y") $(fmt "$v1z")"$'\n'"$(fmt "$v2x") $(fmt "$v2y") $(fmt "$v2z")"

  # replace CELL_PARAMETERS block
  awk -v newblk="$new_block" '
    BEGIN{skipping=0; printed=0}
    {
      if ($0 ~ /^CELL_PARAMETERS[[:space:]]*angstrom/ && !printed) {
        skipping=1
        cnt=0
        print "CELL_PARAMETERS angstrom"
        split(newblk, lines, "\n")
        for (i in lines) print lines[i]
        printed=1
        next
      }
      if (skipping) {
        if (NF>0) { cnt++; if(cnt>=3){skipping=0} }
        next
      }
      print
    }' "$newfile" > tmp && mv tmp "$newfile"

  # ensure ibrav=0
  sed -i -E 's/ibrav[[:space:]]*=[[:space:]]*[^,]*,/ibrav=0,/' "$newfile"

  # modify results folder for this eta
  OUTDIR="\$SCRATCH/pto_tetragonal_eta${eta_dir}"
  sed -i -E "s|(results_folder=)\\\$SCRATCH/[^[:space:]]+|\1$OUTDIR|" "$newfile"

  # update PREFIX
  sed -i -E "s|^(PREFIX=).*|\1\"pto_tetragonal_eta${eta_dir}\"|" "$newfile"

  # append sbatch command to main.sh
  echo "sbatch $newfile" >> main.sh
  echo "sleep 60" >> main.sh

  echo "Generated $newfile (eta=$eta)"
done

chmod +x main.sh
echo "✅ All tetragonal scripts generated; run ./main.sh to submit."
