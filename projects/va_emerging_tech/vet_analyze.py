import temoatools as tt
from joblib import Parallel, delayed, parallel_backend
import os


def analyzeModel(folder, dbs, createPlots, saveData, sectorName, task):
    if task == 0:
        # Costs
        yearlyCosts, LCOE = tt.getCosts(folder, dbs, save_data=saveData, create_plots=createPlots)

    elif task == 1:
        # Emissions
        yearlyEmissions, avgEmissions = tt.getEmissions(folder, dbs, save_data=saveData, create_plots=createPlots)

    # Analyze capacity and activity by fuel types
    elif task == 2:
        switch = 'fuel'
        capacityByFuel = tt.getCapacity(folder, dbs, switch=switch, save_data=saveData, create_plots=createPlots)
    elif task == 3:
        switch = 'fuel'
        ActivityByYearFuel = tt.getActivity(folder, dbs, switch=switch, save_data=saveData, create_plots=createPlots)
    elif task == 4:
        switch = 'fuel'
        ActivityByTODFuel = tt.getActivityTOD(folder, dbs, switch=switch, sector_name=sectorName, save_data=saveData,
                                              create_plots=createPlots)

    # Analyze capacity and activity by technology types
    elif task == 5:
        switch = 'tech'
        capacityByTech = tt.getCapacity(folder, dbs, switch=switch, save_data=saveData, create_plots=createPlots)
    elif task == 6:
        switch = 'tech'
        ActivityByYearTech = tt.getActivity(folder, dbs, switch=switch, save_data=saveData, create_plots=createPlots)
    elif task == 7:
        switch = 'tech'
        ActivityByTODTech = tt.getActivityTOD(folder, dbs, switch=switch, sector_name=sectorName, save_data=saveData,
                                              create_plots=createPlots)


if __name__ == '__main__':
    # ===============
    # Inputs
    # ===============

    folder = os.getcwd() + '/databases'
    dbs = [
        'woEmerg_woFossil_combined_2030.sqlite', 'woEmerg_woFossil_combined_2035.sqlite',
        'woEmerg_woFossil_combined_2040.sqlite', 'woEmerg_woFossil_combined_2045.sqlite',
        'woEmerg_woFossil_combined_2050.sqlite', 'woEmerg_woFossil_combined_na.sqlite',

        'woEmerg_wFossil_combined_2030.sqlite', 'woEmerg_wFossil_combined_2035.sqlite',
        'woEmerg_wFossil_combined_2040.sqlite', 'woEmerg_wFossil_combined_2045.sqlite',
        'woEmerg_wFossil_combined_2050.sqlite', 'woEmerg_wFossil_combined_na.sqlite',

        'wEmerg_woFossil_combined_2030.sqlite', 'wEmerg_woFossil_combined_2035.sqlite',
        'wEmerg_woFossil_combined_2040.sqlite', 'wEmerg_woFossil_combined_2045.sqlite',
        'wEmerg_woFossil_combined_2050.sqlite', 'wEmerg_woFossil_combined_na.sqlite',

        'wEmerg_wFossil_combined_2030.sqlite', 'wEmerg_wFossil_combined_2035.sqlite',
        'wEmerg_wFossil_combined_2040.sqlite', 'wEmerg_wFossil_combined_2045.sqlite',
        'wEmerg_wFossil_combined_2050.sqlite', 'wEmerg_wFossil_combined_na.sqlite']

    createPlots = 'Y'  # Create default plots
    saveData = 'Y'  # Save data as a csv or xls
    sectorName = 'electric'  # Name of sector to be analyzed
    onlySimple = False

    ncpus = 6

    # ===============
    # Analyze model
    # ===============

    # check if more processors have been allocated for this task
    try:
        ncpus = int(os.getenv('NUM_PROCS'))  # try to use variable defined in sbatch script
    except:
        ncpus = ncpus  # otherwise default to this number of cores

    # determine which tasks to run
    if onlySimple:
        n_tasks = 2
    else:
        n_tasks = 8

    # run analysis tasks in parallel
    with parallel_backend('multiprocessing', n_jobs=ncpus):
        Parallel(n_jobs=ncpus, verbose=5)(
            delayed(analyzeModel)(folder, dbs, createPlots, saveData, sectorName, task_number)
            for
            task_number in range(n_tasks))
