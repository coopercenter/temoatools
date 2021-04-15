## About
The temoatools package is designed to complement the @github/TemoaProject by 
providing methods to help with the creation and analysis of the .sqlite databases used by temoa.
Specifically, users provide inputs in excel, which are then moved into .sqlite databases based 
on several simplifying assumptions (listed below). Methods are provided for creating, running and analyzing
baseline scenarios, sensitivity studies, Monte Carlo studies, and stochastic optimization runs using 
parallelization libraries.

More details:
1) temoatools simplifying assumptions
    - Costs change over time following an exponential growth/decline curve using a user-specified rate of change
        - fixed costs
        - variable costs (including fuel costs)
        - capital costs
    - demand is only for a single sector

2) input files
    1) data - contains all project data (demand, technology, costs, etc.)
    2) scenarios - specify which technologies (from data) are used for each scenario to be run
    3) sensitivityVariables - specify which variables to perturb for a sensitivity analysis
  
3) Overview of main folders
    - temoatools/examples - sample uses of temoatools to run and analyze temoa models
    - temoatools/projects - sample projects, it is recommended to create a directory here for your project
    - temoatools/temoa-energysystem - an archived version of Temoa is now kept within the temoatools repository. This is the most recent version that works with temoatools
    - temoatools/temoa_stochastic - an archived version of Temoa in Python 2 that  is now kept within the temoatools repository. This is the most recent version that works with temoatools
    - temoatools/temoatools - temoatools source code
          
## How to cite
### Temoa
Hunter, K., Sreepathi, S. & DeCarolis, J. F. Modeling for insight using tools for energy model optimization and analysis (Temoa). Energy Econ. 40, 339–349 (2013). https://doi.org/10.1016/j.eneco.2013.07.014

### temoatools (this library)
Bennett, J.A., Trevisan, C.N., DeCarolis, J.F. et al. Extending energy system modelling to include extreme weather risks and application to hurricane events in Puerto Rico. Nat Energy 6, 240–249 (2021). https://doi.org/10.1038/s41560-020-00758-6

## temoatools installation with command line (basic)
Temoatools is meant to be an extension for Temoa. 
Temoa is an on-going project, so in order to ensure compatibility, temoatools uses an archived version of Temoa.
Temoatools currently uses the June 30, 2020 version of Temoa (commit 9d10c1d), downloadable at:  https://github.com/TemoaProject/temoa/tree/9d10c1da81dc6b4f2b34cadfac9db947251254e2
The instructions below are for a new installation of temoatools. 
The example commands are shown in a Windows environment.

1) prerequisites: install git and Anaconda3
    - https://git-scm.com/book/en/v2/Getting-Started-Installing-Git
    - https://www.anaconda.com/distribution/#download-section
    
2) launch anaconda3 prompt
    - Windows: Start -> Anaconda3 -> Anaconda Prompt

3) navigate to where you want to install and run temoatools
    
        cd harddrive/yourdirectory

4) download temoatools using git
    
        git clone https://www.github.com/coopercenter/temoatools

5) navigate to temoatools directory
        
        cd temoatools

3) create temoa-py3 environment (modified from archvied version of Temoa)
        
        conda env create
        conda activate temoa-py3
    
4) install temoatools

        pip install .
                                                                                                                                                                                                                     
5) to test:
        
        cd examples/baselines  
        python baselines_run.py

        
## temoatools installation with PyCharm IDE (advanced), last updated 11/23/2020
1) prerequisites: install Git, Anaconda3 and PyCharm Community Edition
    1) https://git-scm.com/book/en/v2/Getting-Started-Installing-Git
    2) https://www.anaconda.com/distribution/#download-section
    3) https://www.jetbrains.com/pycharm/download/
    
2) Create project in PyCharm
    1)  Launch PyCharm
        - Windows: Start -> JetBrains -> PyCharm Community Edition
    2) New project:
        - Select "Get from VCS" Version Control option
        - Settings
            - URL (Must match below):
            
                        https://www.github.com/coopercenter/temoatools
            - Directory (Your choice) - record this directory for later
            
                        C:\Users\YourName\PyCharmProjects\temoatools
    3) Keep PyCharm open
        
