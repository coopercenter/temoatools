import temoatools as tt
from joblib import Parallel, delayed, parallel_backend
import os


# =======================================================
# Function to evaluate a single model
# =======================================================
def evaluateModel(modelInputs, scenarioInputs, scenarioName, casename, temoa_path, project_path, solver):
    # Unique filename
    model_filename = casename + '_' + scenarioName

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
    case_list = ['linear', 'intermittent', 'delay']
    modelInputs_XLSX_list = ['data_combined1.xlsx', 'data_combined2.xlsx', 'data_combined3.xlsx']
    scenarioInputs = 'scenarios_emerging_tech_new.xlsx'
    scenarioNames_list = [['none', 'none_nnf', 'high', 'high_nnf']]
    ncpus = 1  # int(os.getenv('NUM_PROCS'))
    solver = ''  # 'gurobi'

    # combine data files
    tt.combine(project_path=project_path, primary='data_va_ohne_emission_limit.xlsx',
               data_files=['emission_limit_1_linear.xlsx', 'data_emerging_tech.xlsx'],
               output='data_combined1.xlsx')

    tt.combine(project_path=project_path, primary='data_va_ohne_emission_limit.xlsx',
               data_files=['emission_limit_2_intermittent.xlsx', 'data_emerging_tech.xlsx'],
               output='data_combined2.xlsx')

    tt.combine(project_path=project_path, primary='data_va_ohne_emission_limit.xlsx',
               data_files=['emission_limit_3_delay.xlsx', 'data_emerging_tech.xlsx'],
               output='data_combined3.xlsx')

    for modelInputs_XLSX, scenarioNames, casename in zip(modelInputs_XLSX_list, scenarioNames_list, case_list):

        # =======================================================
        # Move modelInputs_XLSX to database
        # =======================================================
        modelInputs = tt.move_data_to_db(modelInputs_XLSX, path=project_path)

        # =======================================================
        # Create directories - best completed before using multiprocessing
        # =======================================================
        tt.create_dir(project_path=project_path, optional_dir='results')

        # ====================================
        # Perform Simulations
        option = 2  # 1 - Run single, 2 - Run all
        # ====================================

        if option == 1:
            # Perform single simulation
            evaluateModel(modelInputs, scenarioInputs, scenarioNames[0], temoa_path, project_path, solver)

        elif option == 2:
            # Perform simulations in parallel
            with parallel_backend('multiprocessing', n_jobs=ncpus):
                Parallel(n_jobs=ncpus, verbose=5)(
                    delayed(evaluateModel)(modelInputs, scenarioInputs, scenarioName, casename, temoa_path,
                                           project_path, solver)
                    for
                    scenarioName in
                    scenarioNames)
