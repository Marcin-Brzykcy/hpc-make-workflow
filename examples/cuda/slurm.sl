#!/bin/bash -l
#SBATCH --job-name=cuda-example
#SBATCH --output=output.txt
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --gres=gpu:1
#SBATCH --time=00:02:00
#SBATCH --mem=1G

set -e
srun ./cuda-example
