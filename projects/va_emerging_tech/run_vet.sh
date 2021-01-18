#!/bin/bash
#SBATCH -N 1
#SBATCH --cpus-per-task=30
#SBATCH -t 20:00:00
#SBATCH -p standard

module purge
module load anaconda

# activate temoa environment
source activate temoa-py3

# if gurobi is available
export PYTHONUTF8=1
module load gurobi

# set the NUM_PROCS env variable for the Python script
export NUM_PROCS=$SLURM_CPUS_PER_TASK

# run
python vet_run_baselines.py
python vet_run_monte_carlo.py
python vet_run_sensitivity.py