library(RSQLite)
library(RColorBrewer)
library(ggplot2)
library(scales)
library(gridExtra)
library(grid)
library("ggpubr")
library(dplyr)

# inputs
csv = 'MonteCarloResults_all.csv' # database to analyze, assumed to be in monte_carlo directory


# This is order that items will be plotted, only items included will be plotted
tech_rename <- c('E_BECCS'="'BECCS'",
                 'E_OCAES'="'OCAES'",
                 'E_PV_DIST_RES'="'Residential solar PV'",
                 'E_SCO2'="sCO[2]")


# tech_palette  <- c("#E69F00", "#000000", "#56B4E9", "#009E73", "#F0E442", "#0072B2", "#D55E00", "#CC79A7") # Set manually
tech_palette <- brewer.pal(n=length(tech_rename),name="Set1") # Use a predefined a palette https://www.datanovia.com/en/blog/top-r-color-palettes-to-know-for-great-data-visualization/
# display.brewer.pal(n=length(tech_rename),name="Set1")

fuel_rename <- c('IMPBIOMASS'="'Biomass'",
                 'IMPNATGAS'="'Natural gas'")
# fuel_palette  <- c("#000000", "#000000", "#56B4E9", "#009E73", "#F0E442", "#0072B2", "#D55E00", "#CC79A7") # Set manually
fuel_palette <- brewer.pal(n=length(fuel_rename),name="Set1") # predefined palette # http://www.cookbook-r.com/Graphs/Colors_(ggplot2)/

season_rename <- c('fall'='Fall',
  'winter'='Winter',
  'winter2'='Winter 2',
  'spring'='Spring',
  'summer'='Summer',
  'summer2'='Summer 2')

tod_rename <- c('hr01'=1,
                'hr02'=2,
                'hr03'=3,
                'hr04'=4,
                'hr05'=5,
                'hr06'=6,
                'hr07'=7,
                'hr08'=8,
                'hr09'=9,
                'hr10'=10,
                'hr11'=11,
                'hr12'=12,
                'hr13'=13,
                'hr14'=14,
                'hr15'=15,
                'hr16'=16,
                'hr17'=17,
                'hr18'=18,
                'hr19'=19,
                'hr20'=20,
                'hr21'=21,
                'hr22'=22,
                'hr23'=23,
                'hr24'=24)


cbPalette <- 
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
setwd('monte_carlo')

# load data
df <- read.csv(csv)

# convert values to double
as.double(df$value)

# Set color palette
options(ggplot2.discrete.fill = tech_palette)
options(ggplot2.discrete.color = tech_palette)
options(ggplot2.continuous.color = tech_palette)
options(ggplot2.continuous.color = tech_palette)


# -------------------------
# process tech_rename, fuel_rename, and tod_rename
# split each into a list of technologies (i.e. tech_list) and names to be used (i.e. tech_levels)
# -------------------------
temp <- as.list(tech_rename)
tech_list <- c()
tech_levels <- c()
for (i in 1:length(tech_rename)) {
  tech_list <- c(tech_list, names(temp[i]))
  tech_levels <- c(tech_levels, temp[[i]])
}

temp <- as.list(fuel_rename)
fuel_list <- c()
fuel_levels <- c()
for (i in 1:length(fuel_rename)) {
  fuel_list <- c(fuel_list, names(temp[i]))
  fuel_levels <- c(fuel_levels, temp[[i]])
}

temp <- as.list(season_rename)
season_list <- c()
season_levels <- c()
for (i in 1:length(season_rename)) {
  season_list <- c(season_list, names(temp[i]))
  season_levels <- c(season_levels, temp[[i]])
}

# -------------------------
# Costs by year
quantity = 'costs_by_year'
savename = 'Results_costs_by_year.pdf'
# -------------------------

# select data 
dfx <- df[df$quantity %in% quantity, ]

# process data
dfx$value <- as.double(dfx$value)
dfx$database <- factor(dfx$database)

# plot
plot_costs <- 
  ggplot(data=dfx, aes_string(x='year',y='value',color='database'))+
  geom_line() + geom_point() +
  scale_colour_discrete(labels=parse_format())+
  labs(x='Year (-)', y=expression(paste("Costs (US$ KWh"^-1,"y"^-1,")")),
       col='Technologies')+
  theme(panel.background = element_rect(fill = NA, colour ="black"),
        panel.border = element_rect(linetype="solid", fill=NA),
        legend.background=element_rect(fill = alpha("white", 0)),
        legend.key = element_rect(colour = "transparent", fill = "white"))

# save
# ggsave(savename, device="pdf", width=7.48, height=5.5, units="in",dpi=300)

# -------------------------
# Emissions by year
quantity = 'emissions_by_year'
conversion = 1e-3 # Mton to Gton
savename = 'Results_emissions_by_year.pdf'
# -------------------------
# select data 
dfx <- df[df$quantity %in% quantity, ]

