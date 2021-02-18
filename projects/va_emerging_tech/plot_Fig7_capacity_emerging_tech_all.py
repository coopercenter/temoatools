import os
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
import matplotlib.patches as mpatches
import matplotlib.colors as colors
import numpy as np

# =====================================
# user inputs
# =====================================
# data input
results_filename = "capacity_by_year.csv"
savename = "Fig7_capacity_emerging_tech.png"

# figure resolution
DPI = 400  # Set resolution for saving figures

x_vars = ['EC_BECCS-CostInvest', 'EC_DAC-CostInvest', 'EC_H2-CostInvest', 'E_OCAES-CostInvest', 'EC_VFB-CostInvest', ]
x_labels = ['BECCS [$/kW]', 'DAC [$/tonne]', '24 hr Hydrogen [$/kW]', '24 hr OCAES [$/kW]',
            '12 hr VFB [$/kW]', ]
x_converts = [1.0, 1.0 / 3.22, 1.0, 1.0, 1.0]  # DAC $/tonne
x_limits = [[], [], [], [], []]
x_scales = ['linear', 'linear', 'linear', 'linear', 'linear']

y_var = "value"
y_converts = [1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 3.22, 1.0]  # DAC tonnes
y_techs = ['EC_BATT', 'EC_BATT_2hr', 'E_OCAES', 'EC_PUMP', 'EC_VFB', 'EC_BECCS', 'EC_BIO', 'EC_DAC', 'EC_H2']
y_labels = ['4 hr Battery', '2 hr Battery', 'OCAES [GW]', 'PUMP [GW]', 'VFB [GW]', 'BECCS [GW]', 'BIO [GW]',
            'DAC [tonne]',
            'Hydrogen [GW]']
y_limits = [[], [], [], [], [], [], [], [], []]
y_scales = ['linear', 'linear', 'linear', 'linear', 'linear', 'linear', 'linear', 'linear', 'linear']

series_var = 'RTE'
series_convert = 100.0
series_label = "Efficiency (%)"

formation_dict = {'LK1': 'B) Lower Cretaceous', 'MK1-3': 'A) Middle Cretaceous', 'UJ1': 'C) Upper Jurassic'}

markersize = 2
# =====================================
# process data
# =====================================

# Import results
os.chdir('monte_carlo')
df = pd.read_csv(results_filename)
os.chdir('..')

# drop unused columns
df = df.drop(['Unnamed: 0', 'Unnamed: 0.1', 'season', 'tod', ], axis=1)

# only look at 2050 capacity
df = df[df.loc[:, 'year'] == 2050]

# drop new nuclear cases
df = df[df.loc[:, 'new_nuclear'] == 'woNuclear']

# drop cases w/o emerging tech
df = df[df.loc[:, 'new_emerg'] == 'wEmerg']

# create new column to distinguish remaining cases
fossil_rename = {'wFossil': 'With Fossil', 'woFossil': 'Without Fossil'}
bio_rename = {'High Bio': 'High Bio', 'Low Bio': 'Low Bio'}
for key in fossil_rename.keys():
    df.loc[df.loc[:, 'new_fossil'] == key, 'new_fossil'] = fossil_rename[key]
for key in bio_rename.keys():
    df.loc[df.loc[:, 'bio'] == key, 'bio'] = bio_rename[key]
df.loc[:, 'case'] = df.loc[:, 'bio'] + ' - ' + df.loc[:, 'new_fossil']
cases = df.loc[:, 'case'].unique()

colors = sns.color_palette("colorblind")

# =====================================
# create plots
# =====================================

