import matplotlib.pyplot as plt
import seaborn as sns
# ====================
# data to plot
# ====================
# demand
demand_year = [2019,
               2025,
               2030,
               2035,
               2040,
               2045,
               2050]
demand_PJ = [315,
             461.4,
             509.7,
             564.8,
             616.8,
             668.8,
             720.8]
# emission limit
emi_year = [2025,
            2030,
            2035,
            2040,
            2045,
            2050]
emi_limit_Mt = [23.800,
                19.040,
                14.280,
                9.520,
                4.760,
                0]

# ====================
# plot
# based on: https://matplotlib.org/stable/gallery/subplots_axes_and_figures/two_scales.html
# ====================
colors = sns.color_palette("colorblind")

# Column width guidelines https://www.elsevier.com/authors/author-schemas/artwork-and-media-instructions/artwork-sizing
# Single column: 90mm = 3.54 in
# 1.5 column: 140 mm = 5.51 in
# 2 column: 190 mm = 7.48 i
width = 4.5  # inches
height = 3.5  # inches

fig, ax1 = plt.subplots()

# Set size
fig.set_size_inches(width, height)

color = colors[0]
# color = "#E69F00"
ax1.set_xlabel('Year')
ax1.set_ylabel('Demand [PJ]', color=color)
ax1.set_ylim(bottom=0, top=800)
ax1.plot(demand_year, demand_PJ, color=color, marker='o')
ax1.tick_params(axis='y', labelcolor=color)

ax2 = ax1.twinx()  # instantiate a second axes that shares the same x-axis

color = colors[1]
# color = "#56B4E9"
ax2.set_ylabel('Emission limit [Mt]', color=color)  # we already handled the x-label with ax1
ax2.set_ylim(bottom=0, top=25)
ax2.plot(emi_year, emi_limit_Mt, color=color, marker='o')
ax2.tick_params(axis='y', labelcolor=color)

fig.tight_layout()  # otherwise the right y-label is slightly clipped
plt.show()
plt.savefig('Fig4_demand_emission_limit.png', DPI=300)
