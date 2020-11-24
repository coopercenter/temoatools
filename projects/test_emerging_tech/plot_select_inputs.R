library(RSQLite)
library(ggplot2)
library(scales)
library(gridExtra)
library(grid)
library("ggpubr")

# inputs
db = 'all.sqlite' # database to analyze, assumed to be in results directory


# This is order that items will be plotted, only items included will be plotted
tech_rename <- c('E_BECCS'="'BECCS'",
                 'E_OCAES'="'OCAES'",
                 'E_PV_DIST_RES'="'Residential solar PV'",
                 'E_SCO2'="sCO[2]",
                 'EC_WIND'="'Offshore wind'")


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
setwd('databases')

# connect to database
con <- dbConnect(SQLite(),db)
setwd('../results')

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

# plot
plot_CostInvest <- ggplot(data=tbl, aes_string(x='vintage',y='cost_invest',color='tech'))+
  geom_line()+
  scale_colour_discrete(labels=parse_format())+
  labs(x='Year (-)', y=expression(paste("CAPEX (US$ KW"^-1,")")),
       col='Technologies')+
  theme(panel.background = element_rect(fill = NA, colour ="black"),
        panel.border = element_rect(linetype="solid", fill=NA),
        legend.background=element_rect(fill = alpha("white", 0)),
        legend.key = element_rect(colour = "transparent", fill = "white"))

# save
# ggsave(savename, device="pdf", width=7.48, height=5.5, units="in",dpi=300)


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

# plot
plot_CostVariable <- ggplot(data=tbl, aes_string(x='periods',y='cost_variable',color='tech'))+
  geom_line()+
  scale_colour_discrete(labels=parse_format())+
  labs(x='Year (-)', y=expression(paste("Variable O&M (US$ kWh"^-1,")")),
       col='Technologies')+
  theme(panel.background = element_rect(fill = NA, colour ="black"),
        panel.border = element_rect(linetype="solid", fill=NA),
        legend.background=element_rect(fill = alpha("white", 0)),
        legend.key = element_rect(colour = "transparent", fill = "white"))

# save
# ggsave(savename, device="pdf", width=7.48, height=5.5, units="in",dpi=300)


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

# plot
plot_CostFixed <- ggplot(data=tbl, aes_string(x='periods',y='cost_fixed',color='tech'))+
  geom_line()+
  scale_colour_discrete(labels=parse_format())+
  labs(x='Year (-)', y=expression(paste("Fixed O&M (US$ KW"^-1,")")),
       col='Technologies')+
  theme(panel.background = element_rect(fill = NA, colour ="black"),
        panel.border = element_rect(linetype="solid", fill=NA),
        legend.background=element_rect(fill = alpha("white", 0)),
        legend.key = element_rect(colour = "transparent", fill = "white"))

# save
# ggsave(savename, device="pdf", width=7.48, height=5.5, units="in",dpi=300)

# -------------------------
# Power Plant Efficiency
table = 'Efficiency'
savename = 'Inputs_PowerPlants_Efficiency.pdf'
conversion = 100.0
# -------------------------

# read-in data
tbl <- dbReadTable(con, table)

# process data
tbl <- tbl[tbl$tech %in% tech_list, ]
tbl <- transform(tbl, tech = tech_rename[as.character(tech)])
tbl$efficiency <- tbl$efficiency * conversion
tbl$tech <- factor(tbl$tech,levels = tech_levels)

# plot
plot_Efficiency <-ggplot(data=tbl, aes_string(x='vintage',y='efficiency',color='tech'))+
  geom_line()+
  scale_colour_discrete(labels=parse_format())+
  labs(x='Year (-)', y='Efficiency (%)',
       col='Technologies')+
  theme(panel.background = element_rect(fill = NA, colour ="black"),
        panel.border = element_rect(linetype="solid", fill=NA),
        legend.background=element_rect(fill = alpha("white", 0)),
        legend.key = element_rect(colour = "transparent", fill = "white"))

# save
# ggsave(savename, device="pdf", width=7.48, height=5.5, units="in",dpi=300)


# --------------------------
# combine technology inputs into single figure
# https://www.datanovia.com/en/lessons/combine-multiple-ggplots-into-a-figure/
# --------------------------
ggarrange(plot_CostInvest, plot_CostFixed, plot_CostVariable, plot_Efficiency, 
                  labels=c("a","b","c", "d"), ncol=2, nrow=2,
                  common.legend = TRUE, legend ="bottom")



