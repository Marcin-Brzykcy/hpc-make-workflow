#!/bin/bash -l
#SBATCH --job-name=basic_c
#SBATCH --output=output.txt
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --time=00:01:00
#SBATCH --mem=128M

set -e
srun ./basic_c
