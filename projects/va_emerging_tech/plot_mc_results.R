library(RSQLite)
library(RColorBrewer)
library(ggplot2)
library(scales)
library(gridExtra)
library(grid)
library("ggpubr")
library(dplyr)

# inputs
csv = 'combined_results.csv' # database to analyze, assumed to be in monte_carlo directory

# Change subplot order - Case
levels <- c("None",
            "All",
            "BECCS",
            "OCAES",
            "Rooftop Solar",
            "sCO2")
# df1$Case <- factor(df1$Case, levels = levels)


# http://www.cookbook-r.com/Graphs/Colors_(ggplot2)/
# cbPalette <- c("#E69F00", "#000000",  "#009E73", "#0072B2", "#D55E00", "#CC79A7", "#56B4E9", "#F0E442") # Selected colors
cbPalette <- c( "#999999","#000000",  "#009E73", "#0072B2","#E69F00", "#D55E00", "#CC79A7", "#56B4E9", "#F0E442") # Selected colors

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

# Set color palette
options(ggplot2.discrete.fill = cbPalette)
options(ggplot2.discrete.color = cbPalette)
options(ggplot2.continuous.color = cbPalette)
options(ggplot2.continuous.color = cbPalette)

# -------------------------
# Costs
# -------------------------
# select data
costs<-df[(df$quantity=="costs_by_year"),]
# factor year
costs$year <- factor(costs$year)
# set plot order
costs$database <- factor(costs$database, levels = levels)

# ---
# V1
# ---
ggplot(costs ,aes(x=year,y=value, fill=database))+
  geom_boxplot(outlier.size = 0.2) +
  labs(x='', y=expression(paste("Cost of electricity (US$ kWh"^-1,")")))

# + facet_wrap(~ database)

# save
ggsave('mc_costs_by_year_v1.png', device="png", width=7.48, height=5.5, units="in",dpi=300)

# ---
# V2
# ---
ggplot(costs ,aes(x=year,y=value, fill=database))+
  geom_boxplot(outlier.size = 0.2) +
  labs(x='', y=expression(paste("Cost of electricity (US$ kWh"^-1,")")))+ 
  facet_wrap(~ database)

# save
ggsave('mc_costs_by_year_v2.png', device="png", width=7.48, height=5.5, units="in",dpi=300)

# ---
# Summarize
# ---
cost_smry <- costs %>% # the names of the new data frame and the data frame to be summarised
  group_by(.dots=c("year", "database")) %>%   # the grouping variable
  summarise(min = min(value),
            mean = mean(value),
            max = max(value))

cost_sum <- cost_smry %>% # the names of the new data frame and the data frame to be summarised
  group_by(.dots=c("database")) %>%   # the grouping variable
  summarise(min = sum(min),
            mean = sum(mean),
            max = sum(max)) 

interest <- 0.02
costs_npv <- c()
years <- unique(costs$year)
start_year <- 2018
for (i in 1:length(levels)){
  npv <- 0.0
  for (j in 1:length(years)){
    R <- cost_smry[cost_smry$database == levels[i] & cost_smry$year == years[j] ,'mean']
    t <- as.numeric(as.character(years[j])) -start_year
    npv <- npv + R / (1+interest)**t
  }
  costs_npv <- c(costs_npv, npv)
}
# -------------------------
# Emissions
# -------------------------
emissions<-df[(df$quantity=="emissions_by_year"),]
# factor year
emissions$year <- factor(emissions$year)
# set plot order
emissions$database <- factor(emissions$database, levels = levels)

# ---
# V1
# ---
ggplot(emissions ,aes(x=year,y=value, fill=database))+
  geom_boxplot(outlier.size = 0.2) +
  labs(x='', y=expression(paste("Emissions (Mton CO"[2],")")))

# save
ggsave('mc_emissions_by_year_v1.png', device="png", width=7.48, height=5.5, units="in",dpi=300)

