#!/bin/bash

cd baselines || exit
sbatch run_baselines.sh

cd ../monte_carlo || exit
sbatch run_monte_carlo.sh

cd ../sensitivity || exit
sbatch run_sensitivity.sh
