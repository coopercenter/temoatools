library(dplyr)
library(RSQLite)
library(ggplot2)
library(scales)
library(gridExtra)
library(grid)
library("ggpubr")
library(hash)
library(RColorBrewer)
library(tidyr)
library(lubridate)
library(reshape2)
library(ggh4x)

# ======================== #
# begin code
# ======================== #
dir_work = dirname(rstudioapi::getSourceEditorContext()$path)
setwd(dir_work)
setwd('../monte_carlo')

# load results
df <- read.csv("capacity_by_year.csv", check.names=FALSE)
setwd(dir_work)

#---------
# new_emerg - rename and factor
#---------
rename <- c("wEmerg"='With LDS/NET',
            "woEmerg"='Without LDS/NET')
df <- transform(df, new_emerg = rename[as.character(new_emerg)])

# treat baselines differently
df[ which(df$new_emerg=='With LDS/NET' & df$iteration=='baseline'),'new_emerg'] <- 'With LDS/NET (Baseline)'

levels <- c('Without LDS/NET', 'With LDS/NET (Baseline)', 'With LDS/NET')
df$new_emerg <- factor(df$new_emerg, levels = levels) 

#---------
# new_fossil - rename and factor
#---------
rename <- c("wFossil"='With New Fossil',
            "woFossil"='Without New Fossil')
df <- transform(df, new_fossil = rename[as.character(new_fossil)])
levels <- c('Without New Fossil', 'With New Fossil')
df$new_fossil <- factor(df$new_fossil, levels = levels)

#---------
# bio - rename and factor
#---------
rename <- c("Low Bio"='Low Bio',
            "High Bio"='High Bio')
df <- transform(df, bio = rename[as.character(bio)])
levels <- c('Low Bio', 'High Bio')
df$bio <- factor(df$bio, levels = levels)

dodge <- 0.2

# Set color palette
# predefined palette # http://www.cookbook-r.com/Graphs/Colors_(ggplot2)/
# The palette with black:
# pathway_Palette <- c("#E69F00", "#56B4E9", "#009E73","#0072B2", "#D55E00", "#000000", "#CC79A7")
# pathway_Palette <- c( "#E69F00", "#56B4E9", "#009E73", "#D55E00", "#CC79A7", "#0072B2","#D55E00", "#CC79A7", "#0072B2")
# options(ggplot2.discrete.fill = pathway_Palette)
# options(ggplot2.discrete.color = pathway_Palette)
# options(ggplot2.continuous.color = pathway_Palette)
# options(ggplot2.continuous.color = pathway_Palette)

#---------
# Group technologies
#---------
batt <- "Batteries - 2 & 4 hour"
bio <- "Biomass"
coal_petrol <- "Coal and Petroleum"
nuc_hyd <- "Nuclear and Hydro"
solar <- "Solar - Utility & Residential"
wind <- "Offshore Wind - Fixed & Floating"
NET <- "Negative Emission Tech"
NG <- "Natural Gas - with & without CCS"
LDS <- "Long duration storage"

drop <- "drop"

rename <- c("EX_BIO"=drop,
            "EX_COAL"=drop,
            "EX_HYDRO"=drop,
            "EX_NG_CC1"=NG,
            "EX_NG_CC2"=NG,
            "EX_NG_CT1"=NG,
            "EX_NG_CT2"=NG,
            "EX_NUCLEAR"=drop,
            "EX_OIL"=drop,
            "EX_PUMP"=drop,
            'EX_SOLPV'=solar,
            "EC_BATT_2hr"=batt,
            "EC_BATT_4hr"=batt,
            "EC_BIO"=drop,
            "EC_COAL"=drop,
            "EC_COAL_CCS"=drop,
            "EC_COAL_IGCC"=drop,
            "EC_NG_CC"=NG,
            "EC_NG_CT"=NG,
            "EC_NG_CCS"=NG,
            "EC_NUCLEAR"=drop,
            "EC_OIL_CC"=drop,
            "EC_PUMP"=drop,
            "EC_SOLPV_Util"=solar,
            "EC_WIND_Fix"=wind,
            'EC_WIND_Float'=wind,
            "ED_SOLPV_Com"=solar,
            "ED_SOLPV_Res"=solar,
            "EC_BECCS"=drop,
            "EC_DAC"=drop,
            "EC_OCAES"=drop,
            "EC_VFB"=drop)

