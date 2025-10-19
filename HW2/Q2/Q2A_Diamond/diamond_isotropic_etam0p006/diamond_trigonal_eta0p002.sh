#!/bin/bash
#SBATCH --job-name="diamond" # job name
#SBATCH --nodes=1 #number of nodes (= -N)
#SBATCH --ntasks=10
#SBATCH --time=0-00:10:00 # total time, days-hours:minutes:seconds (can also use hours:minutes:seconds or days-hours or days-hours:minutes:seconds or minutes or minutes:seconds)
#SBATCH -p skx-dev #partition
#SBATCH --output="slurm-%j.out" # Name of output file
#SBATCH --error="slurm-%j.err" # Name of error file
#SBATCH --mail-type=END
#SBATCH --mail-user=netid@cornell.edu
#SBATCH -A TG-MAT250061 #specify allocation for MSE 5720 (project charge code)

#Files are copied from where the job is submitted (in $SCRATCH) to $WORK for storage since $SCRATCH is purged every 10 days
#First create folders to store results in scratch & work

results_folder=$SCRATCH/diamond_trigonal_eta0p002 #MODIFY FOR EACH JOB
results_folder_final_name=$SCRATCH/Diamond_module #MODIFY FOR EACH JOB #Name of folder when job is completed
mkdir $results_folder
work_results_folder=$WORK/Diamond #MODIFY FOR EACH JOB #Folder in $WORK where results are saved
mkdir $work_results_folder


#copy all (input) files in current folder to folder where results will be stored in scratch
cp * $results_folder

#move to folder results will be stored in
cd $results_folder

echo "Starting $SLURM_JOBID at `date` on `hostname`"
echo "Current directory: $PWD"

set -x   # Echo commands, use set echo with csh

PREFIX="diamond_trigonal_eta0p002"
PSEUDO_DIR="/scratch/11018/zhc/Assisgnment2/Q2/Diamond/Diamond/"
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
 disk_io = 'low',
/
&SYSTEM
 ibrav=0,
 celldm(1)=6.672d0,
 nat=2,
 ntyp=1,
 ecutwfc=50,
 ecutrho=500,
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
C 12.011d0 C_LDA.UPF

ATOMIC_POSITIONS
C 0.d0 0.d0 0.d0
C 0.22110230987d0 0.22110230987d0 0.22110230987d0

K_POINTS automatic
  4 4 4 0 0 0

CELL_PARAMETERS alat
-0.501498000000d0  0.501498000000d0  0.502000000000d0
 0.501498000000d0 -0.501498000000d0  0.502000000000d0
 0.502502000000d0  0.502502000000d0 -0.502000000000d0

EOF

#load modules - (based on module spider qe/7.3)
module purge
module load intel/24.0  impi/21.11
module load qe/7.3
module list

#run calculation/simulation 
#main command
ibrun pw.x < $INFILE > $OUTFILE # Run the executable named pw.x

rm *.igk *.wfc*
rm -r *.save


mv $results_folder $results_folder_final_name #rename folder in scratch to final
cd $SLURM_SUBMIT_DIR #move back to home directory
mv slurm-$SLURM_JOB_ID* $results_folder_final_name

#copy results to permanent storage after job is done
echo "Copying results to $work_results_folder to save after job is done"
cp -rp $results_folder_final_name $work_results_folder
echo "End: `date` on `hostname`"

