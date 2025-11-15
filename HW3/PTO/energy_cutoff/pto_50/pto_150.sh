#!/bin/bash
#SBATCH --job-name="pto" # job name
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
results_folder=$SCRATCH/pto_150 #MODIFY FOR EACH JOB
results_folder_final_name=$SCRATCH/PTO #MODIFY FOR EACH JOB #Name of folder when job is completed
mkdir $results_folder
work_results_folder=$WORK/qe_test #MODIFY FOR EACH JOB #Folder in $WORK where results are saved
mkdir $work_results_folder

#copy all (input) files in current folder to folder where results will be stored in scratch
cp * $results_folder

#move to folder results will be stored in
cd $results_folder

echo "Starting $SLURM_JOBID at `date` on `hostname`"
echo "Current directory: $PWD"

set -x   # Echo commands, use set echo with csh

PREFIX="pto_150"
PSEUDO_DIR="/scratch/11018/zhc/assisgnment3/input_files/"
INFILE="$PREFIX.in"
OUTFILE="$PREFIX.out"

cat > $INFILE << EOF
&CONTROL
 calculation = 'relax',
 restart_mode = 'from_scratch',
 prefix="pto_150",
 pseudo_dir='$PSEUDO_DIR',
 tstress=.true.,
 tprnfor=.true.,
/
&SYSTEM
 ibrav=0,
 nat=5,
 ntyp=3,
 ecutwfc=150,
 ecutrho=1500,
 occupations = 'fixed'
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
 Pb 207.2d0 Pb_LDA.UPF
 Ti 47.88d0 Ti_LDA.UPF
 O  16.00d0 O_LDA.UPF

CELL_PARAMETERS angstrom 
   3.9d0   0.000000000   0.000000000
   0.000000000   3.9d0   0.000000000
   0.000000000   0.000000000  4.1d0 

ATOMIC_POSITIONS crystal
Pb       0.000000000d0   0.000000000d0   1.006422508d0
Ti       0.500000000d0   0.500000000d0   0.540423697d0
O        0.500000000d0   0.500000000d0   0.098580301d0
O        0.500000000d0   0.000000000d0   0.610928891d0
O        0.000000000d0   0.500000000d0   0.610928891d0

K_POINTS automatic
  6 6 4 0 0 0

EOF

#load modules - (based on module spider qe/7.3)
module purge
module load intel/24.0  impi/21.11
module load qe/7.3
module list

ibrun pw.x < $INFILE > $OUTFILE # Run the executable named pw.x 

rm *.igk *.wfc* *.xml
rm -r *.save

mv $results_folder $results_folder_final_name #rename folder in scratch to final
cd $SLURM_SUBMIT_DIR #move back to home directory
mv slurm-$SLURM_JOB_ID* $results_folder_final_name

#copy results to permanent storage after job is done
echo "Copying results to $work_results_folder to save after job is done"
cp -rp $results_folder_final_name $work_results_folder
echo "End: `date` on `hostname`"