# process data
dfx$value <- as.double(dfx$value)
dfx$value <- dfx$value * conversion
dfx$database <- factor(dfx$database)


# plot
plot_emissions <-ggplot(data=dfx, aes_string(x='year',y='value',color='database'))+
  geom_line() + geom_point() +
  scale_colour_discrete(labels=parse_format())+
  labs(x='Year (-)', y=expression(paste("Emissions (Gton CO"[2],"y"^-1,")")),
       col='Technologies')+
  theme(panel.background = element_rect(fill = NA, colour ="black"),
        panel.border = element_rect(linetype="solid", fill=NA),
        legend.background=element_rect(fill = alpha("white", 0)),
        legend.key = element_rect(colour = "transparent", fill = "white"))

# save
# ggsave(savename, device="pdf", width=7.48, height=5.5, units="in",dpi=300)

# --------------------------
# combine costs and emissions into single figure
# https://www.datanovia.com/en/lessons/combine-multiple-ggplots-into-a-figure/
# --------------------------
ggarrange(plot_costs, plot_emissions, 
          labels=c("a","b"), ncol=2, nrow=1,
          common.legend = TRUE, legend ="bottom")


# grid.newpage()
# grid.arrange( ggplotGrob(plot_CostInvest), ggplotGrob(plot_CostFixed), ggplotGrob(plot_CostVariable), 
#               ggplotGrob(plot_Efficiency), nrow=2, ncol=2)

# save
savename = 'results_costs_and_emissions.png'
ggsave(savename, device="png", width=7.48, height=5.5, units="in",dpi=300)

# ggsave(savename, device="pdf",
#        width=7.4, height=6.0, units="in",dpi=1000,
#        plot = grid.arrange( ggplotGrob(plot_CostInvest), ggplotGrob(plot_CostFixed), ggplotGrob(plot_CostVariable), 
#                             ggplotGrob(plot_Efficiency), nrow=2, ncol=2))

# -------------------------
# Capacity by year
quantity = 'capacity_by_year'
savename = 'Results_capacity_by_year.png'
# -------------------------

# select data 
dfx <- df[df$quantity %in% quantity, ]
dfx <- dfx[dfx$tech_or_fuel %in% tech_list, ]

# process data
dfx$value <- as.double(dfx$value)
dfx$database <- factor(dfx$database)
dfx <- transform(dfx, tech_or_fuel = tech_rename[as.character(tech_or_fuel)])

dodge = 0.2
ggplot(dfx,aes_string(x='year', y='value', fill='database', group='database', color='database'))+
  facet_wrap(~tech_or_fuel, labeller = label_parsed)+
  geom_line(size=1,position=position_dodge(width=dodge))+
  geom_point(position=position_dodge(width=dodge))+
  labs(x='Year', y=expression(paste("Capacity (GW y"^-1,")")))+
  theme(legend.position="bottom", legend.title = element_blank(),axis.text.x = element_text(angle = 90,vjust=0.5), 
        panel.background = element_rect(fill = NA, colour ="black"),
        panel.border = element_rect(linetype="solid", fill=NA),
        strip.background = element_rect(colour = NA, fill = NA))

# save
ggsave(savename, device="png", width=7.48, height=5.5, units="in",dpi=300)

# -------------------------
# Activity by year
quantity = 'activity_by_year'
savename = 'Results_activity_by_year.png'
# -------------------------
# select data 
dfx <- df[df$quantity %in% quantity, ]
dfx <- dfx[dfx$tech_or_fuel %in% tech_list, ]

# process data
dfx$value <- as.double(dfx$value)
dfx$database <- factor(dfx$database)
dfx <- transform(dfx, tech_or_fuel = tech_rename[as.character(tech_or_fuel)])

dodge = 0.2
ggplot(dfx,aes_string(x='year', y='value', fill='database', group='database', color='database'))+
  facet_wrap(~tech_or_fuel, labeller = label_parsed)+
  geom_line(size=1,position=position_dodge(width=dodge))+
  geom_point(position=position_dodge(width=dodge))+
  labs(x='Year', y=expression(paste("Activity (TWh y"^-1,")")))+
  theme(legend.position="bottom", legend.title = element_blank(),axis.text.x = element_text(angle = 90,vjust=0.5), 
        panel.background = element_rect(fill = NA, colour ="black"),
        panel.border = element_rect(linetype="solid", fill=NA),
        strip.background = element_rect(colour = NA, fill = NA))

# save
ggsave(savename, device="png", width=7.48, height=5.5, units="in",dpi=300)


# -------------------------
# Activity by time of day
quantity = 'activity_by_tod'
savename = 'Results_emissions_by_year.pdf'
# -------------------------



# -------------------------
# finish program and tidy up
# -------------------------
# https://cran.r-project.org/web/packages/egg/vignettes/Ecosystem.html






# -------------------------
# finish program and tidy up
# -------------------------

# return to original directory
setwd(dir_work)