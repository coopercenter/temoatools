import temoatools as tt
from joblib import Parallel, delayed, parallel_backend
import os


# =======================================================
# Function to evaluate a single model
# =======================================================
def evaluateModel(modelInputs, scenarioInputs, scenarioName, emissionName, temoa_path, project_path, solver):
    # Unique filename
    model_filename = scenarioName + emissionName

    # Build Model
    tt.build(modelInputs, scenarioInputs, scenarioName, model_filename, path=project_path)

    # Run Model
    tt.run(model_filename, saveEXCEL=False, temoa_path=temoa_path, debug=True, solver=solver)


if __name__ == '__main__':

    # =======================================================
    # Model Inputs
    # =======================================================
    temoa_path = os.path.abspath('..//..//temoa_stochastic')
    project_path = os.getcwd()
    ncpus = 1
    solver = ''  # leave blank to let temoa decide which solver to use of those installed

    base_data_file = 'data_va_stoch.xlsx'  # missing emission limits

    scenario_inputs = 'scenarios.xlsx'
    scenario_names = ['A', 'B', 'C']

    emission_inputs = ['emission_limit_0_none.xlsx',
                       'emission_limit_1_linear.xlsx',
                       'emission_limit_2_delay.xlsx']
    emission_names = ['0', '1', '2']

    # =======================================================
    # begin script
    # =======================================================

    # check if more processors have been allocated for this task
    try:
        ncpus = int(os.getenv('NUM_PROCS'))  # try to use variable defined in sbatch script
    except:
        ncpus = ncpus  # otherwise default to this number of cores

    # iterate through emission_inputs
    for emission_input, emission_name in zip(emission_inputs, emission_names):
        # naming convention
        combined_name = 'combined_' + emission_name
        combined_file = combined_name + '.xlsx'

        # combine files
        tt.combine(project_path=project_path, primary=base_data_file,
                   data_files=[emission_input],
                   output=combined_file)

        # =======================================================
        # Move modelInputs_XLSX to database
        # =======================================================
        modelInputs = tt.move_data_to_db(combined_file, path=project_path)

        # ====================================
        # Perform Simulations
        option = 2  # 1 - Run first, 2 - Run all
        # ====================================

        if option == 1:
            # Perform single simulation
            evaluateModel(modelInputs, scenario_inputs, scenario_names[0], emission_name, temoa_path, project_path, solver)

        elif option == 2:
            # Perform simulations in parallel

            with parallel_backend('multiprocessing', n_jobs=ncpus):
                Parallel(n_jobs=ncpus, verbose=5)(
                    delayed(evaluateModel)(modelInputs, scenario_inputs, scenario_name, emission_name, temoa_path, project_path,
                                           solver)
                    for scenario_name in
                    scenario_names)
