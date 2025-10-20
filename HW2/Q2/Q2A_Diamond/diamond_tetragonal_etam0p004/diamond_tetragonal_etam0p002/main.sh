#!/bin/bash

sbatch diamond_tetragonal_etam0p006.sh
sleep 10
sbatch diamond_tetragonal_etam0p004.sh
sleep 10
sbatch diamond_tetragonal_etam0p002.sh
sleep 10
sbatch diamond_tetragonal_eta0p0.sh
sleep 10
sbatch diamond_tetragonal_eta0p002.sh
sleep 10
sbatch diamond_tetragonal_eta0p004.sh
sleep 10
sbatch diamond_tetragonal_eta0p006.sh
sleep 10

