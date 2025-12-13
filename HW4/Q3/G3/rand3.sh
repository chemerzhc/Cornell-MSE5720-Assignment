#!/bin/bash	  
#SBATCH -J CCO_Q3	 	# Job Name
#SBATCH -o CCO.o%j	 # Name of the error and output files (%j appends the jobID)
#SBATCH -N 2             # Requests nodes
#SBATCH -n 120	         # Requests number of tasks, in multiples of 16 
#SBATCH -p normal	 # Queue name: development (max 1 hr walltime) or normal
#SBATCH -t 20:00:00	 # Run time (hh:mm:ss) 
#SBATCH -A TG-BIO210063
set -x	 # Echo commands, use set echo with csh

PREFIX="CCOrand3"
PSEUDO_DIR="./"
INFILE="$PREFIX.in"
OUTFILE="$PREFIX.out"

# deform_list="0.65 0.69 0.72"
# for cnum in $deform_list
# do
cat > CCO.rand3.in << EOF
&CONTROL
 calculation = 'relax',
 restart_mode = 'from_scratch',
 prefix='$PREFIX',
 pseudo_dir='$PSEUDO_DIR',
 tstress=.true.,
 tprnfor=.true.,
/
&SYSTEM
 ibrav=5,
 celldm(1)=11.8795,
 celldm(4)=0.6671,
 nat=10,
 ntyp=3,
 ecutwfc=70,
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
 press=0.1d0,
/
ATOMIC_SPECIES
 Ca 40.078d0 Ca_PBE.UPF
 C 12.0107d0 C_PBE.UPF
 O 16.00d0 O_PBE.UPF

ATOMIC_POSITIONS (crystal)
Ca       0.500000000   0.500000000   0.500000000
Ca       0.000000000  -0.000000000   0.000000000
C        0.250000000   0.250000000   0.250000000
C        0.750000000   0.750000000   0.750000000
O        0.507016955   0.992983045   0.250000000
O        0.992983045   0.250000000   0.507016955
O        0.250000000   0.507016955   0.992983045
O        0.007016955   0.750000000   0.492983045
O        0.750000000   0.492983045   0.007016955
O        0.492983045   0.007016955   0.750000000

K_POINTS automatic
  5 5 5 0 0 0
EOF

# module load intel/19.1.1
# module load mvapich2/2.3.6
# module load impi/19.0.7
# module load qe/7.0

module load intel/17.0.4
module load impi/17.0.3
module load qe/6.4.1

ibrun pw.x < CCO.rand3.in > CCO.rand3.out # Run the executable named pw.x 


INFILE="$PREFIX.phon_rand3.in"
OUTFILE="$PREFIX.phon_rand3.out"

cat > $INFILE << EOF
Phonons of CaCO3
&inputph
 tr2_ph=1.0d-16,
 amass(1)=40.078d0,
 amass(2)=12.0107d0,
 amass(3)=15.999d0,
 ldisp=.false.,
 epsil=.true.,
 prefix='$PREFIX',
 fildyn='calcite.rand3.dyn',
/
0.d0 0.d0 0.d0
EOF

ibrun ph.x -ndiag 1 < $INFILE > $OUTFILE # Run the executable named ph.x


rm *.igk *.wfc*
rm -r *.save
rm -r _ph0
