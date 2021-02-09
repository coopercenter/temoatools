library(dplyr)
library(RSQLite)
library(ggplot2)
library(scales)
library(gridExtra)
library(grid)
library("ggpubr")
library('hash')
library(RColorBrewer)

# inputs
db = 'wEmerg_wFossil_combined_2050.sqlite' # database to analyze, assumed to be in results directory

# This is order that items will be plotted, only items included will be plotted
tech_rename <- c(
  'E_BECCS'="'Bioenergy with CCS (BECCS)'",
  'EC_COAL'="'Coal'",
  'EC_BIO'="'Biomass'",
  'EF_WIND'="'Offshore Wind - Floating'",
  'EC_WIND'="'Offshore Wind - Fixed bottom'",
  'E_SCO2'="'Natural Gas with CCS - sCO'[2]",
  'EC_PUMP'="'Pumped Hydro Storage (12 hour)'",
  'E_OCAES'="'Offshore CAES (24 hour)'",
  'EC_NG_CC'="'Natural Gas and Oil Combined Cycle'",
  'E_PV_DIST_RES'="'Solar PV - Residential'",
  'EC_NG_OC'="'Natural Gas Turbine'",
  'ED_SOLPV'="'Solar PV - Commercial'",
  'EC_SOLPV'="'Solar PV - Utility'",
  'EC_BATT'="'Battery (4 hour)'")

h <- hash()
h[['E_BECCS']] <- c('green', 'solid')
h[['EC_PUMP']] <- c('pink', 'solid')
h[['EC_COAL']] <- c('black', 'solid')
h[['EC_BIO']] <- c('green', 'dashed')
h[['E_SCO2']] <- c('red', 'dotted')
h[['EF_WIND']] <- c('darkblue', 'solid')
h[['EC_WIND']] <- c('darkblue', 'dashed')
h[['E_OCAES']] <- c('lightblue', 'solid')
h[['EC_NG_CC']] <- c('red', 'solid')
h[['EC_NG_OC']] <- c('red', 'dashed')
h[['E_PV_DIST_RES']] <- c('orange', 'dotted')
h[['ED_SOLPV']] <- c('orange', 'solid')
h[['EC_SOLPV']] <- c('orange', 'dashed')
h[['EC_BATT']] <- c('gray', 'solid')

# http://www.cookbook-r.com/Graphs/Colors_(ggplot2)/
colors <- hash()
colors[['black']] <- "#000000"
colors[['gray']] <- "#999999"
colors[['orange']] <- "#E69F00"
colors[['lightblue']] <- "#56B4E9"
colors[['green']] <- "#009E73"
colors[['yellow']] <- "#F0E442"
colors[['darkblue']] <- "#0072B2"
colors[['red']] <- "#D55E00"
colors[['pink']] <- "#CC79A7"
colors[['brown']] <- "#993300"


# tech_palette <- brewer.pal(n=length(tech_rename),name="Set1") # Use a predefined a palette https://www.datanovia.com/en/blog/top-r-color-palettes-to-know-for-great-data-visualization/
#tech_palette <- colorRampPalette(brewer.pal(8, "Set1"))(length(tech_rename)) # Use a predefined a palette https://www.datanovia.com/en/blog/easy-way-to-expand-color-palettes-in-r/

fuel_rename <- c('IMPOIL'="Oil",
                 'IMPNATGAS'="Natural gas",
                 'IMPBIO'="Biomass",
                 'IMPCOAL'="Coal",
                 'IMPNUCLEAR'="Nuclear")
fuel_palette <- c(colors[['brown']], colors[['red']], colors[['green']], colors[['black']], colors[['pink']])
fuel_line_styles <- c('solid', 'solid','dashed','solid','solid')

 
# Column width guidelines https://www.elsevier.com/authors/author-schemas/artwork-and-media-instructions/artwork-sizing
# Single column: 90mm = 3.54 in
# 1.5 column: 140 mm = 5.51 in
# 2 column: 190 mm = 7.48 in

# ======================== #
# begin code
# ======================== #
dir_work = dirname(rstudioapi::getSourceEditorContext()$path)
setwd(dir_work)
setwd('../../databases')

# connect to database
con <- dbConnect(SQLite(),db)
setwd(dir_work)

# -------------------------
# process tech_rename, hash, and colors
# split each into a list of technologies (i.e. tech_list) and names to be used (i.e. tech_levels)
# -------------------------
temp <- as.list(tech_rename)
tech_list <- c()
tech_levels <- c()
tech_palette <- c()
line_styles <- c()
line_style_rename <- tech_rename
for (i in 1:length(tech_rename)) {
  name <-names(temp[i])
  tech_list <- c(tech_list, name)
  tech_levels <- c(tech_levels, temp[[i]])
  
  color_name <- h[[name]][1]
  line_style <- h[[name]][2]
  tech_palette <- c(tech_palette, colors[[color_name]])
  line_styles <- c(line_styles, line_style)
}

