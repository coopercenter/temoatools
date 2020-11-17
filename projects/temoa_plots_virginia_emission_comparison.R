library(here)
library(plotly)
library(tidyverse)
library(dplyr)
library(reshape2)
source(here::here("viz_functions.R"))
virginia_emissions <- read.csv(here::here("virginia/results/emissions_yearly.csv"))
virginia_emissions <- melt(virginia_emissions)
virginia_emissions <- virginia_emissions[c(5:18),]

virginia_emissions <- data.frame(lapply(virginia_emissions, gsub, pattern = "X", replacement = ""))
virginia_emissions <- data.frame(lapply(virginia_emissions, gsub, pattern = ".sqlite", replacement = ""))
virginia_emissions <- data.frame(lapply(virginia_emissions, gsub, pattern = "A", replacement = "No Constraints"))
virginia_emissions <- data.frame(lapply(virginia_emissions, gsub, pattern = "B", replacement = "VCEA"))
virginia_emissions$variable <- as.numeric(as.character(virginia_emissions$variable))
virginia_emissions$value <- as.double(as.character(virginia_emissions$value))
virginia_emissions$database <- as.character(virginia_emissions$fuelOrTech)

virginia_emissions %>%
  ggplot(aes(x = variable, y = value, group = database, color = database)) + 
  ylim(0,60000) +
  geom_line() + 
  geom_point() +
  theme_ceps() +
  ggtitle("Emissions ") +
  xlab("Year") +
  ylab("Emissions (kton)") +
  theme(legend.title = element_blank())

ggsave(here::here("virginia_emissions.png"), width = 16, height = 8, units = "cm")
 
