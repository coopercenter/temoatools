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
def evaluateMonteCarlo(modelInputs, scenarioXLSX, scenarioName, combined_name, monte_carlo_case, temoa_path,
                       project_path, solver,
                       cases, caseNum):
    # Unique filename
    model_filename = combined_name + '_' + monte_carlo_case + '_' + scenarioName + '_' + str(caseNum)

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

        # store uncertain variables and their values
        for i in range(len(MCinputs)):
            mc_var = MCinputs.loc[i, 'tech'] + '-' + MCinputs.loc[i, 'variable']
            results.loc[:, mc_var] = MCinputs.loc[i, 'value']
    else:
        results = pd.Dataframe()

    return results


if __name__ == '__main__':

    # =======================================================
    # Model Inputs
    # =======================================================
    temoa_path = os.path.abspath('../../temoa-energysystem')
    project_path = os.getcwd()
    monte_carlo_inputs = 'monte_carlo_inputs.xlsx'
    monte_carlo_cases = ['default']  # each case corresponds with a list in scenarioNames
    scenarioInputs = 'scenarios_emerging_tech.xlsx'
    scenarioNames = ['wEmerg_woFossil_woNuclear', 'wEmerg_wFossil_woNuclear',
                     'wEmerg_woFossil_wNuclear', 'wEmerg_wFossil_wNuclear']

    modelInputs_primary = 'data_va_noEmissionLimit.xlsx'
    modelInputs_secondary = ['data_emerging_tech.xlsx', 'data_H2_VFB.xlsx']

    emission_inputs = ['emissionLimit_decarb_2050.xlsx']
    emission_names = ['2050']

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

    # =======================================================
    # Create directories - best completed before using multiprocessing
    # =======================================================
    mc_dir = 'monte_carlo'
    tt.create_dir(project_path=project_path, optional_dir=mc_dir)

    # =======================================================
    # iterate through emission_inputs
    # =======================================================
    for emission_input, emission_name in zip(emission_inputs, emission_names):
        # naming convention
        combined_name = emission_name
        combined_file = combined_name + '.xlsx'

        # files
        files = [emission_input]
        for modelInput in modelInputs_secondary:
            if len(modelInput) > 0:
                files.append(modelInput)

        # combine files
        tt.combine(project_path=project_path, primary=modelInputs_primary,
                   data_files=files,
                   output=combined_file)

        # =======================================================
        # Move modelInputs_XLSX to database
        # =======================================================
        modelInputs = tt.move_data_to_db(combined_file, path=project_path)

        # ====================================
        # Perform Simulations
        # ====================================

        for monte_carlo_case in monte_carlo_cases:
            for scenarioName in scenarioNames:
                # Create monte carlo cases
                os.chdir(os.path.join(project_path, 'data'))
                cases = tt.createMonteCarloCases_distributions(monte_carlo_inputs, monte_carlo_case, iterations)
                os.chdir(project_path)

                # Save cases
                os.chdir(os.path.join(project_path, mc_dir))
                cases.to_csv('MonteCarloInputs_' + monte_carlo_case + '_' + scenarioName + '_' + combined_name + '.csv',
                             index=False)
                os.chdir(project_path)

                # Perform simulations in parallel
                with parallel_backend('multiprocessing', n_jobs=ncpus):
                    outputs = Parallel(n_jobs=ncpus, verbose=5)(
                        delayed(evaluateMonteCarlo)(modelInputs, scenarioInputs, scenarioName, combined_name,
                                                    monte_carlo_case, temoa_path,
                                                    project_path,
                                                    solver, cases, caseNum) for caseNum in range(iterations))

                # Save results to a csv
                os.chdir(os.path.join(project_path, mc_dir))
                df = pd.DataFrame()
                for output in outputs:
                    df = df.append(output, ignore_index=True)
                df.to_csv('MonteCarloResults_' + monte_carlo_case + '_' + scenarioName + '_' + combined_name + '.csv')
                os.chdir(project_path)
