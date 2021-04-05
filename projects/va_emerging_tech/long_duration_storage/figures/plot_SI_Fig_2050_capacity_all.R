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
rename <- c("Baseline"='Baseline',
            "wNETSwLDS"='With NETS With LDS',
            "wLDS"='With LDS',
            "wNETS" = 'With NETS')
df <- transform(df, scenario = rename[as.character(scenario)])

# treat baselines differently
#df[ which(df$new_emerg=='With Emerging Tech' & df$iteration=='baseline'),'new_emerg'] <- 'With Emerging Tech (Baseline)'

#levels <- c('Without Emerging Tech', 'With Emerging Tech (Baseline)', 'With Emerging Tech')
#df$new_emerg <- factor(df$new_emerg, levels = levels) 

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
pathway_Palette <- c("#E69F00", "#56B4E9", "#009E73","#0072B2", "#D55E00", "#000000", "#CC79A7")
options(ggplot2.discrete.fill = pathway_Palette)
options(ggplot2.discrete.color = pathway_Palette)
options(ggplot2.continuous.color = pathway_Palette)
options(ggplot2.continuous.color = pathway_Palette)

#---------
# Group technologies
#---------
batt <- "Batteries"
bio <- "Biomass"
coal_petrol <- "Coal and Petroleum"
nuc_hyd <- "Nuclear and Hydro"
solar <- "Solar"
wind <- "Wind"
NET <- "Negative Emission Tech"
NG <- "Natural Gas"
LDS <- "Long duration storage"

rename <- c("EX_BIO"="Biomass",
            "EX_COAL"="Coal & Petrol",
            "EX_HYDRO"="Nuclear + Hydro",
            "EX_NG_CC1"="Natural Gas",
            "EX_NG_CC2"="Natural Gas",
            "EX_NG_CT1"="Natural Gas",
            "EX_NG_CT2"="Natural Gas",
            "EX_NUCLEAR"="Nuclear + Hydro",
            "EX_OIL"="Coal & Petrol",
            "EX_PUMP"="Pump",
            'EX_SOLPV'="Solar - Utility",
            "EC_BATT_2hr"="2-hr Battery",
            "EC_BATT_4hr"="4-hr Battery",
            "EC_BIO"="Biomass",
            "EC_COAL"="Coal & Petrol",
            "EC_COAL_CCS"="Coal & Petrol - CCS",
            "EC_COAL_IGCC"="Coal & Petrol",
            "EC_NG_CC"="Natural Gas",
            "EC_NG_CT"="Natural Gas",
            "EC_NG_CCS"="Natural Gas - CCS",
            "EC_NUCLEAR"="Nuclear + Hydro",
            "EC_OIL_CC"="Coal & Petrol",
            "EC_PUMP"="Pump",
            "EC_SOLPV_Util"="Solar - Utility",
            "EC_WIND_Fix"="Offshore Wind - Fixed",
            'EC_WIND_Float'="Offshore Wind - Floating",
            "ED_SOLPV_Com"="Solar - Commercial",
            "ED_SOLPV_Res"="Solar - Residential",
            "EC_BECCS"="BECCS",
            "EC_DAC"="DAC",
            "EC_OCAES"="OCAES",
            "EC_VFB"="VFB")

# rename technologies
df$original_name <-df$tech_or_fuel
df_renamed <- transform(df, tech_or_fuel = rename[as.character(tech_or_fuel)])

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


palette <-c('#6baed6', '#3182bd',
              '#31a354',  '#006d2c')

options(ggplot2.discrete.fill = palette)
options(ggplot2.discrete.color = palette)
options(ggplot2.continuous.fill = palette)
options(ggplot2.continuous.color = palette)


# -------------------------
# Capacity build-out - low bio
# -------------------------

cap_lowbio<-cap[(cap$bio=="Low Bio"),]
cap_lowbio$Scenario <- paste(cap_lowbio$new_emerg,' - ', cap_lowbio$new_fossil)

ggplot(data=cap_lowbio, aes_string(x='year',y='mean', ymin='min', ymax='max', color='Scenario', fill='Scenario'))+
  geom_line(position=position_dodge(width=dodge))+
  geom_ribbon(alpha=0.2, position=position_dodge(width=dodge))+
  geom_point(position=position_dodge(width=dodge))+
  scale_y_continuous(limits = c(0, 100))+
  facet_wrap(~tech_or_fuel)+
  labs(x='Year', y=expression(paste("Capacity (GW)")))+
  theme(panel.background = element_rect(colour ="black"),
        panel.border = element_rect(linetype="solid", fill=NA),
        legend.background=element_rect(fill = alpha("white", 0)),
        legend.key = element_rect(colour = "transparent"), legend.title=element_blank(),
        axis.text.x = element_text(angle = 90,vjust=0.5),
        legend.position = "bottom")+ guides(col = guide_legend(nrow = 2, byrow = TRUE))
  

savename = 'SI_Fig_2050_capacity_all_lowBio.png'
ggsave(savename, device="png", width=7.48, height=6.0, units="in",dpi=300)

# -------------------------
# Capacity build-out - High bio
# -------------------------

cap_highbio<-cap[(cap$bio=="High Bio"),]
cap_highbio$Scenario <- paste(cap_highbio$new_emerg,' - ', cap_highbio$new_fossil)

ggplot(data=cap_highbio, aes_string(x='year',y='mean', ymin='min', ymax='max', color='Scenario', fill='Scenario'))+
  geom_line(position=position_dodge(width=dodge))+
  geom_ribbon(alpha=0.2, position=position_dodge(width=dodge))+
  geom_point(position=position_dodge(width=dodge))+
  scale_y_continuous(limits = c(0, 100))+
  facet_wrap(~tech_or_fuel)+
  labs(x='Year', y=expression(paste("Capacity (GW)")))+
  theme(panel.background = element_rect(colour ="black"),
        panel.border = element_rect(linetype="solid", fill=NA),
        legend.background=element_rect(fill = alpha("white", 0)),
        legend.key = element_rect(colour = "transparent"), legend.title=element_blank(),
        axis.text.x = element_text(angle = 90,vjust=0.5),
        legend.position = "bottom")+ guides(col = guide_legend(nrow = 2, byrow = TRUE))

savename = 'SI_Fig_2050_capacity_all_highBio.png'
ggsave(savename, device="png", width=7.48, height=6.0, units="in",dpi=300)