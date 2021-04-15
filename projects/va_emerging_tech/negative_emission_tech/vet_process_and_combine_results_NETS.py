import os
import pandas as pd

# naming convention
woFossil = 'woFossil'
wFossil = 'wFossil'
lowBio = 'lowBio'
highBio = 'highBio'
lowDAC = 'lowDAC'
highDAC = 'highDAC'
decarb2050 = 2050

# monte carlo results files
mc = {
    "MonteCarloResults_lowDAClowBio_woFossil_2050.csv": [woFossil, decarb2050, lowDAC, lowBio],
    "MonteCarloResults_lowDAChighBio_woFossil_2050.csv": [woFossil, decarb2050, lowDAC, highBio],
    "MonteCarloResults_highDAClowBio_woFossil_2050.csv": [woFossil, decarb2050, highDAC, lowBio],
    "MonteCarloResults_highDAChighBio_woFossil_2050.csv": [woFossil, decarb2050, highDAC, highBio],

    "MonteCarloResults_lowDAClowBio_wFossil_2050.csv": [wFossil, decarb2050, lowDAC, lowBio],
    "MonteCarloResults_lowDAChighBio_wFossil_2050.csv": [wFossil, decarb2050, lowDAC, highBio],
    "MonteCarloResults_highDAClowBio_wFossil_2050.csv": [wFossil, decarb2050, highDAC, lowBio],
    "MonteCarloResults_highDAChighBio_wFossil_2050.csv": [wFossil, decarb2050, highDAC, highBio]}




# ==============================
# process results
# ==============================

df = pd.DataFrame()

# ------------------------------------
# monte carlo results
# ------------------------------------
# os.chdir('..')
os.chdir('monte_carlo')
for file, d in zip(mc.keys(), mc.values()):
    print(file)
    dfi = pd.read_csv(file)

    # store details about scenario
    dfi.loc[:, 'new_fossil'] = d[0]
    dfi.loc[:, 'decarb'] = d[1]
    dfi.loc[:, 'DAC'] = d[2]
    dfi.loc[:, 'bio'] = d[3]

    # append modified data
    df = df.append(dfi, ignore_index=True)

# ------------------------------------
# save to disk
# ------------------------------------
df.to_csv('combined_results.csv')

# ------------------------------------
# split results for easier plotting
# ------------------------------------
# LCOE
LCOE = df.loc[df.loc[:, 'quantity'] == 'LCOE', :]
LCOE.to_csv('LCOE.csv')

# costs_by_year and emissions_by_year
costs_emi = df.loc[(df.loc[:, 'quantity'] == 'costs_by_year') | (df.loc[:, 'quantity'] == 'emissions_by_year'), :]
costs_emi.to_csv('costs_emissions_by_year.csv')

# capacity_by_year
capacity_by_year = df.loc[df.loc[:, 'quantity'] == 'capacity_by_year', :]
capacity_by_year.to_csv('capacity_by_year.csv')

# activity_by_year
activity_by_year = df.loc[df.loc[:, 'quantity'] == 'activity_by_year', :]
activity_by_year.to_csv('activity_by_year.csv')

# activity_by_tod
activity_by_tod = df.loc[df.loc[:, 'quantity'] == 'activity_by_tod', :]
activity_by_tod.to_csv('activity_by_tod.csv')
