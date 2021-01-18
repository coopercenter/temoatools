import os
import pandas as pd

os.chdir('monte_carlo')

files = ['MonteCarloResults_biomass_all.csv',
         'MonteCarloResults_default_all.csv',
         'MonteCarloResults_default_none.csv',
         'MonteCarloResults_default_DIST_PV.csv',
         'MonteCarloResults_default_OCAES.csv',
         'MonteCarloResults_default_sCO2.csv']

df = pd.DataFrame()
for file in files:
    dfi = pd.read_csv(file)
    df = df.append(dfi, ignore_index=True)

df.to_csv('combined_results.csv')