# grid.newpage()
# grid.arrange( ggplotGrob(plot_CostInvest), ggplotGrob(plot_CostFixed), ggplotGrob(plot_CostVariable), 
#               ggplotGrob(plot_Efficiency), nrow=2, ncol=2)

# save
savename = 'Inputs_PowerPlants.png'
ggsave(savename, device="png", width=7.48, height=5.5, units="in",dpi=300)

# ggsave(savename, device="pdf",
#        width=7.4, height=6.0, units="in",dpi=1000,
#        plot = grid.arrange( ggplotGrob(plot_CostInvest), ggplotGrob(plot_CostFixed), ggplotGrob(plot_CostVariable), 
#                             ggplotGrob(plot_Efficiency), nrow=2, ncol=2))


# -------------------------
# Power Plant Capacity Factors
table = 'CapacityFactorTech'
savename = 'Inputs_PowerPlants_CapacityFactor.pdf'
# -------------------------

# read-in data
tbl <- dbReadTable(con, table)

# process data
tbl <- tbl[tbl$tech %in% tech_list, ]
tbl <- transform(tbl, tech = tech_rename[as.character(tech)])
tbl <- transform(tbl, season_name = season_rename[as.character(season_name)])
tbl <- transform(tbl, time_of_day_name = tod_rename[as.character(time_of_day_name)])
tbl$tech <- factor(tbl$tech,levels = tech_levels)  # Plot in specified order
tbl$season_name <- factor(tbl$season_name,levels = season_levels)

# plot
ggplot(data=tbl, aes_string(x='time_of_day_name',y='cf_tech',color='tech'))+
  geom_line()+
  facet_wrap('season_name')+
  scale_colour_discrete(labels=parse_format())+
  labs(x='Hour (-)', y='Capacity factor (-)',
       col='Technologies')+
  theme(axis.text.x = element_text(angle = 0,vjust=0., hjust = 0.5),
        panel.background = element_rect(fill = NA, colour ="black"),
        panel.border = element_rect(linetype="solid", fill=NA),
        legend.background=element_rect(fill = alpha("white", 0)),
        legend.key = element_rect(colour = "transparent", fill = "white"),
        strip.background = element_rect(colour = NA, fill = NA),
        panel.spacing = unit(1, "lines"))

# save
ggsave(savename, device="pdf", width=7.48, height=5.5, units="in",dpi=300)


# -------------------------
# Demand
table1 = 'Demand'
table2 = 'DemandSpecificDistribution'
savename = 'Inputs_Demand.pdf'
conversion = 277.777778 # M$/PJ to $/kWh
# -------------------------

# read-in data
tbl1 <- dbReadTable(con, table1)
tbl2 <- dbReadTable(con, table2)

# process data
tbl1$demand <- tbl1$demand * conversion
tbl2 <- transform(tbl2, season_name = season_rename[as.character(season_name)])
tbl2 <- transform(tbl2, time_of_day_name = tod_rename[as.character(time_of_day_name)])


# periods <- unique(tbl1$periods)
# tbl2$year <- periods[1]
# tbl3 <- tbl2
# tbl3$dds <- tbl3$dds * tb


for (i in 1:length(tbl1$periods)){
  print(i)
  print(tbl1$periods[i])
  print(tbl1$demand[i])
  tbl_x <- tbl2
  tbl_x$year <- toString(tbl1$periods[i])
  tbl_x$dds <- tbl_x$dds * tbl1$demand[i]
  if (i==1){
    tbl3 <- tbl_x
  }
  else {
    tbl3 <- rbind(tbl3, tbl_x)
  }
  
}

# plot order
tbl3$season_name <- factor(tbl3$season_name,levels = season_levels)

# Set color palette
demand_palette <- brewer.pal(n=length(tbl1$periods),name="Greys") # predefined palette # http://www.cookbook-r.com/Graphs/Colors_(ggplot2)/
options(ggplot2.discrete.fill = demand_palette)
options(ggplot2.discrete.color = demand_palette)
options(ggplot2.continuous.color = demand_palette)
options(ggplot2.continuous.color = demand_palette)

