import temoatools as tt
from joblib import Parallel, delayed, parallel_backend
import os


# =======================================================
# Function to evaluate a single model
# =======================================================
def evaluateModel(modelInputs, scenarioInputs, scenarioName, combined_name, temoa_path, project_path, solver):
    # Unique filename
    model_filename = scenarioName + '_' + combined_name

    # Build Model
    tt.build(modelInputs, scenarioInputs, scenarioName, model_filename, path=project_path)

    # Run Model
    tt.run(model_filename, saveEXCEL=False, temoa_path=temoa_path, debug=True, solver=solver)


if __name__ == '__main__':

    # =======================================================
    # Model Inputs
    # =======================================================
    temoa_path = os.path.abspath('../../temoa-energysystem')
    project_path = os.getcwd()

    # solver settings
    ncpus = 2
    solver = ''  # 'gurobi'

    # model inputs
    scenarioInputs = 'scenarios_emerging_tech.xlsx'
    scenarioNames = ['woEmerg_woFossil',	'woEmerg_wFossil',	'wEmerg_woFossil','wEmerg_wFossil']

    modelInputs_primary = 'data_va_noEmissionLimit.xlsx'
    modelInputs_secondary = ['data_emerging_tech.xlsx', 'data_H2_VFB.xlsx']

    emission_inputs = ['emissionLimit_decarb_2030.xlsx', 'emissionLimit_decarb_2035.xlsx',
                       'emissionLimit_decarb_2040.xlsx', 'emissionLimit_decarb_2045.xlsx',
                       'emissionLimit_decarb_2050.xlsx', 'emissionLimit_decarb_na.xlsx']
    emission_names = ['2030', '2035', '2040', '2045', '2050', 'na']

    # =======================================================
    # begin script
    # =======================================================

    # check if more processors have been allocated for this task
    try:
        ncpus = int(os.getenv('NUM_PROCS'))  # try to use variable defined in sbatch script
    except:
        ncpus = ncpus  # otherwise default to this number of cores

    # =======================================================
    # Create directories - best completed before using multiprocessing
    # =======================================================
    tt.create_dir(project_path=project_path, optional_dir='results')

    # =======================================================
    # iterate through emission_inputs
    # =======================================================
    for emission_input, emission_name in zip(emission_inputs, emission_names):
        # naming convention
        combined_name = 'combined_' + emission_name
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
        option = 2  # 1 - Run single, 2 - Run all
        # ====================================

        if option == 1:
            # Perform single simulation
            evaluateModel(modelInputs, scenarioInputs, scenarioNames[0], combined_name, temoa_path, project_path,
                          solver)

        elif option == 2:
            # Perform simulations in parallel
            with parallel_backend('multiprocessing', n_jobs=ncpus):
                Parallel(n_jobs=ncpus, verbose=5)(
                    delayed(evaluateModel)(modelInputs, scenarioInputs, scenarioName, combined_name, temoa_path,
                                           project_path, solver)
                    for
                    scenarioName in
                    scenarioNames)
