#!/bin/bash
#SBATCH --job-name="Si-bands" # job name
#SBATCH --nodes=1 #number of nodes (= -N)
#SBATCH --ntasks=4
#SBATCH --time=0-00:10:00 # total time, days-hours:minutes:seconds (can also use hours:minutes:seconds or days-hours or days-hours:minutes:seconds or minutes or minutes:seconds)
#SBATCH -p skx-dev #partition
#SBATCH --output="slurm-%j.out" # Name of output file
#SBATCH --error="slurm-%j.err" # Name of error file
#SBATCH --mail-type=END
#SBATCH --mail-user=netid@cornell.edu
#SBATCH -A TG-MAT250061 #specify allocation for MSE 5720 (project charge code)

#Files are copied from where the job is submitted (in $SCRATCH) to $WORK for storage since $SCRATCH is purged every 10 days
#First create folders to store results in scratch & work

results_folder=$SCRATCH/bands #MODIFY FOR EACH JOB
results_folder_final_name=$SCRATCH/2abands #MODIFY FOR EACH JOB #Name of folder when job is completed
mkdir $results_folder
work_results_folder=$WORK/Si_bands #MODIFY FOR EACH JOB #Folder in $WORK where results are saved
mkdir $work_results_folder


#copy all (input) files in current folder to folder where results will be stored in scratch
cp * $results_folder

#move to folder results will be stored in
cd $results_folder

echo "Starting $SLURM_JOBID at `date` on `hostname`"
echo "Current directory: $PWD"

set -x   # Echo commands, use set echo with csh

PREFIX="Si_bands"
PSEUDO_DIR="/scratch/11018/zhc/Assisgnment2/Q1/1A/band_cal/"
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
 ibrav=2,
 celldm(1)=10.2d0,
 nat=2,
 ntyp=1,
 nbnd=4,
 ecutwfc=20,
 ecutrho=300,
 occupations = 'fixed',
 use_all_frac = .true.,
/
&ELECTRONS
 conv_thr = 1.0D-8,
 mixing_mode = 'plain',
 mixing_beta = 0.7d0,
 diagonalization = 'cg',
/
&IONS
 ion_dynamics='bfgs',
/
&CELL
 cell_dynamics = 'bfgs',
 press=0.d0,
/
ATOMIC_SPECIES
Si 28.0855d0 Si_LDA.UPF

ATOMIC_POSITIONS crystal
Si 0.d0 0.d0 0.d0
Si 0.25d0 0.25d0 0.25d0

K_POINTS automatic
  12 12 12 0 0 0

EOF

#load modules - (based on module spider qe/7.3)
module purge
module load intel/24.0  impi/21.11
module load qe/7.3
module list

#run calculation/simulation
#main command
ibrun pw.x < $INFILE > $OUTFILE # Run the executable named pw.x

INFILE="$PREFIX.bands.in"
OUTFILE="$PREFIX.bands.out"

cat > $INFILE << EOF
&CONTROL
 calculation = 'bands',
 prefix='$PREFIX',
 pseudo_dir='$PSEUDO_DIR',
/
&SYSTEM
 ibrav=2,
 celldm(1)=10.2d0,
 nat=2,
 ntyp=1,
 nbnd=8,
 ecutwfc=20,
 ecutrho=300,
 occupations = 'fixed',
 use_all_frac = .true.,
/
&ELECTRONS
 conv_thr = 1.0D-8,
 mixing_mode = 'plain',
 mixing_beta = 0.7d0,
 diagonalization = 'cg',
/
&IONS
 ion_dynamics='bfgs',
/
&CELL
 cell_dynamics = 'bfgs',
 press=0.d0,
/
ATOMIC_SPECIES
Si 28.0855d0 Si_LDA.UPF

ATOMIC_POSITIONS crystal
Si 0.d0 0.d0 0.d0
Si 0.25d0 0.25d0 0.25d0

K_POINTS crystal_b 
3
0.5d0 0.5d0 0.5d0 20
0.d0 0.d0 0.d0 20
1.d0 0.d0 0.d0 20

EOF

ibrun pw.x < $INFILE > $OUTFILE # Run the executable named pw.x

INFILE="$PREFIX.plot.in"
OUTFILE="$PREFIX.plot.out"

cat > $INFILE << EOF
&BANDS
 prefix='$PREFIX',
 filband="Si.bandsplot"
/

EOF

ibrun bands.x < $INFILE > $OUTFILE

INFILE="$PREFIX.dos.in"
OUTFILE="$PREFIX.dos.out"

cat > $INFILE << EOF
&DOS
 prefix='$PREFIX',
 fildos='$PREFIX.dos'
 Emin=-8, Emax=18, DeltaE=0.1 
/
EOF

ibrun dos.x < $INFILE > $OUTFILE

INFILE="$PREFIX.pdos.in"
OUTFILE="$PREFIX.pdos.out"

cat > $INFILE << EOF
&PROJWFC
 prefix='$PREFIX',
 Emin=-8, Emax=18, DeltaE=0.1
 filpdos='$PREFIX.pdos',
 filproj='$PREFIX.proj'
/
EOF

ibrun projwfc.x < $INFILE > $OUTFILE


rm *.igk *.wfc*
rm -r *.save

mv $results_folder $results_folder_final_name #rename folder in scratch to final
cd $SLURM_SUBMIT_DIR #move back to home directory
mv slurm-$SLURM_JOB_ID* $results_folder_final_name

#copy results to permanent storage after job is done
echo "Copying results to $work_results_folder to save after job is done"
cp -rp $results_folder_final_name $work_results_folder
echo "End: `date` on `hostname`"

