import os
import pandas as pd

os.chdir('monte_carlo')

to_analyze = {'MonteCarloResults_default_BECCS.csv': 'BECCS',
              'MonteCarloResults_default_all.csv': 'All',
              'MonteCarloResults_default_none.csv': 'None',
              'MonteCarloResults_default_DIST_PV.csv': 'Rooftop Solar',
              'MonteCarloResults_default_OCAES.csv': 'OCAES',
              'MonteCarloResults_default_sCO2.csv': 'sCO2'}

df = pd.DataFrame()
for file, scenario in zip(to_analyze.keys(), to_analyze.values()):
    dfi = pd.read_csv(file)

    # rename database column
    dfi.database = scenario

    # remove LCOE and average_emissions
    dfi.drop(dfi[dfi.loc[:, 'quantity'] == 'LCOE'].index, inplace=True)
    dfi.drop(dfi[dfi.loc[:, 'quantity'] == 'average_emissions'].index, inplace=True)

    # append modified data
    df = df.append(dfi, ignore_index=True)

# save to disk
df.to_csv('combined_results.csv')
