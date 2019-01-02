import temoatools as tt
import multiprocessing
from joblib import Parallel, delayed, parallel_backend

#=======================================================
# Function to evaluate a single model
#=======================================================
def evaluateModel(modelInputs, scenarioInputs, scenarioName, paths):

    # Unique filename
    model_filename = scenarioName
    
    # Build Model
    tt.build(modelInputs, scenarioInputs, scenarioName, model_filename, path='data')
    
    # Run Model
    saveEXCEL=True
    tt.run(model_filename, paths, saveEXCEL=True, data_path='data', debug=False)
    
if __name__ == '__main__':
    
    #=======================================================
    # Model Inputs
    #=======================================================
    modelInputs_XLSX  = 'data.xlsx'
    scenarioInputs    = 'scenarios.xlsx'
    scenarioNames     = ['A','B','C','D']
    paths             = 'paths.csv'

    #=======================================================
    # Move modelInputs_XLSX to database
    #=======================================================
    modelInputs = tt.move_data_to_db(modelInputs_XLSX, path='data')
    
    #====================================    
    # Perform Simulations
    option = 2 # 1 - Run single, 2 - Run all
    #====================================
    num_cores = multiprocessing.cpu_count() -1 # Save one core for other processes
    
    if option==1:
        # Perform single simulation
        evaluateModel(modelInputs, scenarioInputs, scenarioNames[0], paths)
    
    elif option == 2:
        # Perform simulations in parallel
        with parallel_backend('multiprocessing', n_jobs=num_cores):
            Parallel(n_jobs=num_cores,verbose=5)(delayed(evaluateModel)(modelInputs, scenarioInputs, scenarioName, paths) for scenarioName in scenarioNames)     
    