# rename technologies
df$original_name <-df$tech_or_fuel
df_renamed <- transform(df, tech_or_fuel = rename[as.character(tech_or_fuel)])

# 'drop' technologies that we don't want to plot
df_renamed <- df_renamed[ which(df_renamed$tech_or_fuel !='drop'),]

# summarize to sum capacity of the same category within each simulation
df_renamed2 <- df_renamed %>% # the names of the new data frame and the data frame to be summarised
  group_by(.dots=c("iteration","year","tech_or_fuel","new_emerg", "new_fossil", "bio")) %>%   # the grouping variable
  summarise(value = sum(value))

# summarize
cap <- df_renamed2 %>% # the names of the new data frame and the data frame to be summarised
  group_by(.dots=c("year","tech_or_fuel","new_emerg", "new_fossil", "bio")) %>%   # the grouping variable
  summarise(mean = mean(value),  # calculates the mean
            min = min(value), # calculates the minimum
            max = max(value),# calculates the maximum
            sd=sd(value)) # calculates the standard deviation


palette <-c("#009E73", "#E69F00", "#0072B2", "#000000")

options(ggplot2.discrete.fill = palette)
options(ggplot2.discrete.color = palette)
options(ggplot2.continuous.fill = palette)
options(ggplot2.continuous.color = palette)


# -------------------------
# Capacity build-out
# -------------------------

# cap_lowbio<-cap[(cap$bio=="Low Bio"),]
cap_lowbio$Scenario <- paste(cap_lowbio$new_emerg,' - ', cap_lowbio$new_fossil)

cap$Scenario <- paste(cap$new_emerg,' - ', cap$new_fossil)

plot_cap <- ggplot(data=cap, aes_string(x='year',y='mean', ymin='min', ymax='max', color='Scenario', fill='Scenario'))+
  geom_line(position=position_dodge(width=dodge))+
  geom_ribbon(alpha=0.2, position=position_dodge(width=dodge))+
  geom_point(position=position_dodge(width=dodge))+
  scale_y_continuous(limits = c(0, 100))+
  facet_nested_wrap(~tech_or_fuel+bio, ncol=4)+
  labs(x='Year', y=expression(paste("Capacity (GW)")))+
  theme(panel.background = element_rect(colour ="black"),
        panel.border = element_rect(linetype="solid", fill=NA),
        legend.background=element_rect(fill = alpha("white", 0)),
        legend.key = element_rect(colour = "transparent"), legend.title=element_blank(),
        axis.text.x = element_text(angle = 90,vjust=0.5),
        legend.position = "bottom")+ guides(col = guide_legend(nrow = 2, byrow = TRUE))
  

# savename = 'Fig6_2050_capacity_select.png'
# ggsave(savename, device="png", width=7.48, height=6.0, units="in",dpi=300)

# ======================== #
# begin code for costs and emissions
# ======================== #
dir_work = dirname(rstudioapi::getSourceEditorContext()$path)
setwd(dir_work)
setwd('../monte_carlo')

# load results
df <- read.csv("costs_emissions_by_year.csv", check.names=FALSE)
setwd(dir_work)

#---------
# new_emerg - rename and factor
#---------
rename <- c("wEmerg"='With LDS/NET',
            "woEmerg"='Without LDS/NET')
df <- transform(df, new_emerg = rename[as.character(new_emerg)])

# treat baselines differently
df[ which(df$new_emerg=='With LDS/NET' & df$iteration=='baseline'),'new_emerg'] <- 'With LDS/NET (Baseline)'

levels <- c('Without LDS/NET', 'With LDS/NET (Baseline)', 'With LDS/NET')
df$new_emerg <- factor(df$new_emerg, levels = levels) 

#---------
# new_fossil - rename and factor
#---------
rename <- c("wFossil"='With New Fossil',
            "woFossil"='Without New Fossil')
df <- transform(df, new_fossil = rename[as.character(new_fossil)])
levels <- c('Without New Fossil', 'With New Fossil')
df$new_fossil <- factor(df$new_fossil, levels = levels)


#---------
# bio - rename and factor
#---------
rename <- c("Low Bio"='Low Bio',
            "High Bio"='High Bio')
df <- transform(df, bio = rename[as.character(bio)])
levels <- c('Low Bio', 'High Bio')
df$bio <- factor(df$bio, levels = levels)

