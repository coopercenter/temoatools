library(here)
library(plotly)
library(tidyverse)
library(dplyr)
library(reshape2)
source(here::here("viz_functions.R"))
virginia_capacity_by_fuel <- read.csv(here::here("virginia/results/capacity_by_fuel.csv"))
virginia_capacity_by_fuel_all_technology <- virginia_capacity_by_fuel[c(1,2,3,4,5,6,7,8,9,10,11,12),]
virginia_capacity_by_fuel_VCEA <- virginia_capacity_by_fuel[c(13,14,15,16,17,18,19,20,21,22,23,24),]
virginia_capacity_by_fuel_VCEA <- melt(virginia_capacity_by_fuel_VCEA, id.vars = c("fuelOrTech")) 
virginia_capacity_by_fuel_VCEA <- virginia_capacity_by_fuel_VCEA[(49:176),]
virginia_capacity_by_fuel_VCEA <- data.frame(lapply(virginia_capacity_by_fuel_VCEA,gsub, pattern = "_TAXED", replacement = ""))
virginia_capacity_by_fuel_VCEA <- data.frame(lapply(virginia_capacity_by_fuel_VCEA,gsub, pattern = "X", replacement = ""))

virginia_capacity_by_fuel_VCEA$variable <- as.numeric(as.character(virginia_capacity_by_fuel_VCEA$variable))
virginia_capacity_by_fuel_VCEA$value <- as.double(as.character(virginia_capacity_by_fuel_VCEA$value))
virginia_capacity_by_fuel_VCEA$fuelOrTech <- as.character(virginia_capacity_by_fuel_VCEA$fuelOrTech)

virginia_capacity_by_fuel_VCEA %>%
  ggplot(aes(x = variable, y = value, fill = fuelOrTech)) + 
  ylim(0,160) +
  geom_area() +
  theme_ceps() +
  scale_fill_manual(name=NULL,values=ceps_pal[1:12]) +
  ggtitle("Capacity by Fuel (VCEA)") +
  xlab("Year") +
  ylab("Capacity (GW)")

ggsave(here::here("virginia_capacity_by_fuel_VCEA.png"), width = 16, height = 8, units = "cm")
 
