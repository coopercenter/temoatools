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
df <- read.csv("costs_emissions_by_year.csv", check.names=FALSE)
setwd(dir_work)

#---------
# new_emerg - rename and factor
#---------
rename <- c("wEmerg"='With Emerging Tech',
            "woEmerg"='Without Emerging Tech')
df <- transform(df, new_emerg = rename[as.character(new_emerg)])

# treat baselines differently
df[ which(df$new_emerg=='With Emerging Tech' & df$iteration=='baseline'),'new_emerg'] <- 'With Emerging Tech (Baseline)'

levels <- c('Without Emerging Tech', 'With Emerging Tech (Baseline)', 'With Emerging Tech')
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
pathway_Palette <- c("#E69F00", "#0072B2", "#000000", "#CC79A7")
options(ggplot2.discrete.fill = pathway_Palette)
options(ggplot2.discrete.color = pathway_Palette)
options(ggplot2.continuous.color = pathway_Palette)
options(ggplot2.continuous.color = pathway_Palette)

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
# ---------------
# plot
# ---------------
plot_costs <- ggplot(data=costs_smry, aes_string(x='year',y='mean', ymin='min', ymax='max', color='new_emerg', fill='new_emerg'))+
  geom_line(position=position_dodge(width=dodge))+
  geom_ribbon(alpha=0.2, position=position_dodge(width=dodge))+
  geom_point(position=position_dodge(width=dodge))+
  labs(x='Year', y=expression(paste("Costs (US$ KWh"^-1,")")))+
  facet_nested(~bio + new_fossil)+
  theme(panel.background = element_rect(colour ="black"),
        panel.border = element_rect(linetype="solid", fill=NA),
        legend.background=element_rect(fill = alpha("white", 0)),
        legend.key = element_rect(colour = "transparent"), legend.title=element_blank())

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

# plot
plot_emi <- ggplot(data=emi_smry, aes_string(x='year',y='mean', ymin='min', ymax='max', color='new_emerg', fill='new_emerg'))+
  geom_line(position=position_dodge(width=dodge))+
  geom_ribbon(alpha=0.2, position=position_dodge(width=dodge))+
  geom_point(position=position_dodge(width=dodge))+
  labs(x='Year', y=expression(paste("Emissions (Mt CO"[2],")")))+
  facet_nested(~bio + new_fossil)+
  theme(panel.background = element_rect(colour ="black"),
        panel.border = element_rect(linetype="solid", fill=NA),
        legend.background=element_rect(fill = alpha("white", 0)),
        legend.key = element_rect(colour = "transparent"), legend.title=element_blank())
# -------------------------
# Plot and save
# -------------------------

ggarrange(plot_costs, plot_emi, nrow=2, ncol=1, heights = c(1,1), align="v", 
          labels= c("A", "B"), label.x = 0.0, label.y = 1.0, common.legend = TRUE, legend="bottom")
savename = 'Fig5_yearly_costs_emissions.png'
ggsave(savename, device="png", width=7.48, height=5.5, units="in",dpi=300)


# -------------------------
# Plot and save - costs alone
# -------------------------
ggplot(data=costs_smry, aes_string(x='year',y='mean', ymin='min', ymax='max', color='new_emerg', fill='new_emerg'))+
  geom_line(position=position_dodge(width=dodge))+
  geom_ribbon(alpha=0.2, position=position_dodge(width=dodge))+
  geom_point(position=position_dodge(width=dodge))+
  labs(x='Year', y=expression(paste("Costs (US$ KWh"^-1,")")))+
  scale_y_continuous(limits = c(0, 0.12))+
  facet_nested(~bio + new_fossil)+
  theme(panel.background = element_rect(colour ="black"),
        panel.border = element_rect(linetype="solid", fill=NA),
        legend.background=element_rect(fill = alpha("white", 0)),
        legend.key = element_rect(colour = "transparent"), legend.title=element_blank(), 
        legend.position = "bottom",
        axis.text.x = element_text(angle = 90,vjust=0.5))
savename = 'Fig5_yearly_costs.png'
ggsave(savename, device="png", width=7.48, height=4.5, units="in",dpi=300)