library(here)
library(plotly)
library(tidyverse)
library(dplyr)
library(reshape2)
source(here::here("viz_functions.R"))
virginia_costs <- read.csv(here::here("virginia/results/costs_yearly.csv"))
virginia_costs <- melt(virginia_costs)
virginia_costs <- virginia_costs[c(5:18),]

virginia_costs <- data.frame(lapply(virginia_costs, gsub, pattern = "X", replacement = ""))
virginia_costs <- data.frame(lapply(virginia_costs, gsub, pattern = ".sqlite", replacement = ""))
virginia_costs <- data.frame(lapply(virginia_costs, gsub, pattern = "A", replacement = "No Constraints"))
virginia_costs <- data.frame(lapply(virginia_costs, gsub, pattern = "B", replacement = "VCEA"))
virginia_costs$variable <- as.numeric(as.character(virginia_costs$variable))
virginia_costs$value <- as.double(as.character(virginia_costs$value))
virginia_costs$database <- as.character(virginia_costs$fuelOrTech)

virginia_costs %>%
  ggplot(aes(x = variable, y = value, group = database, color = database)) + 
  ylim(0,15) +
  geom_line() + 
  geom_point() +
  theme_ceps() +
  ggtitle("Costs ") +
  xlab("Year") +
  ylab("Costs (cents/kWh)") +
  theme(legend.title = element_blank())

ggsave(here::here("virginia_costs.png"), width = 16, height = 8, units = "cm")

