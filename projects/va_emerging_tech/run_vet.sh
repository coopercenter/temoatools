#!/bin/bash
#SBATCH -N 1
#SBATCH --cpus-per-task=20
#SBATCH -t 6:00:00
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
python vet_process_and_combine_results.py
python vet_run_sensitivity.py

# create plots in Python
#cd figures
#python plot_Fig4_yearly_demand_emission_constraint.py
#python plot_Fig7_2050_capacity_emerging_storage.py
#python plot_Fig8_2050_capacity_emerging_NET.py
