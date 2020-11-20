library(RSQLite)
library(ggplot2)
library(scales)


# inputs
db = 'all.sqlite' # database to analyze, assumed to be in results directory
tables = c('CostInvest', 'CostVariable', 'CostFixed') # list of SQLite tables to plot

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

# -------------------------
# Power Plant Investment Costs
table = 'CostInvest'
savename = 'Inputs_PowerPlants_InvestmentCosts.pdf'

tech_list = c('E_SCO2','E_PV_DIST_RES','E_OCAES', 'E_BIO','E_BECCS')
rename <- c('E_SCO2'="sCO[2]",
            'E_PV_DIST_RES'="'Residential solar PV'",
            'E_OCAES'="'OCAES'",
            'E_BIO'="'Bioenergy'",
            'E_BECCS'="'BECCS'")
# -------------------------

# read-in data
tbl <- dbReadTable(con, table)

# process data
tbl <- tbl[tbl$tech %in% tech_list, ]
tbl <- transform(tbl, tech = rename[as.character(tech)])

# plot
ggplot(data=tbl, aes_string(x='vintage',y='cost_invest',color='tech'))+
  geom_line()+
  scale_colour_discrete(labels=parse_format())+
  labs(x='Year (-)', y=expression(paste("CAPEX (US$ KW"^-1,")")),
       col='Technologies')+
  theme(panel.background = element_rect(fill = NA, colour ="black"),
        panel.border = element_rect(linetype="solid", fill=NA),
        legend.background=element_rect(fill = alpha("white", 0)),
        legend.key = element_rect(colour = "transparent", fill = "white"))

# save
ggsave(savename, device="pdf", width=7.48, height=5.5, units="in",dpi=300)


# -------------------------
# Power Plant Variable Costs
table = 'CostVariable'
savename = 'Inputs_PowerPlants_VariableCosts.pdf'

tech_list = c('E_SCO2','E_PV_DIST_RES','E_OCAES', 'E_BIO','E_BECCS')
rename <- c('E_SCO2'="sCO[2]",
            'E_PV_DIST_RES'="'Residential solar PV'",
            'E_OCAES'="'OCAES'",
            'E_BIO'="'Bioenergy'",
            'E_BECCS'="'BECCS'")
conversion = 277.777778 # M$/PJ to $/kWh
# -------------------------

# read-in data
tbl <- dbReadTable(con, table)

# process data
tbl <- tbl[tbl$tech %in% tech_list, ]
tbl <- transform(tbl, tech = rename[as.character(tech)])
tbl$cost_variable <- tbl$cost_variable * conversion

# plot
ggplot(data=tbl, aes_string(x='periods',y='cost_variable',color='tech'))+
  geom_line()+
  scale_colour_discrete(labels=parse_format())+
  labs(x='Year (-)', y=expression(paste("Variable cost (US$ kWh"^-1,")")),
       col='Technologies')+
  theme(panel.background = element_rect(fill = NA, colour ="black"),
        panel.border = element_rect(linetype="solid", fill=NA),
        legend.background=element_rect(fill = alpha("white", 0)),
        legend.key = element_rect(colour = "transparent", fill = "white"))

# save
ggsave(savename, device="pdf", width=7.48, height=5.5, units="in",dpi=300)


# -------------------------
# Power Plant Fixed Costs
table = 'CostFixed'
savename = 'Inputs_PowerPlants_FixedCosts.pdf'

tech_list = c('E_SCO2','E_PV_DIST_RES','E_OCAES', 'E_BIO','E_BECCS')
rename <- c('E_SCO2'="sCO[2]",
            'E_PV_DIST_RES'="'Residential solar PV'",
            'E_OCAES'="'OCAES'",
            'E_BIO'="'Bioenergy'",
            'E_BECCS'="'BECCS'")
# -------------------------

# read-in data
tbl <- dbReadTable(con, table)

# process data
tbl <- tbl[tbl$tech %in% tech_list, ]
tbl <- transform(tbl, tech = rename[as.character(tech)])

# plot
ggplot(data=tbl, aes_string(x='periods',y='cost_fixed',color='tech'))+
  geom_line()+
  scale_colour_discrete(labels=parse_format())+
  labs(x='Year (-)', y=expression(paste("Fixed costs (US$ KW"^-1,")")),
       col='Technologies')+
  theme(panel.background = element_rect(fill = NA, colour ="black"),
        panel.border = element_rect(linetype="solid", fill=NA),
        legend.background=element_rect(fill = alpha("white", 0)),
        legend.key = element_rect(colour = "transparent", fill = "white"))

# save
ggsave(savename, device="pdf", width=7.48, height=5.5, units="in",dpi=300)


# -------------------------
# Fuel Costs
table = 'CostVariable'
savename = 'Inputs_Fuels_VariableCosts.pdf'

tech_list = c('IMPBIOMASS','IMPNATGAS')
rename <- c('IMPBIOMASS'="'Biomass'",
            'IMPNATGAS'="'Natural gas'")
# -------------------------

# read-in data
tbl <- dbReadTable(con, table)

# process data
tbl <- tbl[tbl$tech %in% tech_list, ]
tbl <- transform(tbl, tech = rename[as.character(tech)])

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
ggsave(savename, device="pdf", width=7.48, height=5.5, units="in",dpi=300)


grid.newpage()
grid.draw(rbind(ggplotGrob(plot1), ggplotGrob(plot2), size = "first"))


# -------------------------
# finish program and tidy up
# -------------------------
# disconnect from database
dbDisconnect(con)
# return to original directory
setwd(dir_work)