3) Create Python environment
    1) Launch Anaconda3
        - Windows: Start -> Anaconda3 -> Anaconda Prompt
    2) Navigate to PyCharm project path (Directory from Step 2ii)
        
            cd C:\Users\YourName\PyCharmProjects\temoatools
            
    - create environment
    
            conda env create
            conda activate temoa-py3
            
4) Configure PyCharm project
    1) Return to PyCharm
    2) Open PyCharm settings
        1) File -> Settings
    3) Open Interpreter settings
        1) Expand Project:temoatools (on left hand side)
        2) Select Python Interpreter
    4) Select the gear icon in the upper right
    5) "Add"
    6) Select "Conda Environment" on the left hand side
    7) Select "Existing Environment"
    8) From the Interpreter dropdown list select the option that contains temoa-py3
    9) Select OK and OK again
    10) It may take several minutes for PyCharm to update
    
5) Verify installation was successful by running baselines example
    1) Open examples\baselines\baselines_run.py from Project
    2) From main menu: "Run" -> "Run" -> "baselines_run" -> "Run"
    3) Open examples\baselines\baselines_analyze.py from Project
    4) From main menu: "Run" -> "Run" -> "baselines_analyze" -> "Run"
    5) Navigate to examples/baselines/results to see plots
    
Notes:
- The main advantage of this method is tobe able to easily update to the latest version of the code using Git:
        - From upper task bar: "VCS" -> "Git" -> "Pull"
        - When given the prompt to "Update Project", select "Merge incoming changes into the current branch"

- If you will be updating to the latest version of the code then make sure that you put your own project in a unique folder.
    - For example, copy a similar example or project folder to i.e. projects/yourproject
    - This will prevent future code updates from overwriting your work.
       
   
4) install temoatools

        pip install .
                                                                                                                                                                                                                     
5) to test:
        
        cd examples/baselines  
        python baselines_run.py
        
## Running on Rivanna, UVA's high performance computing system*:
1) Get set-up on Rivanna
   1) Get access to an allocation - Work with the Professor leading your research to get an allocation on Rivanna. More information can be found here: https://www.rc.virginia.edu/userinfo/rivanna/allocations/
   2) Get access to Gurobi - Submit a 'Support Request' and ask to be added to the list of Gurobi users. https://www.rc.virginia.edu/form/support-request/
2) Running from Rivanna - There are multiple ways to run code on Rivanna, these instructions are for using FastX.
    1) Login to FastX https://rivanna-desktop.hpc.virginia.edu/
    2) Start a 'MATE' session
    3) Open a terminal
    
   ### To install:
          
        module load anaconda/2019.10-py3.7
        git clone https:www.github.com/coopercenter/temoatools
        cd temoatools
        conda env create
        source activate temoa-py3
        cd ..
        cd temoatools
        pip install .
    
   ### To run manually (in a new terminal):
   
        module load anaconda/2019.10-py3.7
        source activate temoa-py3
        export PYTHONUTF8=1
        module load gurobi
        cd temoatools/examples/baselines
        python baselines_run.py
        python baselines_analyze.py

   ### To run with a bash script (in a new terminal):

        cd temoatools/examples/baselines
        sbatch run_baselines.sh
        sacct

    Note: Installing temoatools only works in your home directory, not the scratch directory.

## Stochastic Instructions
For step-by-step instructions to run the Puerto Rico Stochastic project, see the README.md file in projects/puerto_rico_stoch. 
This project uses a stochastic implementation of temoa that is archived in temoa_stochastic.

## Notes
As of 2/8/2020, temoa currently does not output results to excel, therefore set saveEXCEL to False in temoatools.run()

*At the time of writing this, Rivanna has python 2.7, Anaconda2 and Gurobi installed.
However, modules on Rivanna are routinely updated. 
Therefore "module load" commands (for anaconda and gurobi) may need to be updated. 
Check https://www.rc.virginia.edu/userinfo/rivanna/software/modules/ for the latest.