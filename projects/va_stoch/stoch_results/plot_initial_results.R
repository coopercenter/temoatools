library(dplyr)
library(RSQLite)
library(ggplot2)
library(scales)
library(gridExtra)
library(grid)
library("ggpubr")
library('hash')
library(RColorBrewer)

# inputs
db = 'B2030.sqlite' # database to analyze, assumed to be in results directory

# ======================== #
# begin code
# ======================== #
dir_work = dirname(rstudioapi::getSourceEditorContext()$path)
setwd(dir_work)

# connect to database
con <- dbConnect(SQLite(),db)
setwd(dir_work)


# -------------------------
# Costs
table = 'Output_Costs'
savename = 'Results_Costs.png'
# -------------------------

# read-in data
costs <- dbReadTable(con, table)

# Remove "solve" scenario (scenario run without stochastics)
# costs<-costs[!(costs$scenario=="solve"),]

# Analyze Discounted costs
costs_to_analyze <- c("V_DiscountedVariableCostsByProcess",
                      "V_DiscountedInvestmentByProcess",
                      "V_DiscountedFixedCostsByProcess")
costs <- costs[costs$output_name %in% costs_to_analyze, ]


# Summarize by scenario
groupings = c("scenario")
costs_smry <- costs %>% 
  group_by(.dots=groupings)%>%
  summarise(NPV = sum(output_cost))
write.csv(costs_smry, "cost_summary.csv")

# write.csv(df_smry_all, "cost_summary.csv")
# 
# 
# # plot
# ggplot(data=costs, aes_string(x='vintage',y='cost_invest',color='Technologies',linetype='Technologies'))+
#   geom_line()+
#   scale_linetype_manual(values=line_styles,labels=parse_format())+
#   scale_color_manual(values=tech_palette,labels=parse_format())+
#   labs(x='Year (-)', y=expression(paste("CAPEX (US$ KW"^-1,")")))+
#   theme(panel.background = element_rect(fill = NA, colour ="black"),
#       panel.border = element_rect(linetype="solid", fill=NA),
#       legend.background=element_rect(fill = alpha("white", 0)),
#       legend.key = element_rect(colour = "transparent", fill = "white"))
# 
# # save
# ggsave(savename, device="png", width=7.48, height=5.5, units="in",dpi=300)


# -------------------------
# Emissions
table = 'Output_Emissions'
savename = 'Results_Emissions.png'
conversion = 1000.0 # kton to Mton
# -------------------------

# read-in data
emi <- dbReadTable(con, table)

# Remove "solve" scenario (scenario run without stochastics)
# emi<-emi[!(emi$scenario=="solve"),]

# Convert


# Summarize by scenario
groupings = c("scenario", "t_periods")
emi_smry <- emi %>% 
  group_by(.dots=groupings)%>%
  summarise(emi = sum(emissions))

# plot
ggplot(data=emi_smry, aes_string(x='t_periods',y='emi', color='scenario'))+
  geom_line()+
  labs(x='Year (-)', y=expression(paste("Emissions (Mton CO2)")))+
  theme(panel.background = element_rect(fill = NA, colour ="black"),
        panel.border = element_rect(linetype="solid", fill=NA),
        legend.background=element_rect(fill = alpha("white", 0)),
        legend.key = element_rect(colour = "transparent", fill = "white"))

# save
ggsave(savename, device="png", width=7.48, height=5.5, units="in",dpi=300)

# -------------------------
# Capacity
table = 'Output_CapacityByPeriodAndTech'
savename = 'Results_Capacity.png'
# -------------------------

# read-in data
cap <- dbReadTable(con, table)

# Remove "solve" scenario (scenario run without stochastics)
cap<-cap[!(cap$scenario=="solve"),]

# Focus on electric sector
cap<-cap[(cap$sector=="electric"),]

# plot
ggplot(data=cap, aes_string(x='t_periods',y='capacity', color='scenario'))+
  facet_wrap('tech')+
  geom_line()+
  labs(x='Year (-)', y=expression(paste("Capacity (GW)")))+
  theme(panel.background = element_rect(fill = NA, colour ="black"),
        panel.border = element_rect(linetype="solid", fill=NA),
        legend.background=element_rect(fill = alpha("white", 0)),
        legend.key = element_rect(colour = "transparent", fill = "white"))

# save
ggsave(savename, device="png", width=7.48, height=5.5, units="in",dpi=300)


# -------------------------
# Activity
table = 'Output_VFlow_Out'
savename = 'Results_Activity.png'
# -------------------------

# read-in data
act <- dbReadTable(con, table)

# Remove "solve" scenario (scenario run without stochastics)
act<-act[!(act$scenario=="solve"),]

# Focus on electric sector
act<-act[(act$sector=="electric"),]

# Summarize by scenario
groupings = c("scenario", "tech", "t_periods")
act_smry <- act %>% 
  group_by(.dots=groupings)%>%
  summarise(act = sum(vflow_out))

# plot
ggplot(data=act_smry, aes_string(x='t_periods',y='act', color='scenario'))+
  facet_wrap('tech')+
  geom_line()+
  labs(x='Year (-)', y=expression(paste("Activity (PJ)")))+
  theme(panel.background = element_rect(fill = NA, colour ="black"),
        panel.border = element_rect(linetype="solid", fill=NA),
        legend.background=element_rect(fill = alpha("white", 0)),
        legend.key = element_rect(colour = "transparent", fill = "white"))

# save
ggsave(savename, device="png", width=7.48, height=5.5, units="in",dpi=300)

# -------------------------
# finish program and tidy up
# -------------------------
# disconnect from database
dbDisconnect(con)
# return to original directory
setwd(dir_work)