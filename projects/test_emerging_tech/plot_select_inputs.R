library(RSQLite)
library(ggplot2)
library(scales)
library(gridExtra)
library(grid)
library("ggpubr")

# inputs
db = 'all.sqlite' # database to analyze, assumed to be in results directory


tech_list = c('E_SCO2','E_PV_DIST_RES','E_OCAES', 'E_BECCS')
tech_rename <- c('E_SCO2'="sCO[2]",
                 'E_PV_DIST_RES'="'Residential solar PV'",
                 'E_OCAES'="'OCAES'",
                 'E_BECCS'="'BECCS'")

fuel_list = c('IMPBIOMASS','IMPNATGAS')
fuel_rename <- c('IMPBIOMASS'="'Biomass'",
                 'IMPNATGAS'="'Natural gas'")

season_rename <- c(
  'winter'='Winter',
  'winter2'='Winter 2',
  'spring'='Spring',
  'summer'='Summer',
  'summer2'='Summer 2',
  'fall'='Fall')

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

# The palette with black: http://www.cookbook-r.com/Graphs/Colors_(ggplot2)/
# cbPalette <- c("#E69F00", "#000000", "#56B4E9", "#009E73", "#F0E442", "#0072B2", "#D55E00", "#CC79A7") # Full palette
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
options(ggplot2.discrete.fill = cbPalette)
options(ggplot2.discrete.color = cbPalette)
options(ggplot2.continuous.color = cbPalette)
options(ggplot2.continuous.color = cbPalette)
# -------------------------
# Power Plant Investment Costs
table = 'CostInvest'
savename = 'Inputs_PowerPlants_InvestmentCosts.pdf'
# -------------------------

# read-in data
tbl <- dbReadTable(con, table)

# process data
tbl <- tbl[tbl$tech %in% tech_list, ]
tbl <- transform(tbl, tech = tech_rename[as.character(tech)])

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

# plot
plot_CostVariable <- ggplot(data=tbl, aes_string(x='periods',y='cost_variable',color='tech'))+
  geom_line()+
  scale_colour_discrete(labels=parse_format())+
  labs(x='Year (-)', y=expression(paste("Variable cost (US$ kWh"^-1,")")),
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

# plot
plot_CostFixed <- ggplot(data=tbl, aes_string(x='periods',y='cost_fixed',color='tech'))+
  geom_line()+
  scale_colour_discrete(labels=parse_format())+
  labs(x='Year (-)', y=expression(paste("Fixed costs (US$ KW"^-1,")")),
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
savename = 'Inputs_PowerPlants.pdf'
ggsave(savename, device="pdf", width=7.48, height=5.5, units="in",dpi=300)

# ggsave(savename, device="pdf",
#        width=7.4, height=6.0, units="in",dpi=1000,
#        plot = grid.arrange( ggplotGrob(plot_CostInvest), ggplotGrob(plot_CostFixed), ggplotGrob(plot_CostVariable), 
#                             ggplotGrob(plot_Efficiency), nrow=2, ncol=2))

# -------------------------
# Fuel Costs
table = 'CostVariable'
savename = 'Inputs_Fuels_VariableCosts.png'
# -------------------------

# read-in data
tbl <- dbReadTable(con, table)

# process data
tbl <- tbl[tbl$tech %in% fuel_list, ]
tbl <- transform(tbl, tech = fuel_rename[as.character(tech)])

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

# plot
ggplot(data=tbl, aes_string(x='time_of_day_name',y='cf_tech',color='tech'))+
  geom_line()+
  facet_wrap('season_name')+
  scale_colour_discrete(labels=parse_format())+
  labs(x='Hour (-)', y='Capacity factor (-)',
       col='Technologies')+
  theme(panel.background = element_rect(fill = NA, colour ="black"),
        panel.border = element_rect(linetype="solid", fill=NA),
        legend.background=element_rect(fill = alpha("white", 0)),
        legend.key = element_rect(colour = "transparent", fill = "white"),
        strip.background = element_rect(colour = NA, fill = NA))

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

# plot
ggplot(data=tbl3, aes_string(x='time_of_day_name',y='dds',color='year'))+
  geom_line() +
  labs(x='Hour (-)', y='Demand (GWh)',
       col='Year')+
  facet_wrap('season_name')+
  theme(panel.background = element_rect(fill = NA, colour ="black"),
        panel.border = element_rect(linetype="solid", fill=NA),
        legend.background=element_rect(fill = alpha("white", 0)),
        legend.key = element_rect(colour = "transparent", fill = "white"))

# save
ggsave(savename, device="pdf", width=7.48, height=5.5, units="in",dpi=300)


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