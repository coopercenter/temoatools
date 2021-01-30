import os
import shutil
import temoatools as tt


def test_directory(path):
    # check if directory exists, create the directory if it does not
    try:
        os.stat(path)
    except:
        os.mkdir(path)


# ===================================
# Inputs
# ===================================
solver = ''
n_cpus = 1
solve_time = 1  # maximum number of hours

# Baseline databases to use
dbs = ["example.sqlite"]

# model years
years = [2020, 2030]

# Scenarios with corresponding probabilities
scenarios = ["BIO_HIGHCOST", "BIO_LOWCOST"]
probabilities = [0.5, 0.5]

# temoa model technologies and corresponding values for variable
variable = 'CostInvestIncrease'
techs = {'E_BIO': [1.0, 0.75],
         'E_NG': [1.0, 1.0]}

# ===================================
# Begin input file preparation
# ===================================

# --------------------
# Check for appropriate entries
# --------------------

n_periods = len(years) - 1
for key in techs.keys():
    values = techs[key]
    min_value = min(values)
    if min_value ** n_periods < 1e-6:
        print("Warning: value for " + key + " is too low")
        print("\tvalue^n_periods>1e-6 in order to be recognized")
        print("\twhere n is # of model years excluding the first time step\n")

# --------------------
# directory management
# --------------------

# current working directory (assumed to be temoatools//projects/puerto_rich_stoch)
wrkdir = os.getcwd()

# Create directory to store stochastic shell scripts
stochdir = os.path.join(wrkdir, 'sbatch_files')
test_directory(stochdir)

# temoa_stochastic directory (already exists from temoatools package)
temoadir = os.path.abspath('..//..//temoa_stochastic')

# configuration file directory (create if necessary)
configdir = os.path.abspath('..//..//temoa_stochastic//configs')
test_directory(configdir)

# database directory (create if necessary)
datadir = os.path.abspath('..//..//temoa_stochastic//data_files')
test_directory(datadir)

# Create directory to store scenario tree scripts for stochastic simulations
treedir = os.path.abspath('..//..//temoa_stochastic//tools//options')

# --------------------
# begin creation of input files
# --------------------