# Column width guidelines https://www.elsevier.com/authors/author-schemas/artwork-and-media-instructions/artwork-sizing
# Single column: 90mm = 3.54 in
# 1.5 column: 140 mm = 5.51 in
# 2 column: 190 mm = 7.48 i
width = 10.0  # inches
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

        for case, color in zip(cases, colors):
            # get data
            df3 = df2[(df2.loc[:, 'case'] == case)]

            # convert data
            x = x_convert * df3.loc[:, x_var]
            y = y_convert * df3.loc[:, y_var]

            # prepare color
            c = np.ndarray([1, 3])
            c[0, 0] = color[0]
            c[0, 1] = color[1]
            c[0, 2] = color[2]

            # plot
            im = ax.scatter(x, y, c=c, s=markersize, marker='.', label=case)

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

        # Caption labels
        # caption_labels = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O']
        # plt.text(0.1, 0.9, caption_labels[count], horizontalalignment='center', verticalalignment='center',
        #          transform=ax.transAxes, fontsize='medium', fontweight='bold')
        # count = count + 1

        # plot successful combinations
        # df2 = df[(df.loc[:, 'RTE'] > 0.4) & (df.loc[:, 'sheet_name'] == formation)]
        # x = x_convert * df2.loc[:, x_var]
        # y = y_convert * df2.loc[:, y_var]
#         # ax.scatter(x, y, c='black', s=markersize, marker='.')
#
#         # plot failures
#         # df2 = df[(df.loc[:, 'RTE'] <= 0.4) & (df.loc[:, 'sheet_name'] == formation)]
#         # x = x_convert * df2.loc[:, x_var]
#         # y = y_convert * df2.loc[:, y_var]
#         # ax.scatter(x, y, c='red', s=markersize, marker='.')
#
#         # set background color
#         # ax = plt.gca()
#         # ax.set_facecolor((0.95, 0.95, 0.95))
#
#         # plot additional lines
#         thk_sizing = 10
#         k_sizing = 10
#         if len(y_limit) == 2:
#             ax.plot([thk_sizing, thk_sizing], [k_sizing, y_limit[1]], c=(0, 0, 0), linewidth=1.5, linestyle='--')
#         if len(x_limit) == 2:
#             ax.plot([thk_sizing, x_limit[1]], [k_sizing, k_sizing], c=(0, 0, 0), linewidth=1.5, linestyle='--')
#

#

#

#
#         # top labels
#         if j == 0:
#             plt.text(0.05, 1.05, formation_dict[formation], horizontalalignment='left', verticalalignment='center',
#                      transform=ax.transAxes, fontsize='medium', fontweight='bold')
#
#         # Caption labels
#         # caption_labels = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O']
#         # plt.text(0.1, 0.9, caption_labels[count], horizontalalignment='center', verticalalignment='center',
#         #          transform=ax.transAxes, fontsize='medium', fontweight='bold')
#         # count = count + 1
#
# # Legend
# # patches = [mpatches.Patch(color='black', label='RTE > 40%'), mpatches.Patch(color='red', label='RTE <= 40%')]
# # a[1, 1].legend(handles=patches, bbox_to_anchor=(0.5, -0.275), loc="upper center", ncol=2)
# a_cbar = []
# for ax in a:
#     a_cbar.append(ax[-1])
# cbar = f.colorbar(im, ax=a_cbar, location='right', shrink=0.6, pad=0.2, extendfrac='auto')
# # cbar = f.colorbar(im, ax=a[1, 1], orientation='horizontal', pad=0.2)
# cbar.ax.set_title('Round-trip\nefficiency\n(%)')
# # cbar.set_label('RTE [%]', rotation=0)
# # Adjust layout
# # plt.tight_layout()
# # plt.subplots_adjust(top=0.848,
# #                     bottom=0.13,
# #                     left=0.125,
# #                     right=0.85,
# #                     hspace=0.2,
# #                     wspace=0.2)
# plt.subplots_adjust(top=0.9,
#                     bottom=0.1,
#                     left=0.1,
#                     right=0.85,
#                     hspace=0.2,
#                     wspace=0.2)
# f.align_ylabels(a[:, 0])  # align y labels
#
# # Save Figure
# # plt.savefig(savename, dpi=DPI, bbox_extra_artists=leg)
# plt.savefig(savename, dpi=DPI)
# # plt.close()
