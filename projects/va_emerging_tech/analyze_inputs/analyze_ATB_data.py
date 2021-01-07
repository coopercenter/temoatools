import pandas as pd
import numpy as np
from scipy.optimize import curve_fit
import matplotlib.pyplot as plt

# This script analyzes data from the 2020 NREL ATB:
# NREL (National Renewable Energy Laboratory). 2020.
# "2020 Annual Technology Baseline." Golden, CO:
# National Renewable Energy Laboratory. https://atb.nrel.gov/.

# Inputs:
# CAPEX [$/kW]
# Fixed O&M [$/kW-yr]
# Variable O&M [$/MWH]

# Outputs:
# CAPEX [$/kW]
# Fixed O&M [$/kW-yr]
# Variable O&M [M$/PJ]
# rates [fraction]

# Exponential curve fit with intercept of 1.0
def func(x, a):
    return np.exp(a * x)


# import ATB data for analysis
data = pd.read_excel('2020_ATB_CostProjections.xlsx', sheet_name=None)

# prepare DataFrame to store results
entries = [
    'Technology',
    'CAPEX_2018',
    'CAPEX_Advanced_rate',
    'CAPEX_Moderate_rate',
    'CAPEX_Conservative_rate',
    'FixedOM_2018',
    'FixedOM_Advanced_rate',
    'FixedOM_Moderate_rate',
    'FixedOM_Conservative_rate',
    'VariableOM_2018',
    'VariableOM_Advanced_rate',
    'VariableOM_Moderate_rate',
    'VariableOM_Conservative_rate'
]
output = pd.DataFrame(columns=entries)

# iterate through data
for key in data.keys():
    df = data[key]
    df = df.set_index('Year')

    s = pd.Series(index=entries)

    years = df.columns.values - min(df.columns)
    years = years.astype(float)

    s['Technology'] = key
    s['CAPEX_2018'] = df.loc['CAPEX_Moderate', 2018]
    s['FixedOM_2018'] = df.loc['FixedOM_Moderate', 2018]
    s['VariableOM_2018'] = df.loc['VariableOM_Moderate', 2018] * 0.000001 * 277777.7778 # convert $/MWh to M$/PJ

    input_vars = ['CAPEX_Advanced', 'CAPEX_Moderate', 'CAPEX_Conservative',
                  'FixedOM_Advanced', 'FixedOM_Moderate', 'FixedOM_Conservative',
                  'VariableOM_Advanced', 'VariableOM_Moderate', 'VariableOM_Conservative']
    output_vars = ['CAPEX_Advanced_rate', 'CAPEX_Moderate_rate', 'CAPEX_Conservative_rate',
                   'FixedOM_Advanced_rate', 'FixedOM_Moderate_rate', 'FixedOM_Conservative_rate',
                   'VariableOM_Advanced_rate', 'VariableOM_Moderate_rate', 'VariableOM_Conservative_rate']
    for input_var, output_var in zip(input_vars, output_vars):
        if df.loc[input_var, 2018] > 0.0:
            ydata = df.loc[input_var, :].values / df.loc[input_var, 2018]
            popt, pcov = curve_fit(func, years, ydata)
            s[output_var] = popt[0]

            # Plot one validation case for each technology
            if input_var == 'CAPEX_Moderate':
                plt.figure()
                plt.plot(years, df.loc[input_var, :].values, 'k.')
                fit = df.loc[input_var, 2018] * np.exp(popt[0] * years)
                plt.plot(years, fit, 'b--')
                save_name = 'curve_fit_CAPEX_' + key + '.png'
                plt.xlabel('Year')
                plt.ylabel('CAPEX ($/kW)')
                plt.ylim(bottom=0.0)
                plt.savefig(save_name)
                plt.close()
        else:
            s[output_var] = 0.0

    # save output
    output = output.append(s, ignore_index=True)

# write to csv
output.to_csv('analyzed_ATB_data.csv')