# plot
ggplot(data=tbl3, aes_string(x='time_of_day_name',y='dds',color='year'))+
  geom_line() +
  labs(x='Hour (-)', y='Demand (GWh)',
       col='Year')+
  facet_wrap('season_name')+
  theme(axis.text.x = element_text(angle = 0,vjust=0., hjust = 0.5),
        panel.background = element_rect(fill = NA, colour ="black"),
        panel.border = element_rect(linetype="solid", fill=NA),
        legend.background=element_rect(fill = alpha("white", 0)),
        legend.key = element_rect(colour = "transparent", fill = "white"),
        strip.background = element_rect(colour = NA, fill = NA),
        panel.spacing = unit(1, "lines"))

# save
ggsave(savename, device="pdf", width=7.48, height=5.5, units="in",dpi=300)


# -------------------------
# Combine Demand and Capacity Factor TOD
savename = 'Inputs_Demand_CapacityFactor.png'
# -------------------------

custom_palette <- c('#000000', tech_palette)

# Set color palette
options(ggplot2.discrete.fill = custom_palette)
options(ggplot2.discrete.color = custom_palette)
options(ggplot2.continuous.color = custom_palette)
options(ggplot2.continuous.color = custom_palette)

# Normalize demand
tbl2$dds <- tbl2$dds / max(tbl2$dds)
# Rename demand columns to match capacity factor table
tbl2 <- tbl2 %>% rename(tech=demand_name, cf_tech=dds)
# Rename entries in demand
demand_rename = c('ELC_DMD'='Demand')
tbl2 <- transform(tbl2, tech = demand_rename[as.character(tech)])
# Remove note columns
tbl = subset(tbl, select = -c(cf_tech_notes) )
tbl2 = subset(tbl2, select = -c(dds_notes) )
# Combine dataframes
tbl_comb <- rbind(tbl2,tbl)


# set order for plotting
levels <- c("Demand", tech_levels)
tbl_comb$tech <- factor(tbl_comb$tech,levels = levels)
tbl_comb$season_name <- factor(tbl_comb$season_name,levels = season_levels)



# Set color palette - add black for Demand
newPalette <- c('#000000',tech_palette)
options(ggplot2.discrete.fill = newPalette)
options(ggplot2.discrete.color = newPalette)
options(ggplot2.continuous.color = newPalette)
options(ggplot2.continuous.color = newPalette)

# plot
ggplot(data=tbl_comb, aes_string(x='time_of_day_name',y='cf_tech',color='tech'))+
  geom_line()+
  facet_wrap('season_name')+
  scale_colour_discrete(labels=parse_format())+
  labs(x='Hour (-)', y='Normalized demand and capacity factor (-)',
       col='Technologies')+
  theme(axis.text.x = element_text(angle = 0,vjust=0., hjust = 0.5),
        panel.background = element_rect(fill = NA, colour ="black"),
        panel.border = element_rect(linetype="solid", fill=NA),
        legend.background=element_rect(fill = alpha("white", 0)),
        legend.key = element_rect(colour = "transparent", fill = "white"),
        strip.background = element_rect(colour = NA, fill = NA),
        panel.spacing = unit(1, "lines"))

# save
ggsave(savename, device="png", width=7.48, height=5.5, units="in",dpi=300)



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

# plot
ggplot(data=tbl, aes_string(x='periods',y='cost_variable',color='tech'))+
  geom_line()+
  scale_colour_discrete(labels=parse_format())+
  labs(x='Year (-)', y=expression(paste("Fuel cost (US$ MJ"^-1,")")),
       col='Fuel')+
  theme(panel.background = element_rect(fill = NA, colour ="black"),
        panel.border = element_rect(linetype="solid", fill=NA),
        legend.background=element_rect(fill = alpha("white", 0)),
        legend.key = element_rect(colour = "transparent", fill = "white"))

# save
ggsave(savename, device="png", width=3.54, height=3.54, units="in",dpi=300)

# -------------------------
# finish program and tidy up
# -------------------------
# https://cran.r-project.org/web/packages/egg/vignettes/Ecosystem.html






# -------------------------
# finish program and tidy up
# -------------------------
# disconnect from database
dbDisconnect(con)
# return to original directory
setwd(dir_work)