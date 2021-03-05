import os
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
import matplotlib.patches as mpatches
import matplotlib.colors as colors
import matplotlib.lines as mlines
import numpy as np

# =====================================
# user inputs
# =====================================
# data input
results_filename = "capacity_by_year.csv"
savename = "Fig8_2050_capacity_emerging_NET"

# figure resolution
DPI = 300  # Set resolution for saving figures


# https://matplotlib.org/stable/tutorials/text/mathtext.html

x_vars = ['EC_BECCS-CostInvest', 'EC_DAC-CostInvest']
x_labels = [r"BECCS [\$/(t CO$_2$/yr)]", r'DAC [\$/(t CO$_2$/yr)]']
x_converts = [1.0/8.37, 1.0 / 3.22]  # $/kW to $/tonne
x_limits = [[], []]
x_scales = ['linear', 'linear']

y_var = "value"
y_converts = [8.37, 3.22]  # $/kW to $/tonne
y_techs = ['EC_BECCS', 'EC_DAC']
y_labels = [r'BECCS [Mt CO$_2$/yr]', r'DAC [Mt CO$_2$/yr]']
y_limits = [[0,15], [0,15]]
y_scales = ['linear', 'linear']

markersize = 5
# =====================================
# process data
# =====================================

# Import results
wrk_dir = os.getcwd()
os.chdir('../monte_carlo')
df = pd.read_csv(results_filename)
os.chdir(wrk_dir)

# drop unused columns
df = df.drop(['Unnamed: 0', 'Unnamed: 0.1', 'season', 'tod', ], axis=1)

# only look at 2050 capacity
df = df[df.loc[:, 'year'] == 2050]

# drop cases w/o emerging tech
df = df[df.loc[:, 'new_emerg'] == 'wEmerg']

# version 1 - separate colors and markers
bio_rename = {'High Bio': 'High', 'Low Bio': 'Low'}
bio_cases = df.loc[:, 'bio'].unique()
colors1 = sns.color_palette("colorblind")

fossil_rename = {'wFossil': 'With', 'woFossil': 'Without'}
fossil_cases = df.loc[:, 'new_fossil'].unique()
markers = ['^', 's']

# version 2 - create new column to distinguish remaining cases
fossil_rename = {'wFossil': 'With Fossil', 'woFossil': 'Without Fossil'}
bio_rename = {'Low Bio': 'Low Bio', 'High Bio': 'High Bio'}
for f_key in fossil_rename.keys():
    for b_key in bio_rename.keys():
        ind = (df.loc[:, 'new_fossil'] == f_key) & (df.loc[:, 'bio'] == b_key)
        df.loc[ind, 'case'] = bio_rename[b_key] + ' ' + fossil_rename[f_key]
# cases = df.loc[:, 'case'].unique()
cases = ['Low Bio With Fossil', 'Low Bio Without Fossil',
         'High Bio With Fossil', 'High Bio Without Fossil']
colors2 = sns.color_palette('Paired')

# =====================================
# create plot version 2 - only colors
# =====================================

# Column width guidelines https://www.elsevier.com/authors/author-schemas/artwork-and-media-instructions/artwork-sizing
# Single column: 90mm = 3.54 in
# 1.5 column: 140 mm = 5.51 in
# 2 column: 190 mm = 7.48 i
width = 7.48  # inches
height = 5.5  # inches

# Create plot
f, a = plt.subplots(len(y_techs), len(x_vars), sharex='col', sharey='row', squeeze=False,
                    constrained_layout=True)

# Set size
f.set_size_inches(width, height)

# Set style and context
sns.set_style("white", {"font.family": "serif", "font.serif": ["Times", "Palatino", "serif"]})
sns.set_context("paper")
sns.set_style("ticks", {"xtick.major.size": 8, "ytick.major.size": 8})

count = 0
# iterate through y-variables
for j, (y_tech, y_label, y_limit, y_scale, y_convert) in enumerate(
        zip(y_techs, y_labels, y_limits, y_scales, y_converts)):

    # get data
    df2 = df[(df.loc[:, 'tech_or_fuel'] == y_tech)]

    # iterate through x-variables
    for i, (x_var, x_label, x_convert, x_limit, x_scale) in enumerate(
            zip(x_vars, x_labels, x_converts, x_limits, x_scales)):

        # access subplot
        ax = a[j, i]

        for case, color in zip(cases, colors2):
            # get data
            df3 = df2[(df2.loc[:, 'case'] == case)]

            # convert data
            x = x_convert * df3.loc[:, x_var]
            y = y_convert * df3.loc[:, y_var]

            # plot
            ax.plot(x, y,
                    linestyle='',
                    marker='.',
                    markersize=markersize,
                    markeredgecolor=color,
                    markerfacecolor='None')

        # axes labels
        # x-axis labels (only bottom)
        if j == len(y_techs) - 1:
            ax.set_xlabel(x_label)
        else:
            ax.get_xaxis().set_visible(False)

        # y-axis labels (only left side)
        if i == 0:
            ax.set_ylabel(y_label)
        else:
            ax.get_yaxis().set_visible(False)

        # axes scales
        ax.set_xscale(x_scale)
        ax.set_yscale(y_scale)

        # Axes limits
        if len(y_limit) == 2:
            ax.set_ylim(bottom=y_limit[0], top=y_limit[1])
        if len(x_limit) == 2:
            ax.set_xlim(left=x_limit[0], right=x_limit[1])

        # Despine and remove ticks
        # sns.despine(ax=ax, )
        ax.tick_params(top=False, right=False)

# Legend - Colors
ax = a[len(a) - 1, 1]
patches = []
for case, color in zip(cases, colors2):
    patches.append(mpatches.Patch(color=color, label=case))
leg1 = ax.legend(handles=patches, bbox_to_anchor=(-0.1, -0.25), loc="upper center", ncol=4)
ax.add_artist(leg1)

# Adjust spacing
plt.subplots_adjust(top=0.95,
                    bottom=0.155,
                    left=0.08,
                    right=0.95,
                    hspace=0.15,
                    wspace=0.07)
# Save Figure
plt.savefig(savename + ".png", dpi=DPI, bbox_extra_artists=leg1)