# ---
# V2
# ---
ggplot(emissions ,aes(x=year,y=value, fill=database))+
  geom_boxplot(outlier.size = 0.2) +
  labs(x='', y=expression(paste("Emissions (Mton CO"[2],")")))+ 
  facet_wrap(~ database)

# save
ggsave('mc_emissions_by_year_v2.png', device="png", width=7.48, height=5.5, units="in",dpi=300)


# ---
# Summarize
# ---
emissions_smry <- emissions %>% # the names of the new data frame and the data frame to be summarised
  group_by(.dots=c("year", "database")) %>%   # the grouping variable
  summarise(mean = mean(value))  # calculates the mean

emissions_total <- emissions_smry %>% # the names of the new data frame and the data frame to be summarised
  group_by(.dots=c("database")) %>%   # the grouping variable
  summarise(sum = sum(mean))  # calculates the mean


# -------------------------
# Combined costs and emissions
# -------------------------

plt_cost <- ggplot(costs ,aes(x=year,y=value, fill=database))+
  geom_boxplot(outlier.size = 0.2) +
  labs(x='', y=expression(paste("Costs (US$ kWh"^-1,")")))+ 
  facet_grid(~ database)+
  theme(legend.position="none", legend.title = element_blank(),
        axis.text.x=element_blank()) 

plt_emi <- ggplot(emissions ,aes(x=year,y=value, fill=database))+
  geom_boxplot(outlier.size = 0.2) +
  labs(x='', y=expression(paste("Emissions (Mton CO"[2],")")))+ 
  facet_grid(~ database) +
  theme(legend.position="none", legend.title = element_blank(),
        axis.text.x = element_text(angle = 90,vjust=0.5), 
        strip.text = element_blank())

ggarrange(plt_cost, plt_emi, nrow=2, ncol=1, heights = c(1.0,1.0), align="v")

# save
ggsave('mc_costs_and_emissions_by_year.png', device="png", width=8.48, height=5.5, units="in",dpi=300)

# -------------------------
# Capacity
# -------------------------
capacity<-df[(df$quantity=="capacity_by_year"),]
# factor year
capacity$year <- factor(capacity$year)

# Rename Technology
rename <- c("EC_BATT"="'Batteries'",
            "ED_BATT"="'Batteries'",
            "EX_HYDRO"="'Nuclear and hydro'",
            "EX_NUCLEAR"="'Nuclear and hydro'",
            "EX_COAL"="'Coal and petroleum'",
            "EC_COAL"="'Coal and petroleum'",
            "EX_OIL"="'Coal and petroleum'",
            "EC_OIL_CC"="'Coal and petroleum'",
            "EX_NG_CC"="'Natural gas'",
            "EX_NG_CT"="'Natural gas'",
            "EC_NG_CC"="'Natural gas'",
            "EC_NG_OC"="'Natural gas'",
            "EC_PUMP"="'Pumped hydro'",
            "EX_PUMP"="'Pumped hydro'",
            "EX_BIO"="'Biomass'",
            "EC_BIO"="'Biomass'",
            "E_BECCS"="'BECCS'",
            'EX_SOLPV'="'Solar'",
            "EC_SOLPV"="'Solar'",
            "ED_SOLPV"="'Solar'",
            "E_PV_DIST_RES"="'Residential solar'",
            'EX_WIND'="'Wind'",
            'EC_WIND'="'Wind'",
            "EF_WIND"="'Wind'",
            "E_OCAES"="'OCAES'",
            "E_SCO2"="'sCO2'")

capacity <- transform(capacity, tech_or_fuel = rename[as.character(tech_or_fuel)])


# Summarise to create line plots
capacity_smry <- capacity %>% # the names of the new data frame and the data frame to be summarised
  group_by(.dots=c("tech_or_fuel", "year", "database")) %>%   # the grouping variable
  summarise(mean = mean(value),  # calculates the mean
            min = min(value), # calculates the minimum
            max = max(value),# calculates the maximum
            sd=sd(value)) # calculates the standard deviation