# -------------------------
# Costs
# -------------------------

# select costs
costs <- df[ which(df$quantity%in% c('costs_by_year')),]

# convert from cents/kWh to dollars/kWh
costs$value <- costs$value / 100.0

# summarize to create line plots
costs_smry <- costs %>% # the names of the new data frame and the data frame to be summarised
  group_by(.dots=c("year","new_emerg", "new_fossil", "bio")) %>%   # the grouping variable
  summarise(mean = mean(value),  # calculates the mean
            min = min(value), # calculates the minimum
            max = max(value),# calculates the maximum
            sd=sd(value)) # calculates the standard deviation

# Scenario
costs_smry$Scenario <- paste(costs_smry$new_emerg,' - ', costs_smry$new_fossil)

# -------------------------
# Costs
# -------------------------
plot_costs <- ggplot(data=costs_smry, aes_string(x='year',y='mean', ymin='min', ymax='max', color='Scenario', fill='Scenario'))+
  geom_line(position=position_dodge(width=dodge))+
  geom_ribbon(alpha=0.2, position=position_dodge(width=dodge))+
  geom_point(position=position_dodge(width=dodge))+
  labs(x='Year', y=expression(paste("Costs (US$ KWh"^-1,")")))+
  scale_y_continuous(limits = c(0, 0.12))+
  facet_nested(~bio)+
  theme(panel.background = element_rect(colour ="black"),
        panel.border = element_rect(linetype="solid", fill=NA),
        legend.background=element_rect(fill = alpha("white", 0)),
        legend.key = element_rect(colour = "transparent"), legend.title=element_blank(),
        legend.position = "bottom",
        axis.text.x = element_text(angle = 90,vjust=0.5))
# savename = 'Backup_Fig_yearly_costs.png'
# ggsave(savename, device="png", width=7.48, height=4.5, units="in",dpi=300)

# -------------------------
# Emissions
# -------------------------

# select emissions
emi <- df[ which(df$quantity%in% c('emissions_by_year')),]

# Convert kt to Mt
emi$value <- emi$value / 1000.0

# summarize to create line plots
emi_smry <- emi %>% # the names of the new data frame and the data frame to be summarised
  group_by(.dots=c("year","new_emerg", "new_fossil", "bio")) %>%   # the grouping variable
  summarise(mean = mean(value),  # calculates the mean
            min = min(value), # calculates the minimum
            max = max(value),# calculates the maximum
            sd=sd(value)) # calculates the standard deviation

# Scenario
emi_smry$Scenario <- paste(emi_smry$new_emerg,' - ', emi_smry$new_fossil)

# plot
plot_emi <- ggplot(data=emi_smry, aes_string(x='year',y='mean', ymin='min', ymax='max', color='Scenario', fill='Scenario'))+
  geom_line(position=position_dodge(width=dodge))+
  geom_ribbon(alpha=0.2, position=position_dodge(width=dodge))+
  geom_point(position=position_dodge(width=dodge))+
  labs(x='Year', y=expression(paste("Emissions (Mt CO"[2],")")))+
  facet_nested(~bio)+
  theme(panel.background = element_rect(colour ="black"),
        panel.border = element_rect(linetype="solid", fill=NA),
        legend.background=element_rect(fill = alpha("white", 0)),
        legend.key = element_rect(colour = "transparent"), legend.title=element_blank(),
        legend.position = "bottom",
        axis.text.x = element_text(angle = 90,vjust=0.5))


# -------------------------
# Plot and save
# -------------------------

# ggarrange(plot_costs, ggarrange(plot_costs, plot_cap, ncol=2, labels = c("B","C"), common.legend = FALSE, legend="bottom"),
#           nrow=2, ncol=1, heights = c(1,1),  
#           labels= "A", label.x = 0.0, label.y = 1.0, common.legend = TRUE, legend="bottom")

ggarrange(ggarrange(plot_costs, plot_emi, ncol=2, labels = c("A","B"), common.legend = TRUE, legend="none"),
          plot_cap, nrow=2, ncol=1, heights = c(1.2,2),  
          labels= c("","C"), label.x = 0.0, label.y = 1.0, common.legend = TRUE, legend="bottom")

savename = 'Fig5_yearly_costs_emissions_cap.png'
ggsave(savename, device="png", width=7.48, height=7.48, units="in",dpi=300)