#!/bin/bash
#SBATCH --job-name="Si-scf"
#SBATCH --nodes=1
#SBATCH --ntasks=10
#SBATCH --time=0-00:10:00
#SBATCH -p skx-dev
#SBATCH --output="slurm-%j.out"
#SBATCH --error="slurm-%j.err"
#SBATCH --mail-type=END
#SBATCH --mail-user=netid@cornell.edu
#SBATCH -A TG-MAT250061

results_folder=$SCRATCH/Si_tetragonal_etam0p002
results_folder_final_name=$SCRATCH/Q2A_si
mkdir $results_folder
work_results_folder=$WORK/Si_scf
mkdir $work_results_folder

cp * $results_folder
cd $results_folder

echo "Starting $SLURM_JOBID at `date` on `hostname`"
echo "Current directory: $PWD"

set -x

PREFIX="Si_tetragonal_etam0p002"
PSEUDO_DIR="/scratch/11018/zhc/Assisgnment2/Q1/1A/energy_cutoff_test/"
INFILE="$PREFIX.in"
OUTFILE="$PREFIX.out"

cat > $INFILE << EOF
&CONTROL
 calculation = 'scf',
 restart_mode = 'from_scratch',
 prefix='$PREFIX',
 pseudo_dir='$PSEUDO_DIR',
 tstress=.true.,
 tprnfor=.true.,
/
&SYSTEM
 ibrav=0,
 celldm(1)=10.2d0,
 nat=2,
 ntyp=1,
 nbnd=8,
 ecutwfc=30,
 ecutrho=450,
 occupations = 'fixed',
 use_all_frac = .true.,
/
&ELECTRONS
 conv_thr = 1.0D-8,
 mixing_mode = 'plain',
 mixing_beta = 0.7d0,
 diagonalization = 'cg',
/
ATOMIC_SPECIES
Si 28.0855d0 Si_LDA.UPF

ATOMIC_POSITIONS crystal
Si 0.d0 0.d0 0.d0
Si 0.25d0 0.25d0 0.25d0

K_POINTS automatic
 12 12 12 0 0 0

CELL_PARAMETERS alat
-0.499000000000d0  0.000000000000d0  0.502000000000d0
 0.000000000000d0  0.499000000000d0  0.502000000000d0
-0.499000000000d0  0.499000000000d0  0.000000000000d0
EOF

module purge
module load intel/24.0 impi/21.11
module load qe/7.3
module list

ibrun pw.x < $INFILE > $OUTFILE

rm *.igk *.wfc*
rm -r *.save

mv $results_folder $results_folder_final_name
cd $SLURM_SUBMIT_DIR
mv slurm-$SLURM_JOB_ID* $results_folder_final_name

cp -rp $results_folder_final_name $work_results_folder
echo "End: `date` on `hostname`"