temp <- as.list(fuel_rename)
fuel_list <- c()
fuel_levels <- c()
for (i in 1:length(fuel_rename)) {
  fuel_list <- c(fuel_list, names(temp[i]))
  fuel_levels <- c(fuel_levels, temp[[i]])
}

# Set color palette
options(ggplot2.discrete.fill = tech_palette)
options(ggplot2.discrete.color = tech_palette)
options(ggplot2.continuous.color = tech_palette)
options(ggplot2.continuous.color = tech_palette)

# -------------------------
# Power Plant Investment Costs
table = 'CostInvest'
savename = 'Inputs_PowerPlants_InvestmentCosts.png'
# -------------------------

# read-in data
tbl <- dbReadTable(con, table)

# process data
tbl <- tbl[tbl$tech %in% tech_list, ] # only plot tech in list
tbl <- transform(tbl, tech = tech_rename[as.character(tech)]) # rename tech
tbl$tech <- factor(tbl$tech,levels = tech_levels) # Plot series in specified order
names(tbl)[names(tbl) == "tech"] <- "Technologies" # rename column

# plot
plot_CAPEX <- ggplot(data=tbl, aes_string(x='vintage',y='cost_invest',color='Technologies',linetype='Technologies'))+
  geom_line()+
  scale_linetype_manual(values=line_styles,labels=parse_format())+
  scale_color_manual(values=tech_palette,labels=parse_format())+
  scale_y_continuous(expand = c(0, 0), limits = c(0, NA)) + 
  labs(x='Year (-)', y=expression(paste("CAPEX (US$ KW"^-1,")")))+
  theme(panel.background = element_rect(fill = NA, colour ="black"),
      panel.border = element_rect(linetype="solid", fill=NA),
      legend.background=element_rect(fill = alpha("white", 0)),
      legend.key = element_rect(colour = "transparent", fill = "white"))

plot_CAPEX_gray <- ggplot(data=tbl, aes_string(x='vintage',y='cost_invest',color='Technologies',linetype='Technologies'))+
  geom_line()+
  scale_linetype_manual(values=line_styles,labels=parse_format())+
  scale_color_manual(values=tech_palette,labels=parse_format())+
  scale_y_continuous(expand = c(0, 0), limits = c(0, NA)) + 
  labs(x='Year (-)', y=expression(paste("CAPEX (US$ KW"^-1,")")))+
  theme(panel.background = element_rect(colour ="black"),
        panel.border = element_rect(linetype="solid", fill=NA),
        legend.key = element_rect(colour = "transparent"))

# save
# ggsave(savename, device="png", width=7.48, height=5.5, units="in",dpi=300)


# -------------------------
# Power Plant Variable Costs
# table = 'CostVariable'
# savename = 'Inputs_PowerPlants_VariableCosts.png'
# conversion = 277.777778 # M$/PJ to $/kWh
# # -------------------------
# 
# # read-in data
# tbl <- dbReadTable(con, table)
# 
# # process data
# tbl <- tbl[tbl$tech %in% tech_list, ]
# tbl <- transform(tbl, tech = tech_rename[as.character(tech)])
# tbl$cost_variable <- tbl$cost_variable * conversion
# tbl$tech <- factor(tbl$tech,levels = tech_levels)
# names(tbl)[names(tbl) == "tech"] <- "Technologies" # rename column
# 
# # plot
# ggplot(data=tbl, aes_string(x='periods',y='cost_variable',color='Technologies',linetype='Technologies'))+
#   geom_line()+
#   scale_linetype_manual(values=line_styles,labels=parse_format())+
#   scale_color_manual(values=tech_palette,labels=parse_format())+
#   labs(x='Year (-)', y=expression(paste("Variable O&M (US$ kWh"^-1,")")))+
#   theme(panel.background = element_rect(fill = NA, colour ="black"),
#         panel.border = element_rect(linetype="solid", fill=NA),
#         legend.background=element_rect(fill = alpha("white", 0)),
#         legend.key = element_rect(colour = "transparent", fill = "white"))
# 
# # save
# ggsave(savename, device="png", width=7.48, height=5.5, units="in",dpi=300)


