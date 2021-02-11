import time
import numpy as np
import pandas as pd
import temoatools as tt


def get_series(scenario, iteration, db):
    # create Pandas Series
    entries = ['scenario', 'iteration', 'database', 'quantity', 'quantity_type', 'tech_or_fuel', 'year', 'season',
               'tod', 'value']
    s = pd.Series(index=entries)

    # populate required entries
    s['scenario'] = scenario
    s['iteration'] = iteration
    s['database'] = db

    # set remaining entries to nan as default
    s['quantity'] = np.nan
    s['quantity_type'] = np.nan
    s['tech_or_fuel'] = np.nan
    s['year'] = np.nan
    s['season'] = np.nan
    s['tod'] = np.nan
    s['value'] = np.nan

    return s


def get_df(scenario, iteration, db, n_rows):
    # create Pandas DataFrame
    entries = ['scenario', 'iteration', 'database', 'quantity', 'quantity_type', 'tech_or_fuel', 'year', 'season',
               'tod', 'value']
    mc_df = pd.DataFrame(index=range(n_rows), columns=entries)

    # populate required entries
    mc_df.loc[:, 'scenario'] = scenario
    mc_df.loc[:, 'iteration'] = iteration
    mc_df.loc[:, 'database'] = db

    # set remaining entries to nan as default
    mc_df.loc[:, 'quantity'] = np.nan
    mc_df.loc[:, 'quantity_type'] = np.nan
    mc_df.loc[:, 'tech_or_fuel'] = np.nan
    mc_df.loc[:, 'year'] = np.nan
    mc_df.loc[:, 'season'] = np.nan
    mc_df.loc[:, 'tod'] = np.nan
    mc_df.loc[:, 'value'] = np.nan

    return mc_df


def analyze_db(folder, db, scenario='default', iteration=0, switch='fuel', tod_analysis=False, debug=False):
    # ==============================================================================
    #    required inputs:
    #    1) folder         - path containing db
    #    2) db             - names of database
    #    optional inputs:
    #    3) scenario       - unique name of this Monte Carlo simulation
    #    4) iteration      - integer representing the iteration within the Monte Carlo simulation
    #    5) switch         - 'fuel' or 'tech', basis of categorization
    #    6) tod_analysis   - if True, performs time of day analysis
    #
    #    outputs:
    #    1) output          - pandas DataFrame holding all results
    # ==============================================================================

    if debug:
        t0 = time.time()

    # -----------------------------------
    # create dataframe to hold outputs
    # -----------------------------------
    output = pd.DataFrame()

    # -----------------------------------
    # check for appropriate value of switch
    # -----------------------------------
    if switch not in ['tech', 'fuel']:
        switch = 'fuel'

    # -----------------------------------
    # yearly_costs and LCOE
    # -----------------------------------
    yearly_costs, LCOE = tt.getCosts(folder, db)

    # LCOE
    row = get_series(scenario, iteration, db)
    row['quantity'] = 'LCOE'
    row['value'] = LCOE['LCOE'].values[0]
    output = output.append(row, ignore_index=True)

    # yearly_costs
    yearly_costs = yearly_costs.drop(columns=['database', 'scenario'])
    df = get_df(scenario, iteration, db, yearly_costs.shape[1])
    df.loc[:, 'quantity'] = 'costs_by_year'
    df.loc[:, 'year'] = yearly_costs.columns
    df.loc[:, 'value'] = yearly_costs.loc[0, :].values
    output = output.append(df, ignore_index=True)

    if debug:
        t1 = time.time()

    # -----------------------------------
    # yearly_emissions and average_emissions
    # -----------------------------------
    yearly_emissions, average_emissions = tt.getEmissions(folder, db)

    # average_emissions
    row = get_series(scenario, iteration, db)
    row['quantity'] = 'average_emissions'
    row['value'] = average_emissions['avgEmissions'].values[0]
    output = output.append(row, ignore_index=True)

    # yearly_emissions
    yearly_emissions = yearly_emissions.drop(columns=['database', 'scenario'])
    df = get_df(scenario, iteration, db, yearly_costs.shape[1])
    df.loc[:, 'quantity'] = 'emissions_by_year'
    df.loc[:, 'year'] = yearly_emissions.columns
    df.loc[:, 'value'] = yearly_emissions.loc[0, :].values
    output = output.append(df, ignore_index=True)

    if debug:
        t2 = time.time()

    # -----------------------------------
    # capacity_by_year
    # -----------------------------------
    # analyze
    capacity_by_year = tt.getCapacity(folder, db, switch=switch)
    capacity_by_year = capacity_by_year.drop(columns=['database', 'scenario'])
    # reorganize
    temp = pd.melt(capacity_by_year, id_vars=['fuelOrTech'], var_name='year')
    # store results
    df = get_df(scenario, iteration, db, temp.shape[0])
    df.loc[:, 'quantity'] = 'capacity_by_year'
    df.loc[:, 'quantity_type'] = switch
    df.loc[:, 'tech_or_fuel'] = temp.loc[:, 'fuelOrTech'].values
    df.loc[:, 'year'] = temp.loc[:, 'year'].values
    df.loc[:, 'value'] = temp.loc[:, 'value'].values
    output = output.append(df, ignore_index=True)

    if debug:
        t3 = time.time()

    # -----------------------------------
    # activity_by_year
    # -----------------------------------
    # analyze
    activity_by_year = tt.getActivity(folder, db, switch=switch)
    activity_by_year = activity_by_year.drop(columns=['database', 'scenario'])
    # reorganize
    temp = pd.melt(activity_by_year, id_vars=['fuelOrTech'], var_name='year')
    # store results
    df = get_df(scenario, iteration, db, temp.shape[0])
    df.loc[:, 'quantity'] = 'activity_by_year'
    df.loc[:, 'quantity_type'] = switch
    df.loc[:, 'tech_or_fuel'] = temp.loc[:, 'fuelOrTech'].values
    df.loc[:, 'year'] = temp.loc[:, 'year'].values
    df.loc[:, 'value'] = temp.loc[:, 'value'].values
    output = output.append(df, ignore_index=True)

    if debug:
        t4 = time.time()

    # -----------------------------------
    # activity_by_tod
    # -----------------------------------
    if tod_analysis:
        # analyze
        activity_by_tod = tt.getActivityTOD(folder, db, switch=switch)
        activity_by_tod = activity_by_tod.drop(columns=['database', 'scenario'])
        # store results
        df = get_df(scenario, iteration, db, activity_by_tod.shape[0])
        df.loc[:, 'quantity'] = 'activity_by_tod'
        df.loc[:, 'quantity_type'] = switch
        df.loc[:, 'tech_or_fuel'] = activity_by_tod.loc[:, 'fuelOrTech'].values
        df.loc[:, 'year'] = activity_by_tod.loc[:, 'year'].values
        df.loc[:, 'season'] = activity_by_tod.loc[:, 'season'].values
        df.loc[:, 'tod'] = activity_by_tod.loc[:, 'tod'].values
        df.loc[:, 'value'] = activity_by_tod.loc[:, 'value'].values
        output = output.append(df, ignore_index=True)

    if debug:
        t5 = time.time()
        print('Run time per analysis (seconds):')
        print('costs            :' + str(t1 - t0))
        print('emissions        :' + str(t2 - t1))
        print('capacity_by_year :' + str(t3 - t2))
        print('activity_by_year :' + str(t4 - t3))
        print('activity_by_tod  :' + str(t5 - t4))

    return output
