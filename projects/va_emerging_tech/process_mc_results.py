import os
import pandas as pd

# naming convention
woEmerg = 'woEmerg'
wEmerg = 'wEmerg'
woFossil = 'woFossil'
wFossil = 'wFossil'
woNuclear = 'woNuclear'
wNuclear = 'wNuclear'
decarb2050 = 2050

# baseline results files
baselines = {
    "BaselineResults__wEmerg_wFossil_wNuclear_combined_2050.csv": [wEmerg, wFossil, wNuclear, decarb2050],
    "BaselineResults__wEmerg_wFossil_woNuclear_combined_2050.csv": [wEmerg, wFossil, woNuclear, decarb2050],
    "BaselineResults__wEmerg_woFossil_wNuclear_combined_2050.csv": [wEmerg, woFossil, wNuclear, decarb2050],
    "BaselineResults__wEmerg_woFossil_woNuclear_combined_2050.csv": [wEmerg, woFossil, woNuclear, decarb2050],
    "BaselineResults__woEmerg_wFossil_wNuclear_combined_2050.csv": [woEmerg, wFossil, wNuclear, decarb2050],
    "BaselineResults__woEmerg_wFossil_woNuclear_combined_2050.csv": [woEmerg, wFossil, woNuclear, decarb2050],
    "BaselineResults__woEmerg_woFossil_wNuclear_combined_2050.csv": [woEmerg, woFossil, wNuclear, decarb2050],
    "BaselineResults__woEmerg_woFossil_woNuclear_combined_2050.csv": [woEmerg, woFossil, woNuclear, decarb2050]}

# default values for monte carlo variables
default_values = {
    'EC_BECCS-CostInvest': 6874,
    'EC_DAC-CostInvest': 2500,
    'EC_H2-CostInvest': 5821.55,
    'E_OCAES-CostInvest': 1457.0,
    'EC_VFB-CostInvest': 4317.0}

# monte carlo results files
mc = {'MonteCarloResults_default_wEmerg_wFossil_wNuclear.csv': [wEmerg, wFossil, wNuclear, decarb2050],
      'MonteCarloResults_default_wEmerg_wFossil_woNuclear.csv': [wEmerg, wFossil, woNuclear, decarb2050],
      'MonteCarloResults_default_wEmerg_woFossil_wNuclear.csv': [wEmerg, woFossil, wNuclear, decarb2050],
      'MonteCarloResults_default_wEmerg_woFossil_woNuclear.csv': [wEmerg, woFossil, woNuclear, decarb2050]}

# ==============================
# process results
# ==============================

df = pd.DataFrame()

# baseline results
os.chdir('results')
for file, d in zip(baselines.keys(), baselines.values()):
    dfi = pd.read_csv(file)

    # store details about scenario
    dfi.new_emerg = d[0]
    dfi.new_fossil = d[1]
    dfi.new_nuclear = d[2]
    dfi.decarb = d[3]

    # store default values of monte carlo variables
    for key, value in zip(default_values.keys(), default_values.values()):
        dfi.loc[:, key] = value

    # append modified data
    df = df.append(dfi, ignore_index=True)

# monte carlo results
os.chdir('..')
os.chdir('monte_carlo')
for file, d in zip(mc.keys(), mc.values()):
    dfi = pd.read_csv(file)

    # store details about scenario
    dfi.new_emerg = d[0]
    dfi.new_fossil = d[1]
    dfi.new_nuclear = d[2]
    dfi.decarb = d[3]

    # append modified data
    df = df.append(dfi, ignore_index=True)

# save to disk
df.to_csv('combined_results.csv')
