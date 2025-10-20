#!/bin/bash
# gen.sh — Generate Diamond/Si deformation scripts
# Inserts CELL_PARAMETERS block *after* K_POINTS automatic section

set -euo pipefail

TEMPLATE="diamond.sh"
if [[ ! -f "$TEMPLATE" ]]; then
  echo "❌ ERROR: Template $TEMPLATE not found!"
  exit 1
fi

# Deformation types and values
deformations=("isotropic" "tetragonal" "trigonal")
etas=(-0.006 -0.004 -0.002 0.0 0.002 0.004 0.006)

# Base lattice vectors in alat units (diamond)
a1=(-0.50 0.50 0.50)
a2=(0.50 -0.50 0.50)
a3=(0.50 0.50 -0.50)

# Functions to generate deformed CELL_PARAMETERS
cell_isotropic() {
  eta="$1"
  s=$(awk -v e="$eta" 'BEGIN{print 1+e}')
  awk -v s="$s" -v a1x="${a1[0]}" -v a1y="${a1[1]}" -v a1z="${a1[2]}" \
             -v a2x="${a2[0]}" -v a2y="${a2[1]}" -v a2z="${a2[2]}" \
             -v a3x="${a3[0]}" -v a3y="${a3[1]}" -v a3z="${a3[2]}" \
    'BEGIN{
      printf "% .12fd0 % .12fd0 % .12fd0\n", a1x*s,a1y*s,a1z*s;
      printf "% .12fd0 % .12fd0 % .12fd0\n", a2x*s,a2y*s,a2z*s;
      printf "% .12fd0 % .12fd0 % .12fd0\n", a3x*s,a3y*s,a3z*s;
    }'
}

cell_tetragonal() {
  eta="$1"
  sx=$(awk -v e="$eta" 'BEGIN{print 1+e}')
  sz=$(awk -v e="$eta" 'BEGIN{print 1-2*e}')
  awk -v sx="$sx" -v sz="$sz" -v a1x="${a1[0]}" -v a1y="${a1[1]}" -v a1z="${a1[2]}" \
             -v a2x="${a2[0]}" -v a2y="${a2[1]}" -v a2z="${a2[2]}" \
             -v a3x="${a3[0]}" -v a3y="${a3[1]}" -v a3z="${a3[2]}" \
    'BEGIN{
      printf "% .12fd0 % .12fd0 % .12fd0\n", a1x*sx,a1y*sx,a1z*sz;
      printf "% .12fd0 % .12fd0 % .12fd0\n", a2x*sx,a2y*sx,a2z*sz;
      printf "% .12fd0 % .12fd0 % .12fd0\n", a3x*sx,a3y*sx,a3z*sz;
    }'
}

cell_trigonal() {
  eta="$1"
  awk -v e="$eta" -v a1x="${a1[0]}" -v a1y="${a1[1]}" -v a1z="${a1[2]}" \
             -v a2x="${a2[0]}" -v a2y="${a2[1]}" -v a2z="${a2[2]}" \
             -v a3x="${a3[0]}" -v a3y="${a3[1]}" -v a3z="${a3[2]}" \
    'BEGIN{
      ax=a1x+e*a1y/2; ay=a1y+e*a1x/2; az=a1z;
      bx=a2x+e*a2y/2; by=a2y+e*a2x/2; bz=a2z;
      cx=a3x+e*a3y/2; cy=a3y+e*a3x/2; cz=a3z;
      printf "% .12fd0 % .12fd0 % .12fd0\n", ax,ay,az;
      printf "% .12fd0 % .12fd0 % .12fd0\n", bx,by,bz;
      printf "% .12fd0 % .12fd0 % .12fd0\n", cx,cy,cz;
    }'
}

# Remove old main.sh
rm -f main.sh
echo "#!/bin/bash" > main.sh
echo "" >> main.sh

# Loop over deformations
for def in "${deformations[@]}"; do
  for eta in "${etas[@]}"; do
    eta_dir=$(echo "$eta" | sed 's/-/m/; s/\./p/')
    newfile="diamond_${def}_eta${eta_dir}.sh"
    cp "$TEMPLATE" "$newfile"

    # Replace PREFIX
    sed -E -i "s|^(PREFIX=).*|\1\"diamond_${def}_eta${eta_dir}\"|I" "$newfile"

    # Replace results_folder
    sed -E -i "s|(results_folder=)\\\$SCRATCH/[^[:space:]]+|\1\\\$SCRATCH/diamond_${def}_eta${eta_dir}|I" "$newfile"

    # Generate CELL_PARAMETERS
    case "$def" in
      isotropic) cell_block=$(cell_isotropic "$eta");;
      tetragonal) cell_block=$(cell_tetragonal "$eta");;
      trigonal) cell_block=$(cell_trigonal "$eta");;
    esac

    # Insert CELL_PARAMETERS after K_POINTS block
    awk -v block="$cell_block" '
      BEGIN{inserted=0}
      {
        print
        if ($1=="K_POINTS" && $2=="automatic") {
          getline; print $0; print ""; print "CELL_PARAMETERS alat"; print block; inserted=1
        }
      }
      END{if(!inserted){print "CELL_PARAMETERS alat\n" block}}
    ' "$newfile" > tmp && mv tmp "$newfile"

    echo "sbatch $newfile" >> main.sh
    echo "sleep 10" >> main.sh

    echo "Generated $newfile (η=$eta, $def)"
  done
done

chmod +x main.sh
echo "✅ All Diamond deformation scripts generated. Run ./main.sh to submit."

