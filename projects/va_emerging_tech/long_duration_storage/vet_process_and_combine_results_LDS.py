import os
import pandas as pd

# naming convention
wNETS = "With NETS"
wLDS = "With LDS"
wNETSwLDS = "With NETS with LDS"
Baseline = "Baseline"
lowBio = "Low Bio"
highBio = "High Bio"
decarb2050 = 2050

# monte carlo results files
mc = {
    "MonteCarloResults_highBio_Baseline_2050.csv": [Baseline, decarb2050, highBio],
    "MonteCarloResults_highBio_wNETSwLDS_2050.csv": [wLDS, decarb2050, highBio],
    "MonteCarloResults_highBio_wLDS_2050.csv": [wLDS, decarb2050, highBio],
    "MonteCarloResults_highBio_wNETS_2050.csv": [wNETS, decarb2050, highBio],

    "MonteCarloResults_lowBio_Baseline_2050.csv": [Baseline, decarb2050, lowBio],
    "MonteCarloResults_lowBio_wNETSwLDS_2050.csv": [wLDS, decarb2050, lowBio],
    "MonteCarloResults_lowBio_wLDS_2050.csv": [wLDS, decarb2050, lowBio],
    "MonteCarloResults_lowBio_wNETS_2050.csv": [wNETS, decarb2050, lowBio],}

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
    dfi.loc[:, 'Scenario'] = d[0]
    dfi.loc[:, 'decarb'] = d[1]
    dfi.loc[:, 'bio'] = d[2]

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