# -------------------------
# Power Plant Fixed Costs
# table = 'CostFixed'
# savename = 'Inputs_PowerPlants_FixedCosts.png'
# # -------------------------
# 
# # read-in data
# tbl <- dbReadTable(con, table)
# 
# # process data
# tbl <- tbl[tbl$tech %in% tech_list, ]
# tbl <- transform(tbl, tech = tech_rename[as.character(tech)])
# tbl$tech <- factor(tbl$tech,levels = tech_levels)
# names(tbl)[names(tbl) == "tech"] <- "Technologies" # rename column
# 
# # plot
# ggplot(data=tbl, aes_string(x='periods',y='cost_fixed',color='Technologies',linetype='Technologies'))+
#   geom_line()+
#   scale_linetype_manual(values=line_styles,labels=parse_format())+
#   scale_color_manual(values=tech_palette,labels=parse_format())+
#   labs(x='Year (-)', y=expression(paste("Fixed O&M (US$ KW"^-1,")")))+
#   theme(panel.background = element_rect(fill = NA, colour ="black"),
#         panel.border = element_rect(linetype="solid", fill=NA),
#         legend.background=element_rect(fill = alpha("white", 0)),
#         legend.key = element_rect(colour = "transparent", fill = "white"))
# # save
# ggsave(savename, device="png", width=7.48, height=5.5, units="in",dpi=300)

# -------------------------
# Fuel Costs
table = 'CostVariable'
savename = 'Inputs_Fuels_VariableCosts.png'
# -------------------------

# Set color palette
options(ggplot2.discrete.fill = fuel_palette)
options(ggplot2.discrete.color = fuel_palette)
options(ggplot2.continuous.color = fuel_palette)
options(ggplot2.continuous.color = fuel_palette)

# read-in data
tbl <- dbReadTable(con, table)

# process data
tbl <- tbl[tbl$tech %in% fuel_list, ]
tbl <- transform(tbl, tech = fuel_rename[as.character(tech)])
tbl$tech <- factor(tbl$tech,levels = fuel_levels)

plot
plot_Fuels <- ggplot(data=tbl, aes_string(x='periods',y='cost_variable',color='tech'))+
  geom_line()+
  scale_linetype_manual(values=fuel_line_styles,labels=parse_format())+
  scale_y_continuous(expand = c(0, 0), limits = c(0, NA)) + 
  labs(x='Year (-)', y=expression(paste("Cost (US$ MJ"^-1,")   ")),
       col='Fuels')+
  theme(panel.background = element_rect(fill = NA, colour ="black"),
        panel.border = element_rect(linetype="solid", fill=NA),
        legend.background=element_rect(fill = alpha("white", 0)),
        legend.key = element_rect(colour = "transparent", fill = "white"))

plot_Fuels_gray <- ggplot(data=tbl, aes_string(x='periods',y='cost_variable',color='tech'))+
  geom_line()+
  scale_linetype_manual(values=fuel_line_styles,labels=parse_format())+
  scale_y_continuous(expand = c(0, 0), limits = c(0, NA)) + 
  labs(x='Year (-)', y=expression(paste("Cost (US$ MJ"^-1,")   ")),
       col='Fuels')+
  theme(panel.background = element_rect(colour ="black"),
        panel.border = element_rect(linetype="solid", fill=NA),
        legend.key = element_rect(colour = "transparent"))

# save
# ggsave(savename, device="png", width=3.54, height=3.54, units="in",dpi=300)


# --------------------------
# combine technology inputs into single figure
# https://www.datanovia.com/en/lessons/combine-multiple-ggplots-into-a-figure/
# --------------------------
ggarrange(plot_CAPEX, plot_Fuels, nrow=2, ncol=1, heights = c(2.5,1), align="v", 
          labels= c("A", "B"), label.x = 0.0, label.y = 1.0)


# grid.newpage()
# grid.arrange( ggplotGrob(plot_CAPEX), ggplotGrob(plot_Fuels), nrow=1, ncol=2, widths=c(2,1))

# save
savename = 'Fig3_Inputs_Costs_Overview_white.png'
ggsave(savename, device="png", width=7.48, height=7.0, units="in",dpi=500)

###########

ggarrange(plot_CAPEX_gray, plot_Fuels_gray, nrow=2, ncol=1, heights = c(2.5,1), align="v", 
          labels= c("A", "B"), label.x = 0.0, label.y = 1.0)

savename = 'Fig3_Inputs_Costs_Overview_gray.png'
ggsave(savename, device="png", width=7.48, height=7.0, units="in",dpi=500)

# -------------------------
# finish program and tidy up
# -------------------------
# disconnect from database
dbDisconnect(con)
# return to original directory
setwd(dir_work)