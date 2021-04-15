import temoatools as tt
from joblib import Parallel, delayed, parallel_backend
import os
import pandas as pd


# =======================================================
# Function to evaluate a single model
# =======================================================
def evaluateModel(modelInputs, scenarioInputs, scenarioName, combined_name, temoa_path, project_path, solver):
    # Unique filename
    model_filename = scenarioName + '_' + combined_name

    # Build Model
    tt.build(modelInputs, scenarioInputs, scenarioName, model_filename, path=project_path)

    # Run Model
    error = tt.run(model_filename, saveEXCEL=False, temoa_path=temoa_path, debug=True, solver=solver)

    # Analyze Model (w/ default monte carlo analysis function)
    if not error:
        folder = os.path.join(project_path, 'databases')
        db = model_filename + '.sqlite'
        results = tt.analyze_db(folder, db, scenario=scenarioName, iteration='baseline', switch='tech',
                                tod_analysis=True, debug=False)

        # Save results to a csv
        os.chdir(os.path.join(project_path, 'results'))
        df = pd.DataFrame()
        df = df.append(results, ignore_index=True)
        df.to_csv('BaselineResults_' + model_filename + '.csv')
        os.chdir(project_path)


if __name__ == '__main__':

    # =======================================================
    # Model Inputs
    # =======================================================
    temoa_path = os.path.abspath('../../../temoa-energysystem')
    project_path = os.getcwd()

    # solver settings
    ncpus = 1
    solver = ''  # 'gurobi'

    # model inputs
    scenarioInputs = 'scenarios_emerging_tech.xlsx'
    scenarioNames = ['woFossil', 'wFossil']

    modelInputs_primary = 'data_va_noEmissionLimit.xlsx'
    modelInputs_secondary = ['data_emerging_tech.xlsx', 'data_H2_VFB.xlsx']

    emission_inputs = ['emissionLimit_decarb_2050.xlsx']
    emission_names = ['2050']

    # =======================================================
    # begin script
    # =======================================================

    # check if more processors have been allocated for this task
    try:
        ncpus = int(os.getenv('NUM_PROCS'))  # try to use variable defined in sbatch script
    except:
        ncpus = ncpus  # otherwise default to this number of cores

    # Create directories - best completed before using multiprocessing
    tt.create_dir(project_path=project_path, optional_dir='results')

    # iterate through emission_inputs
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

        # Move modelInputs_XLSX to database
        modelInputs = tt.move_data_to_db(combined_file, path=project_path)

        # Perform Simulations in parallel
        with parallel_backend('multiprocessing', n_jobs=ncpus):
            outputs = Parallel(n_jobs=ncpus, verbose=5)(
                delayed(evaluateModel)(modelInputs, scenarioInputs, scenarioName, combined_name, temoa_path,
                                       project_path, solver)
                for
                scenarioName in
                scenarioNames)