# Iterate through each database for each case
for db in dbs:

    db_name = tt.remove_ext(db)

    # ====================================
    # Stochastic input file
    # ====================================
    os.chdir(treedir)

    # Write File
    filename = "stoch_" + db_name + ".py"
    # Open File
    f = open(filename, "w")
    f.write(
        "# Automatically generated stochastic input file from temoatools github.com/EnergyModels/temoatools\n\n")
    f.write("verbose = True\n")
    f.write("force = True\n")
    f.write("\n")
    f.write("dirname = '" + db_name + "'\n")
    f.write("modelpath = '" + "../temoa_model/temoa_model.py'\n")
    f.write("dotdatpath = '../data_files/" + db_name + ".dat'\n")
    f.write("stochasticset = 'time_optimize'\n")
    f.write("stochastic_points = (")
    for year in years:
        f.write(str(year) + ", ")
    f.write(")\n")
    f.write("stochastic_indices = {'" + variable + "': 0}\n")
    f.write("types = (\n\t")
    for scenario in scenarios:
        f.write("'" + scenario + "', ")
    f.write("\n")
    f.write(")\n")
    f.write("conditional_probability = dict(\n")
    for scenario, prob in zip(scenarios, probabilities):
        f.write("\t" + scenario + "=" + str(prob) + ",\n")
    f.write(")\n")
    f.write("rates = {\n")
    f.write("\t'" + variable + "': dict(\n")
    for ix, (scenario, prob) in enumerate(zip(scenarios, probabilities)):
        f.write("\t\t" + scenario + "=(\n")
        for tech in techs.keys():
            value = techs[tech][ix]
            f.write("\t\t\t('" + tech + "', " + str(value) + "),\n")
        f.write("\t\t),\n\n")
    f.write("\t),\n")
    f.write("}\n")
    #
    # # Close File
    # f.close()

    # ====================================
    # Configuration file
    # ====================================
    os.chdir(configdir)
    filename = "config_stoch_" + db_name + ".txt"
    input_path = os.path.join(temoadir, "tools", db_name,
                              "ScenarioStructure.dat")
    output_path = os.path.join(datadir, db_name + ".sqlite")
    db_io_path = os.path.join(datadir, )

    f = open(filename, "w")
    # ---
    f.write(
        "#-----------------------------------------------------\n")
    f.write("# This is an automatically generated configuration file for Temoa using")
    f.write(" temoatools github.com/EnergyModels/temoatools\n")
    f.write("# It allows you to specify (and document) all run-time model options\n")
    f.write("# Legal chars in path: a-z A-Z 0-9 - _  / . :\n")
    f.write("# Comment out non-mandatory options to omit them\n")
    f.write("#----------------------------------------------------- \n")
    f.write("\n")
    f.write("# Input File (Mandatory)\n")
    f.write("# Input can be a .sqlite or .dat file\n")
    f.write("# Both relative path and absolute path are accepted\n")
    f.write("--input=" + input_path + "\n")
    f.write("\n")
    f.write("# Output File (Mandatory)\n")
    f.write("# The output file must be a existing .sqlite file\n")
    f.write("--output=" + output_path + "\n")
    f.write("\n")
    f.write("# Scenario Name (Mandatory)\n")
    f.write("# This scenario name is used to store results within the output .sqlite file\n")
    f.write("--scenario=" + db_name + "\n")
    f.write("\n")
    f.write("# Path to the 'db_io' folder (Mandatory)\n")
    f.write("# This is the location where database files reside\n")
    f.write("--path_to_db_io=" + db_io_path + "\n")
    f.write("\n")
    f.write("# Spreadsheet Output (Optional)\n")
    f.write("# Direct model output to a spreadsheet\n")
    f.write("# Scenario name specified above is used to name the spreadsheet\n")
    f.write("#--saveEXCEL\n")
    f.write("\n")
    f.write("# Save the log file output (Optional)\n")
    f.write("# This is the same output provided to the shell\n")
    f.write("#--saveTEXTFILE\n")
    f.write("\n")
    f.write("# Solver-related arguments (Optional)\n")
    if len(solver) > 0:
        f.write("--solver=" + solver + "                    # Optional, indicate the solver\n")
    else:
        f.write("#--solver=cplex                    # Optional, indicate the solver\n")

    f.write("#--keep_pyomo_lp_file             # Optional, generate Pyomo-compatible LP file\n")
    f.write("\n")
    f.write("# Modeling-to-Generate Alternatives (Optional)\n")
    f.write(
        "# Run name will be automatically generated by appending '_mga_' and iteration number to scenario name\n")
    f.write("#--mga {\n")
    f.write("#	slack=0.1                     # Objective function slack value in MGA runs\n")
    f.write("#	iteration=4                   # Number of MGA iterations\n")
    f.write(
        "#	weight=integer                # MGA objective function weighting method, currently 'integer' or 'normalized'\n")
    f.write("#}\n")
    f.write("\n")
    f.close()

    # ====================================
    # Script file - Individual
    # ====================================
    os.chdir(stochdir)

    config_filename = "config_stoch_" + db_name + ".txt"
    tree_filename = "stoch_" + db_name + ".py"
    script_filename = "stoch_" + db_name + ".sh"
    config_filepath = os.path.join(configdir, config_filename)

    f = open(script_filename, "w")
    f.write("#!/bin/bash\n")
    f.write("#SBATCH -N 1\n")
    f.write("#SBATCH --cpus-per-task=" + str(n_cpus) + "\n")
    f.write("#SBATCH -t " + str(solve_time) + ":00:00\n")
    f.write("#SBATCH -p standard\n\n")
    f.write("module purge\n")
    f.write("module load anaconda/2019.10-py2.7\n\n")
    f.write("# activate temoa environment\n")
    f.write("source activate temoa-stoch-py2\n\n")
    f.write("# if gurobi is available\n")
    f.write("export PYTHONPATH=$EBROOTGUROBI/lib/python2.7_utf32\n")
    f.write("module load gurobi/9.0.1\n\n")
    f.write("# set the NUM_PROCS env variable for the Python script\n")
    f.write("export NUM_PROCS =$SLURM_CPUS_PER_TASK\n\n")
    f.write("# run\n")
    f.write("cd " + temoadir + "\n")
    f.write("cd tools\n\n")
    f.write("python generate_scenario_tree_JB.py options/" + tree_filename + " --debug\n")
    # Not needed, only based on build year
    # f.write("python rewrite_tree_nodes.py options/" + tree_filename + " --debug\n\n")
    f.write("cd ..\n\n")
    f.write("python temoa_model/temoa_stochastic.py --config=" + config_filepath + "\n")
    f.close()

# ====================================
# Script file - batch
# ====================================
os.chdir(wrkdir)
f = open("run_all_simulations.sh", "w")
f.write("#!/bin/bash\n\n")
f.write('cd sbatch_files\n\n')
for db in dbs:
    db_name = tt.remove_ext(db)
    script_filename = "stoch_" + db_name + ".sh"
    f.write("sbatch " + script_filename + " \n")
f.close()

# Copy baseline databases
for db in dbs:
    db_name = tt.remove_ext(db)
    # .sqlite
    src_dir = os.path.join(wrkdir, "databases", db_name + ".sqlite")
    dst_dir = os.path.join(datadir, db_name + ".sqlite")
    shutil.copy(src_dir, dst_dir)
    # .dat
    src_dir = os.path.join(wrkdir, "databases", db_name + ".dat")
    dst_dir = os.path.join(datadir, db_name + ".dat")
    shutil.copy(src_dir, dst_dir)

# Return to original working directory
os.chdir(wrkdir)
