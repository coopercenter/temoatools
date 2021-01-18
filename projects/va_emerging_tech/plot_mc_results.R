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
setwd('monte_carlo')

# load data
df <- read.csv(csv)



# -------------------------
# Costs
# -------------------------
# select data
costs<-df[(df$quantity=="costs_by_year"),]
# factor year
costs$year <- factor(costs$year)

ggplot(costs ,aes(x=year,y=value, fill=database))+
  geom_boxplot(outlier.size = 0.2) +
  labs(x='', y=expression(paste("Cost of electricity (US$ kWh"^-1,")")))

# + facet_wrap(~ database)



# save
ggsave('mc_costs_by_year.png', device="png", width=7.48, height=5.5, units="in",dpi=300)

# -------------------------
# Emissions
# -------------------------
emissions<-df[(df$quantity=="emissions_by_year"),]
# factor year
emissions$year <- factor(emissions$year)


ggplot(emissions ,aes(x=year,y=value, fill=database))+
  geom_boxplot(outlier.size = 0.2) +
  labs(x='', y=expression(paste("Emissions (Mton CO"[2],")")))

# save
ggsave('mc_emissions_by_year.png', device="png", width=7.48, height=5.5, units="in",dpi=300)

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
# Activity TOD V1
# -------------------------
activityTOD<-df[(df$quantity=="activity_by_tod"),]
activityTOD<-activityTOD[(activityTOD$year==2050),]
activityTOD<-activityTOD[(activityTOD$database=="All"),]
activityTOD<-activityTOD[(activityTOD$season=="summer")|(activityTOD$season=="winter2"),]
# rename
activityTOD <- transform(activityTOD, tech_or_fuel = rename[as.character(tech_or_fuel)])

# factor 
activityTOD$tod <- factor(activityTOD$tod)

ggplot(activityTOD,aes(x=tod, y=value))+
  facet_grid(season~tech_or_fuel, labeller = label_parsed)+
  geom_line(size=1,position=position_dodge(width=dodge))



# save
ggsave('mc_activity_by_year.png', device="png", width=7.48, height=5.5, units="in",dpi=300)


# -------------------------
# Activity TOD V2
# -------------------------
activityTOD<-df[(df$quantity=="activity_by_tod"),]
activityTOD<-activityTOD[(activityTOD$year==2050),]
activityTOD<-activityTOD[(activityTOD$database=="All"),]
activityTOD<-activityTOD[(activityTOD$season=="summer")|(activityTOD$season=="winter2"),]
# rename
activityTOD <- transform(activityTOD, tech_or_fuel = rename[as.character(tech_or_fuel)])

# factor 
activityTOD$tod <- factor(activityTOD$tod)


activityTOD_smry <- activityTOD %>% # the names of the new data frame and the data frame to be summarised
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
ggsave('mc_activity_by_year.png', device="png", width=7.48, height=5.5, units="in",dpi=300)

# -------------------------
# finish program and tidy up
# -------------------------

# return to original directory
setwd(dir_work)