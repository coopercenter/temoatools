# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
"""
BLIS - Balancing Load of Intermittent Solar:
A characteristic-based transient power plant model

Copyright (C) 2020. University of Virginia Licensing & Ventures Group (UVA LVG). All Rights Reserved.

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
documentation files (the "Software"), to deal in the Software without restriction, including without limitation
the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the
Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
"""
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

import pandas as pd
import numpy as np


# =============================================================================#
# Create MonteCarlo Inputs
# =============================================================================#
def createMonteCarloCases_distributions(filename, sheet_name, iterations):
    # Read Excel with inputs
    df_xls = pd.read_excel(filename, sheet_name=sheet_name)  # , index_col=[0, 1, 2])

    # Create Empty DataFrame
    general_cols = ['sheet_name', 'type', 'variable', 'tech']
    dist_cols = list(range(iterations))
    cols = general_cols + dist_cols
    df = pd.DataFrame(columns=cols)

    # Create Inputs
    for index in df_xls.index:

        # store general information
        df.loc[index, 'sheet_name'] = sheet_name
        df.loc[index, 'type'] = df_xls.loc[index, 'type']
        df.loc[index, 'variable'] = df_xls.loc[index, 'variable']
        df.loc[index, 'tech'] = df_xls.loc[index, 'tech']

        # extract distribution type
        dist_type = df_xls.loc[index, "distribution"]

        # Constants
        if dist_type == "constant" or dist_type == "Constant" or dist_type == "C":
            avg = df_xls.loc[index, "average"]
            df.loc[index, dist_cols] = avg

        # Uniform Distributions - specified low and high values
        elif dist_type == "uniform" or dist_type == "Uniform" or dist_type == "U":
            low = df_xls.loc[index, "low"]
            high = df_xls.loc[index, "high"]
            df.loc[index, dist_cols] = np.random.uniform(low=low, high=high, size=iterations)

        # Uniform Distributions - (+/-) 10 % perturbation from average
        elif dist_type == "uniform_perturb10" or dist_type == "Uniform_perturb10":
            low = 0.9 * df_xls.loc[index, "average"]
            high = 1.1 * df_xls.loc[index, "average"]
            df.loc[index, dist_cols] = np.random.uniform(low=low, high=high, size=iterations)

        # Normal Distributions
        elif dist_type == "normal" or dist_type == "Normal" or dist_type == "N":
            avg = df_xls.loc[index, "average"]
            stdev = df_xls.loc[index, "stdev"]
            df.loc[index, dist_cols] = np.random.normal(loc=avg, scale=stdev, size=iterations)

        # LogNormal Distributions
        elif dist_type == "lognormal" or dist_type == "Lognormal" or dist_type == "LN":
            avg = df_xls.loc[index, "average"]
            stdev = df_xls.loc[index, "stdev"]
            df.loc[index, dist_cols] = np.random.lognormal(mean=avg, sigma=stdev, size=iterations)

        # Triangular Distributions
        elif dist_type == "triangle" or dist_type == "Triangle" or dist_type == "T":
            left = df_xls.loc[index, "low"]
            mode = df_xls.loc[index, "average"]
            right = df_xls.loc[index, "high"]
            df.loc[index, dist_cols] = np.random.triangular(left, mode, right, size=iterations)

    return df
