#!/bin/bash

sbatch pto_tetragonal_etam0p006.sh
sleep 40
sbatch pto_tetragonal_etam0p004.sh
sleep 40
sbatch pto_tetragonal_etam0p002.sh
sleep 40
sbatch pto_tetragonal_eta0p0.sh
sleep 40
sbatch pto_tetragonal_eta0p002.sh
sleep 40
sbatch pto_tetragonal_eta0p004.sh
sleep 40
sbatch pto_tetragonal_eta0p006.sh
sleep 40
