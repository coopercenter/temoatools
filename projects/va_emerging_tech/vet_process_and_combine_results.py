import os
import pandas as pd

# naming convention
woEmerg = 'woEmerg'
wEmerg = 'wEmerg'
woFossil = 'woFossil'
wFossil = 'wFossil'
woNuclear = 'woNuclear'
wNuclear = 'wNuclear'
lowBio = "Low Bio"
highBio = "High Bio"
decarb2050 = 2050

# monte carlo results files
mc = {
    "MonteCarloResults_highBio_wEmerg_wFossil_woNuclear_2050.csv": [wEmerg, wFossil, woNuclear, decarb2050, highBio],
    "MonteCarloResults_highBio_wEmerg_woFossil_woNuclear_2050.csv": [wEmerg, woFossil, woNuclear, decarb2050, highBio],
    "MonteCarloResults_highBio_woEmerg_wFossil_woNuclear_2050.csv": [woEmerg, wFossil, woNuclear, decarb2050,
                                                                     highBio],
    "MonteCarloResults_highBio_woEmerg_woFossil_woNuclear_2050.csv": [woEmerg, woFossil, woNuclear, decarb2050,
                                                                      highBio],

    "MonteCarloResults_lowBio_wEmerg_wFossil_woNuclear_2050.csv": [wEmerg, wFossil, woNuclear, decarb2050, lowBio],
    "MonteCarloResults_lowBio_wEmerg_woFossil_woNuclear_2050.csv": [wEmerg, woFossil, woNuclear, decarb2050, lowBio],
    "MonteCarloResults_lowBio_woEmerg_wFossil_woNuclear_2050.csv": [woEmerg, wFossil, woNuclear, decarb2050, lowBio],
    "MonteCarloResults_lowBio_woEmerg_woFossil_woNuclear_2050.csv": [woEmerg, woFossil, woNuclear, decarb2050, lowBio]}

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
    dfi.loc[:, 'new_emerg'] = d[0]
    dfi.loc[:, 'new_fossil'] = d[1]
    dfi.loc[:, 'new_nuclear'] = d[2]
    dfi.loc[:, 'decarb'] = d[3]
    dfi.loc[:, 'bio'] = d[4]

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
