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
db = 'all.sqlite' # database to analyze, assumed to be in results directory

# This is order that items will be plotted, only items included will be plotted
tech_rename <- c(
  'E_BECCS'="'Bioenergy with CCS (BECCS)'",
  'EC_PUMP'="'Pumped Hydro Storage'",
  'EC_COAL'="'Coal'",
  'E_BIO'="'Biomass'",
  'E_SCO2'="'Natural Gas with CCS - sCO'[2]",
  'EF_WIND'="'Offshore Wind - Floating'",
  'EC_WIND'="'Offshore Wind - Fixed bottom'",
  'E_OCAES'="'Offshore CAES'",
  'EC_NG_CC'="'Natural Gas and Oil Combined Cycle'",
  'EC_NG_OC'="'Natural Gas Turbine'",
  'E_PV_DIST_RES'="'Solar PV - Residential'",
  'ED_SOLPV'="'Solar PV - Commercial'",
  'EC_SOLPV'="'Solar PV - Utility'",
  'EC_BATT'="'Battery'")

h <- hash()
h[['E_BECCS']] <- c('green', 'solid')
h[['EC_PUMP']] <- c('pink', 'solid')
h[['EC_COAL']] <- c('black', 'solid')
h[['E_BIO']] <- c('green', 'dashed')
h[['E_SCO2']] <- c('red', 'solid')
h[['EF_WIND']] <- c('darkblue', 'solid')
h[['EC_WIND']] <- c('darkblue', 'dashed')
h[['E_OCAES']] <- c('lightblue', 'solid')
h[['EC_NG_CC']] <- c('red', 'dashed')
h[['EC_NG_OC']] <- c('red', 'dotted')
h[['E_PV_DIST_RES']] <- c('orange', 'solid')
h[['ED_SOLPV']] <- c('orange', 'dashed')
h[['EC_SOLPV']] <- c('orange', 'dotted')
h[['EC_BATT']] <- c('gray', 'solid')

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


# tech_palette  <- c("#E69F00", "#000000", "#56B4E9", "#009E73", "#F0E442", "#0072B2", "#D55E00", "#CC79A7") # Set manually
# tech_palette <- brewer.pal(n=length(tech_rename),name="Set1") # Use a predefined a palette https://www.datanovia.com/en/blog/top-r-color-palettes-to-know-for-great-data-visualization/
#tech_palette <- colorRampPalette(brewer.pal(8, "Set1"))(length(tech_rename)) # Use a predefined a palette https://www.datanovia.com/en/blog/easy-way-to-expand-color-palettes-in-r/


# cbPalette <- 
# cbPalette <- c("#E69F00", "#000000",  "#009E73", "#0072B2", "#D55E00", "#CC79A7", "#56B4E9", "#F0E442") # Selected colors

# Column width guidelines https://www.elsevier.com/authors/author-schemas/artwork-and-media-instructions/artwork-sizing
# Single column: 90mm = 3.54 in
# 1.5 column: 140 mm = 5.51 in
# 2 column: 190 mm = 7.48 in

# ======================== #
# begin code
# ======================== #
dir_work = dirname(rstudioapi::getSourceEditorContext()$path)
setwd(dir_work)
setwd('../databases')

# connect to database
con <- dbConnect(SQLite(),db)
setwd('../analyze_inputs')

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

# Set color palette
options(ggplot2.discrete.fill = tech_palette)
options(ggplot2.discrete.color = tech_palette)
options(ggplot2.continuous.color = tech_palette)
options(ggplot2.continuous.color = tech_palette)

# -------------------------
# Power Plant Investment Costs
table = 'CostInvest'
savename = 'Inputs_PowerPlants_InvestmentCosts.pdf'
# -------------------------

# read-in data
tbl <- dbReadTable(con, table)

