# ======================================================================================================================
# monte_carlo_run.py
# Jeff Bennett, jab6ft@virginia.edu
#
# This script provides an example of using Temoatools to build and run Monte Carlo simluations using Temoa models.
# The approach remains from the baselines example to build models from two .xlsx files. The first
# provides all possible system and technology data (named data.xlsx in the example). The second specifies scenarios
# that make use of specified combinations of technology data (named Scenarios.xlsx in the example).
#
# Required inputs (lines 106-116)
#   temoa_path - path to Temoa directory that contains temoa_model/
#   project_path - path to directory that contains this file (expects a subdirectory within named data)
#   modelInputs_XLSX_list - list that contains the *.xlsx file with model data (within data subdirectory)
#   scenarioInputs - identifies which technologies are used for each scenario (within data subdirectory)
#   scenarioNames_list - names of each scenario to perform a monte carlo simulation with (named within ScenarioInputs)
#   sensitivityInputs - identifies which parameters to vary in monte carlo study
#   sensitivityMultiplier - percent perturbation for each sensitivity variable
#   ncpus - number of cores to use, -1 for all, -2 for all but one, replace with int(os.getenv('NUM_PROCS')) for cluster
#   solver - leave as '' to use system default, other options include 'cplex', 'gurobi'
#   n_cases - number of simulations to run
#
# Outputs (paths are all relative to project_path)
#   data/data.db - universal database that contains input data in a .sqlite database
#   configs/config_*.txt - a separate configuration file for each Temoa run
#   databases/*.dat - a separate .sqlite database for each Temoa run
#   databases/*.sqlite - a separate .sqlite database for each Temoa run
# ======================================================================================================================
import os
from joblib import Parallel, delayed, parallel_backend
import pandas as pd
import temoatools as tt


# =======================================================
# Function to evaluate a single model
# =======================================================
def evaluateMonteCarlo(modelInputs, scenarioXLSX, scenarioName, monte_carlo_case, temoa_path, project_path, solver,
                       cases, caseNum):
    # Unique filename
    model_filename = 'MC_' + monte_carlo_case + '_' + scenarioName + '_' + str(caseNum)

    # Prepare monte carlo inputs
    cols = ['type', 'variable', 'tech', caseNum]
    MCinputs = cases.loc[:, cols]
    MCinputs = MCinputs.rename(columns={caseNum: 'value'})

    # Build Model
    tt.build(modelInputs, scenarioXLSX, scenarioName, model_filename, MCinputs=MCinputs, path=project_path,
             mc_type='values')

    # Run Model
    error = tt.run(model_filename, saveEXCEL=False, temoa_path=temoa_path, debug=True, solver=solver)

    # Analyze Model (w/ default monte carlo analysis function)
    if not error:
        folder = os.path.join(project_path, 'databases')
        db = model_filename + '.sqlite'
        results = tt.analyze_db(folder, db, scenario=scenarioName, iteration=caseNum, switch='tech', tod_analysis=True,
                                debug=False)
    else:
        results = pd.Dataframe()

    return results


if __name__ == '__main__':

    # =======================================================
    # Model Inputs
    # =======================================================
    temoa_path = os.path.abspath('../../temoa-energysystem')
    project_path = os.getcwd()
    modelInputs_XLSX = 'data_combined.xlsx'
    monte_carlo_inputs = 'monte_carlo_inputs.xlsx'
    monte_carlo_cases = ['biomass', 'default']  # each case corresponds with a list in scenarioNames
    scenarioInputs = 'scenarios_emerging_tech.xlsx'
    scenarioNames = [['all'], ['all', 'none', 'BECCS', 'OCAES', 'DIST_PV', 'sCO2']]
    ncpus = 1  # default, unless otherwise specified in sbatch script
    solver = ''  # leave blank to let temoa decide which solver to use of those installed
    iterations = 100

    # =======================================================
    # begin script
    # =======================================================
    try:
        ncpus = int(os.getenv('NUM_PROCS'))  # try to use variable defined in sbatch script
    except:
        ncpus = ncpus  # otherwise default to this number of cores

    # combine data files
    tt.combine(project_path=project_path, primary='data_va.xlsx',
               data_files=['data_emerging_tech.xlsx', 'data_H2_VFB.xlsx'],
               output='data_combined.xlsx')

    # =======================================================
    # Move modelInputs_XLSX to database
    # =======================================================
    modelInputs = tt.move_data_to_db(modelInputs_XLSX, path=project_path)

    # =======================================================
    # Create directories - best completed before using multiprocessing
    # =======================================================
    mc_dir = 'monte_carlo'
    tt.create_dir(project_path=project_path, optional_dir=mc_dir)

    # ====================================
    # Perform Simulations
    # ====================================

    for monte_carlo_case, scenarioNames_list in zip(monte_carlo_cases, scenarioNames):
        for scenarioName in scenarioNames_list:
            # Create monte carlo cases
            os.chdir(os.path.join(project_path, 'data'))
            cases = tt.createMonteCarloCases_distributions(monte_carlo_inputs, monte_carlo_case, iterations)
            os.chdir(project_path)

            # Save cases
            os.chdir(os.path.join(project_path, mc_dir))
            cases.to_csv('MonteCarloInputs_' + monte_carlo_case + '_' + scenarioName + '.csv', index=False)
            os.chdir(project_path)

            # Perform simulations in parallel
            with parallel_backend('multiprocessing', n_jobs=ncpus):
                outputs = Parallel(n_jobs=ncpus, verbose=5)(
                    delayed(evaluateMonteCarlo)(modelInputs, scenarioInputs, scenarioName, monte_carlo_case, temoa_path,
                                                project_path,
                                                solver, cases, caseNum) for caseNum in range(iterations))

            # Save results to a csv
            os.chdir(os.path.join(project_path, mc_dir))
            df = pd.DataFrame()
            for output in outputs:
                df = df.append(output, ignore_index=True)
            df.to_csv('MonteCarloResults_' + monte_carlo_case + '_' + scenarioName + '.csv')
            os.chdir(project_path)
