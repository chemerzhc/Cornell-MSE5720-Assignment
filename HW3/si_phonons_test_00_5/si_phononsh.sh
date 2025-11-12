#!/bin/bash
#SBATCH --job-name="Si-phonons" # job name
#SBATCH --nodes=1 #number of nodes (= -N)
#SBATCH --ntasks=10
#SBATCH --time=0-00:40:00 # total time, days-hours:minutes:seconds (can also use hours:minutes:seconds or days-hours or days-hours:minutes:seconds or minutes or minutes:seconds)
#SBATCH -p skx-dev #partition
#SBATCH --output="slurm-%j.out" # Name of output file
#SBATCH --error="slurm-%j.err" # Name of error file
#SBATCH -A TG-MAT250061 #specify allocation for MSE 5720 (project charge code)

#Files are copied from where the job is submitted (in $SCRATCH) to $WORK for storage since $SCRATCH is purged every 10 days
#First create folders to store results in scratch & work

results_folder=$SCRATCH/si_phonons_test_00_5 #MODIFY FOR EACH JOB
results_folder_final_name=$SCRATCH/si_phonons_results_00_5#MODIFY FOR EACH JOB #Name of folder when job is completed
mkdir $results_folder
work_results_folder=$WORK/Si_phonons #MODIFY FOR EACH JOB #Folder in $WORK where results are saved
mkdir $work_results_folder


#copy all (input) files in current folder to folder where results will be stored in scratch
cp * $results_folder

#move to folder results will be stored in
cd $results_folder

echo "Starting $SLURM_JOBID at `date` on `hostname`"
echo "Current directory: $PWD"

set -x   # Echo commands, use set echo with csh

PREFIX="Si"
PSEUDO_DIR="/scratch/11018/zhc/Assisgnment2/Q2/Si/"
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
 celldm(1)=10.032d0,
 nat=2,
 ntyp=1,
 ecutwfc=50,
 ecutrho=500,
 occupations = 'fixed',
/
&ELECTRONS
 conv_thr = 1.0D-08,
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
  8 8 8 0 0 0

EOF

#load modules - (based on module spider qe/7.3)
module purge
module load intel/24.0  impi/21.11
module load qe/7.3
module list

#run calculation/simulation
#main command
ibrun pw.x < $INFILE > $OUTFILE # Run the executable named pw.x

INFILE="$PREFIX.phon.in"
OUTFILE="$PREFIX.phon.out"

cat > $INFILE << EOF
Phonons of Si
&inputph
tr2_ph=1.0d-16,
amass(1)=28.0855d0,
ldisp=.true.,
nq1=4,nq2=4,nq3=4,
prefix='$PREFIX',
fildyn='silicon.dyn',
/

EOF

ibrun ph.x < $INFILE > $OUTFILE # Run the executable named ph.x

rm *.igk *.wfc*
rm -r *.save

mv $results_folder $results_folder_final_name #rename folder in scratch to final
cd $SLURM_SUBMIT_DIR #move back to home directory
mv slurm-$SLURM_JOB_ID* $results_folder_final_name

#copy results to permanent storage after job is done
echo "Copying results to $work_results_folder to save after job is done"
cp -rp $results_folder_final_name $work_results_folder
echo "End: `date` on `hostname`"

