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
savename = "Fig7_2050_capacity_OCAES"

# figure resolution
DPI = 300  # Set resolution for saving figures

x_vars = ['EC_OCAES-CostInvest']
x_labels = ['24-hour OCAES [$/kW]']
x_converts = [1.0]
x_limits = [[]]
x_scales = ['linear']

y_var = "value"
y_converts = [1.0, 1.0, 1.0, 1.0]
y_techs = ['EC_OCAES', 'EC_BATT_2hr', 'EC_BATT_4hr']
y_labels = ['24-hour\nOCAES\n[GW]', '2-hour\nBattery\n[GW]', '4-hour\nBattery\n[GW]']
y_limits = [[0,8], [0,25], [0,50],]
y_scales = ['linear', 'linear', 'linear']

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
bio_rename = {'High Bio': 'High Bio', 'Low Bio': 'Low Bio'}
bio_cases = df.loc[:, 'bio'].unique()
colors1 = sns.color_palette("colorblind")

fossil_rename = {'wFossil': 'With New Fossil', 'woFossil': 'Without New Fossil'}
fossil_cases = df.loc[:, 'new_fossil'].unique()
markers = ['^', 's']

# version 2 - create new column to distinguish remaining cases
fossil_rename = {'wFossil': 'With New Fossil', 'woFossil': 'Without New Fossil'}
bio_rename = {'Low Bio': 'Low Bio', 'High Bio': 'High Bio'}
for f_key in fossil_rename.keys():
    for b_key in bio_rename.keys():
        ind = (df.loc[:, 'new_fossil'] == f_key) & (df.loc[:, 'bio'] == b_key)
        df.loc[ind, 'case'] = bio_rename[b_key] + ' ' + fossil_rename[f_key]
# cases = df.loc[:, 'case'].unique()
cases = ['Low Bio With New Fossil', 'Low Bio Without New Fossil',
         'High Bio With New Fossil', 'High Bio Without New Fossil']
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
        ax.set_ylim(bottom=0)
        if len(y_limit) == 2:
            ax.set_ylim(bottom=y_limit[0], top=y_limit[1])
        if len(x_limit) == 2:
            ax.set_xlim(left=x_limit[0], right=x_limit[1])

        # Plot dashed line to show important value
        if len(y_limit) == 2:
            ax.plot([3200,3200], y_limit, 'k--')
            # ax.set_ylim(bottom=y_limit[0], top=y_limit[1])

        # Despine and remove ticks
        # sns.despine(ax=ax, )
        ax.tick_params(top=False, right=False)

# Legend - Colors
ax = a[len(a) - 1,0]
patches = []
for case, color in zip(cases, colors2):
    patches.append(mpatches.Patch(color=color, label=case))
leg1 = ax.legend(handles=patches, bbox_to_anchor=(0.5, -0.35), loc="upper center", ncol=2)
ax.add_artist(leg1)

# Adjust spacing
plt.subplots_adjust(top=0.95,
                    bottom=0.175,
                    left=0.1,
                    right=0.95,
                    hspace=0.2,
                    wspace=0.09)
# Save Figure
plt.savefig(savename + ".png", dpi=DPI, bbox_extra_artists=leg1)
