#!/bin/bash
# gen_bn.sh ח genrate bn_20.sh to bn_100.sh,and make batch command main.sh

# delete exist main.sh
rm -f main.sh

for para in {20..100..10}; do
    newfile="cto_${para}.sh"
    cp cto.sh "$newfile"

# change the ecut
    sed -i "s/ecutwfc *= *[0-9]\+/ecutwfc=${para}/" "$newfile"
    sed -i "s/ecutrho *= *[0-9]\+/ecutrho=$((para*10))/" "$newfile"

# change the output name
    sed -i "s/PREFIX *= *\"CTO_[0-9]\+\"/PREFIX=\"CTO_${para}\"/" "$newfile"

# uodate the task to main.sh
    echo "sbatch $newfile" >> main.sh
done
