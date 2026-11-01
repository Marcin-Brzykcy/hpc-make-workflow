#!/bin/bash -l
#SBATCH --job-name=openmp-example
#SBATCH --output=output.txt
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --time=00:01:00
#SBATCH --mem=128M

set -e
for threads in 1 2 4; do
    export OMP_NUM_THREADS=$threads
    echo "Running with $OMP_NUM_THREADS thread(s)"
    srun ./openmp
done