# process data
tbl <- tbl[tbl$tech %in% tech_list, ] # only plot tech in list
tbl <- transform(tbl, tech = tech_rename[as.character(tech)]) # rename tech
tbl$tech <- factor(tbl$tech,levels = tech_levels) # Plot series in specified order
names(tbl)[names(tbl) == "tech"] <- "Technologies" # rename column

# plot
ggplot(data=tbl, aes_string(x='vintage',y='cost_invest',color='Technologies',linetype='Technologies'))+
  geom_line()+
  scale_linetype_manual(values=line_styles,labels=parse_format())+
  scale_color_manual(values=tech_palette,labels=parse_format())+
  labs(x='Year (-)', y=expression(paste("CAPEX (US$ KW"^-1,")")))+
  theme(panel.background = element_rect(fill = NA, colour ="black"),
      panel.border = element_rect(linetype="solid", fill=NA),
      legend.background=element_rect(fill = alpha("white", 0)),
      legend.key = element_rect(colour = "transparent", fill = "white"))

# save
ggsave(savename, device="pdf", width=7.48, height=5.5, units="in",dpi=300)


# -------------------------
# Power Plant Variable Costs
table = 'CostVariable'
savename = 'Inputs_PowerPlants_VariableCosts.pdf'
conversion = 277.777778 # M$/PJ to $/kWh
# -------------------------

# read-in data
tbl <- dbReadTable(con, table)

# process data
tbl <- tbl[tbl$tech %in% tech_list, ]
tbl <- transform(tbl, tech = tech_rename[as.character(tech)])
tbl$cost_variable <- tbl$cost_variable * conversion
tbl$tech <- factor(tbl$tech,levels = tech_levels)
names(tbl)[names(tbl) == "tech"] <- "Technologies" # rename column

# plot
ggplot(data=tbl, aes_string(x='periods',y='cost_variable',color='Technologies',linetype='Technologies'))+
  geom_line()+
  scale_linetype_manual(values=line_styles,labels=parse_format())+
  scale_color_manual(values=tech_palette,labels=parse_format())+
  labs(x='Year (-)', y=expression(paste("Variable O&M (US$ kWh"^-1,")")))+
  theme(panel.background = element_rect(fill = NA, colour ="black"),
        panel.border = element_rect(linetype="solid", fill=NA),
        legend.background=element_rect(fill = alpha("white", 0)),
        legend.key = element_rect(colour = "transparent", fill = "white"))

# save
ggsave(savename, device="pdf", width=7.48, height=5.5, units="in",dpi=300)


# -------------------------
# Power Plant Fixed Costs
table = 'CostFixed'
savename = 'Inputs_PowerPlants_FixedCosts.pdf'
# -------------------------

# read-in data
tbl <- dbReadTable(con, table)

# process data
tbl <- tbl[tbl$tech %in% tech_list, ]
tbl <- transform(tbl, tech = tech_rename[as.character(tech)])
tbl$tech <- factor(tbl$tech,levels = tech_levels)
names(tbl)[names(tbl) == "tech"] <- "Technologies" # rename column

# plot
ggplot(data=tbl, aes_string(x='periods',y='cost_fixed',color='Technologies',linetype='Technologies'))+
  geom_line()+
  scale_linetype_manual(values=line_styles,labels=parse_format())+
  scale_color_manual(values=tech_palette,labels=parse_format())+
  labs(x='Year (-)', y=expression(paste("Fixed O&M (US$ KW"^-1,")")))+
  theme(panel.background = element_rect(fill = NA, colour ="black"),
        panel.border = element_rect(linetype="solid", fill=NA),
        legend.background=element_rect(fill = alpha("white", 0)),
        legend.key = element_rect(colour = "transparent", fill = "white"))
# save
ggsave(savename, device="pdf", width=7.48, height=5.5, units="in",dpi=300)

# -------------------------
# finish program and tidy up
# -------------------------
# disconnect from database
dbDisconnect(con)
# return to original directory
setwd(dir_work)