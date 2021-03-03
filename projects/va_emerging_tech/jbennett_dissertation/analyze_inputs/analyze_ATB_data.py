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

# import ATB data for analysis
data = pd.read_excel('2020_ATB_CostProjections.xlsx', sheet_name=None)

# prepare DataFrame to store results
entries = [
    'Technology',
    'CAPEX_2019',
    'CAPEX_2025',
    'CAPEX_Advanced_rate',
    'CAPEX_Moderate_rate',
    'CAPEX_Conservative_rate',
    'FixedOM_2019',
    'FixedOM_2025',
    'FixedOM_Advanced_rate',
    'FixedOM_Moderate_rate',
    'FixedOM_Conservative_rate',
    'VariableOM_2019',
    'VariableOM_2025',
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

    # years = df.columns.values - min(df.columns)
    # years = years.astype(float)

    s['Technology'] = key

    # ------------------------------
    # CAPEX
    # ------------------------------
    s['CAPEX_2019'] = df.loc['CAPEX_Moderate', 2019]
    s['CAPEX_2025'] = df.loc['CAPEX_Moderate', 2025]

    input_vars = ['CAPEX_Advanced', 'CAPEX_Moderate', 'CAPEX_Conservative']
    output_vars = ['CAPEX_Advanced_rate', 'CAPEX_Moderate_rate', 'CAPEX_Conservative_rate']
    for input_var, output_var in zip(input_vars, output_vars):
        if df.loc[input_var, 2025] > 0.0:
            curve_fit_type = 'endYear'
            y_2025 = df.loc['CAPEX_Moderate', 2025]
            y_2050 = df.loc[input_var, 2050]
            exponent = np.log(y_2050 / y_2025) / (2050 - 2025)
            s[output_var] = exponent
        else:
            s[output_var] = 0.0

    # ------------------------------
    # Fixed O&M
    # ------------------------------
    s['FixedOM_2019'] = df.loc['FixedOM_Moderate', 2019]
    s['FixedOM_2025'] = df.loc['FixedOM_Moderate', 2025]

    input_vars = ['FixedOM_Advanced', 'FixedOM_Moderate', 'FixedOM_Conservative']
    output_vars = ['FixedOM_Advanced_rate', 'FixedOM_Moderate_rate', 'FixedOM_Conservative_rate']
    for input_var, output_var in zip(input_vars, output_vars):
        if df.loc[input_var, 2025] > 0.0:
            curve_fit_type = 'endYear'
            y_2025 = df.loc['FixedOM_Moderate', 2025]
            y_2050 = df.loc[input_var, 2050]
            exponent = np.log(y_2050 / y_2025) / (2050 - 2025)
            s[output_var] = exponent
        else:
            s[output_var] = 0.0

    # ------------------------------
    # Variable O&M
    # ------------------------------
    s['VariableOM_2019'] = df.loc['VariableOM_Moderate', 2019] * 0.000001 * 277777.7778  # convert $/MWh to M$/PJ
    s['VariableOM_2025'] = df.loc['VariableOM_Moderate', 2025] * 0.000001 * 277777.7778  # convert $/MWh to M$/PJ

    input_vars = ['VariableOM_Advanced', 'VariableOM_Moderate', 'VariableOM_Conservative']
    output_vars = ['VariableOM_Advanced_rate', 'VariableOM_Moderate_rate', 'VariableOM_Conservative_rate']
    for input_var, output_var in zip(input_vars, output_vars):
        if df.loc[input_var, 2025] > 0.0:
            curve_fit_type = 'endYear'
            y_2025 = df.loc['VariableOM_Moderate', 2025]
            y_2050 = df.loc[input_var, 2050]
            exponent = np.log(y_2050 / y_2025) / (2050 - 2025)
            s[output_var] = exponent
        else:
            s[output_var] = 0.0

    # save output
    output = output.append(s, ignore_index=True)

    # Plot one validation case for each technology
    plt.figure()
    years = df.columns.values
    plt.plot(years, df.loc['CAPEX_Advanced', :].values, 'k.')
    plt.plot(years, df.loc['CAPEX_Moderate', :].values, 'k.')
    plt.plot(years, df.loc['CAPEX_Conservative', :].values, 'k.')

    years = np.arange(0, 25)
    fit1 = s['CAPEX_2025'] * np.exp(s['CAPEX_Advanced_rate'] * years)
    fit2 = s['CAPEX_2025'] * np.exp(s['CAPEX_Moderate_rate'] * years)
    fit3 = s['CAPEX_2025'] * np.exp(s['CAPEX_Conservative_rate'] * years)
    years = years + 2025
    plt.plot(years, fit1, 'r--')
    plt.plot(years, fit2, 'b--')
    plt.plot(years, fit3, 'g--')
    save_name = key + '_curve_fit_CAPEX.png'
    plt.xlabel('Year')
    plt.ylabel('CAPEX ($/kW)')
    plt.ylim(bottom=0.0)
    plt.savefig(save_name)
    plt.close()

# write to csv
output.to_csv('analyzed_ATB_data.csv')