dodge = 0.2
ggplot(capacity_smry,aes(x=year, y=mean, ymin=min, ymax=max, fill=database, group=database, color=database))+
  facet_wrap(~tech_or_fuel, labeller = label_parsed)+
  geom_line(size=1,position=position_dodge(width=dodge))+
  geom_ribbon(alpha=0.2, colour = NA,position=position_dodge(width=dodge))+
  geom_point(position=position_dodge(width=dodge))+
  labs(x='Year', y=expression(paste("Capacity (GW)")))+
  theme(legend.position="bottom", legend.title = element_blank(),
        axis.text.x = element_text(angle = 90,vjust=0.5)) 


# save
ggsave('mc_capacity_by_year.png', device="png", width=7.48, height=5.5, units="in",dpi=300)

# -------------------------
# Activity
# -------------------------
activity<-df[(df$quantity=="activity_by_year"),]
# factor year
activity$year <- factor(activity$year)
# rename
activity <- transform(activity, tech_or_fuel = rename[as.character(tech_or_fuel)])

# Summarise to create line plots
activity_smry <- activity %>% # the names of the new data frame and the data frame to be summarised
  group_by(.dots=c("tech_or_fuel", "year", "database")) %>%   # the grouping variable
  summarise(mean = mean(value),  # calculates the mean
            min = min(value), # calculates the minimum
            max = max(value),# calculates the maximum
            sd=sd(value)) # calculates the standard deviation
dodge = 0.2
ggplot(activity_smry,aes(x=year, y=mean, ymin=min, ymax=max, fill=database, group=database, color=database))+
  facet_wrap(~tech_or_fuel, labeller = label_parsed)+
  geom_line(size=1,position=position_dodge(width=dodge))+
  geom_ribbon(alpha=0.2, colour = NA,position=position_dodge(width=dodge))+
  geom_point(position=position_dodge(width=dodge))+
  labs(x='Year', y=expression(paste("Activity (TWh y"^-1,")")))+
  theme(legend.position="bottom", legend.title = element_blank(),
        axis.text.x = element_text(angle = 90,vjust=0.5)) 

# save
ggsave('mc_activity_by_year.png', device="png", width=7.48, height=5.5, units="in",dpi=300)

# -------------------------
# Process demand data
# -------------------------
# inputs
db = 'all.sqlite' # database to analyze, assumed to be in results directory

season_rename <- c('fall'="'Fall'",
                   'winter'="'Winter - Sunny days'",
                   'winter2'="'Winter - Cloudy days'",
                   'spring'="'Spring'",
                   'summer'="'Summer - Sunny days'",
                   'summer2'="'Summer - Cloudy days'")

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

# connect to database
setwd('../databases')
con <- dbConnect(SQLite(),db)

# return to main directory
setwd(dir_work)
setwd('monte_carlo')

table1 = 'Demand'
table2 = 'DemandSpecificDistribution'
savename = 'Inputs_Demand.pdf'
conversion = 277.777778 # M$/PJ to $/kWh

# read-in data
tbl1 <- dbReadTable(con, table1)
tbl2 <- dbReadTable(con, table2)

# disconnect from database
dbDisconnect(con)

# process data
tbl1$demand <- tbl1$demand * conversion
tbl2 <- transform(tbl2, season_name = season_rename[as.character(season_name)])
tbl2 <- transform(tbl2, time_of_day_name = tod_rename[as.character(time_of_day_name)])


# -------------------------
# Process Activity TOD data
# -------------------------
year <- 2050
activityTOD<-df[(df$quantity=="activity_by_tod"),]
activityTOD<-activityTOD[(activityTOD$year==year),]
activityTOD <- transform(activityTOD, season = season_rename[as.character(season)])
activityTOD <- transform(activityTOD, tod = tod_rename[as.character(tod)])

# Normalize activity by season peak demand
yearly_demand <- tbl1[tbl1$periods == year,'demand']
for (i in 1:length(season_rename)){
  peak_demand <- max(tbl2[tbl2$season_name == season_rename[i],'dds']) * yearly_demand
  activityTOD[activityTOD$season == season_rename[i],'value'] <- activityTOD[activityTOD$season == season_rename[i],'value'] / peak_demand
}

# factor tod
activityTOD$tod <- factor(activityTOD$tod)

# rename tech_or_fuel
activityTOD <- transform(activityTOD, tech_or_fuel = rename[as.character(tech_or_fuel)])

# select subset of databases
activityTOD_all <- activityTOD[(activityTOD$scenario=='all'),]



# -------------------------
# Activity TOD V1
# -------------------------
ggplot(activityTOD_all,aes(x=tod, y=value))+
  facet_grid(season~tech_or_fuel, labeller = label_parsed)+
  geom_line(size=1,position=position_dodge(width=dodge))


# save
ggsave('mc_activity_by_tod_v1.png', device="png", width=7.48, height=5.5, units="in",dpi=300)


# -------------------------
# Activity TOD V2
# -------------------------
activityTOD_smry <- activityTOD_all %>% # the names of the new data frame and the data frame to be summarised
  group_by(.dots=c("tech_or_fuel", "tod", "season")) %>%   # the grouping variable
  summarise(mean = mean(value),  # calculates the mean
            min = min(value), # calculates the minimum
            max = max(value),# calculates the maximum
            sd=sd(value)) # calculates the standard deviation
# factor 
activityTOD_smry$tod <- factor(activityTOD_smry$tod)

dodge = 0.2
ggplot(activityTOD_smry,aes(x=tod, y=mean, ymin=min, ymax=max, fill=season, group=season, color=season))+
  facet_grid(season~tech_or_fuel, labeller = label_parsed)+
  geom_line(size=1,position=position_dodge(width=dodge))+
  geom_ribbon(alpha=0.2, colour = NA,position=position_dodge(width=dodge))+
  geom_point(position=position_dodge(width=dodge))+
  labs(x='Year', y=expression(paste("Activity (TWh y"^-1,")")))+
  theme(legend.position="bottom", legend.title = element_blank(),
        axis.text.x = element_text(angle = 90,vjust=0.5)) 

# save
ggsave('mc_activity_by_tod_v2.png', device="png", width=7.48, height=5.5, units="in",dpi=300)

# -------------------------
# Activity TOD V3
# -------------------------
activityTOD_smry <- activityTOD %>% # the names of the new data frame and the data frame to be summarised
  group_by(.dots=c("tech_or_fuel", "tod", "season", "database")) %>%   # the grouping variable
  summarise(mean = mean(value),  # calculates the mean
            min = min(value), # calculates the minimum
            max = max(value),# calculates the maximum
            sd=sd(value)) # calculates the standard deviation
# factor 
activityTOD_smry$tod <- factor(activityTOD_smry$tod)

dodge = 0.2
ggplot(activityTOD_smry,aes(x=tod, y=mean, ymin=min, ymax=max, fill=database, group=database, color=database))+
  facet_grid(season~tech_or_fuel, labeller = label_parsed)+
  geom_line(size=1,position=position_dodge(width=dodge))+
  geom_ribbon(alpha=0.2, colour = NA,position=position_dodge(width=dodge))+
  geom_point(position=position_dodge(width=dodge))+
  labs(x='Year', y=expression(paste("Activity (TWh y"^-1,")")))+
  theme(legend.position="bottom", legend.title = element_blank(),
        axis.text.x = element_text(angle = 90,vjust=0.5)) 

# save
ggsave('mc_activity_by_tod_v3.png', device="png", width=7.48, height=5.5, units="in",dpi=300)

# -------------------------
# finish program and tidy up
# -------------------------

# return to original directory
setwd(dir_work)