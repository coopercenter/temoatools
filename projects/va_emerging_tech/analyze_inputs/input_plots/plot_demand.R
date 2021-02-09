library(dplyr)
library(RSQLite)
library(ggplot2)
library(scales)
library(gridExtra)
library(grid)
library("ggpubr")
library(RColorBrewer)
library(hash)

# inputs
db = 'wEmerg_wFossil_combined_2050.sqlite' # database to analyze, assumed to be in results directory


# This is order that items will be plotted, only items included will be plotted
tech_rename <- c('EC_SOLPV'="'Solar PV - Utility'",
                 'ED_SOLPV'="'Solar PV - Commercial'",
                 'E_PV_DIST_RES'="'Solar PV - Residential'",
                 'EF_WIND'="'Offshore Wind - Floating'",
                 'EC_WIND'="'Offshore Wind - Fixed bottom'")

tech_rename <- c('EC_SOLPV'="'Solar PV'",
                 'EC_WIND'="'Offshore Wind'")

h <- hash()
h[['E_BECCS']] <- c('green', 'solid')
h[['EC_PUMP']] <- c('pink', 'solid')
h[['EC_COAL']] <- c('black', 'solid')
h[['E_BIO']] <- c('green', 'dashed')
h[['E_SCO2']] <- c('red', 'dotted')
h[['EF_WIND']] <- c('darkblue', 'solid')
h[['EC_WIND']] <- c('darkblue', 'solid')
h[['E_OCAES']] <- c('lightblue', 'solid')
h[['EC_NG_CC']] <- c('red', 'solid')
h[['EC_NG_OC']] <- c('red', 'dashed')
h[['E_PV_DIST_RES']] <- c('orange', 'dotted')
h[['ED_SOLPV']] <- c('orange', 'solid')
h[['EC_SOLPV']] <- c('orange', 'solid')
h[['EC_BATT']] <- c('gray', 'solid')

# http://www.cookbook-r.com/Graphs/Colors_(ggplot2)/
colors <- hash()
colors[['black']] <- "#000000"
colors[['gray']] <- "#999999"
colors[['orange']] <- "#E69F00"
colors[['lightblue']] <- "#56B4E9"
colors[['green']] <- "#009E73"
colors[['yellow']] <- "#F0E442"
colors[['darkblue']] <- "#0072B2"
colors[['red']] <- "#D55E00"
colors[['pink']] <- "#CC79A7"
colors[['brown']] <- "#993300"

season_rename <- c('fall'='Fall',
  'winter'='Winter - High renewables',
  'winter2'='Winter - Low renewables',
  'spring'='Spring',
  'summer'='Summer - High renewables',
  'summer2'='Summer - Low renewables')

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
setwd('../../databases')

# connect to database
con <- dbConnect(SQLite(),db)
setwd(dir_work)

# Set color palette
options(ggplot2.discrete.fill = tech_palette)
options(ggplot2.discrete.color = tech_palette)
options(ggplot2.continuous.color = tech_palette)
options(ggplot2.continuous.color = tech_palette)


# -------------------------
# process tech_rename, hash, and colors
# split each into a list of technologies (i.e. tech_list) and names to be used (i.e. tech_levels)
# -------------------------
temp <- as.list(tech_rename)
tech_list <- c()
tech_levels <- c()
tech_palette <- c()
line_styles <- c()
line_style_rename <- tech_rename
for (i in 1:length(tech_rename)) {
  name <-names(temp[i])
  tech_list <- c(tech_list, name)
  tech_levels <- c(tech_levels, temp[[i]])
  
  color_name <- h[[name]][1]
  line_style <- h[[name]][2]
  tech_palette <- c(tech_palette, colors[[color_name]])
  line_styles <- c(line_styles, line_style)
}

temp <- as.list(season_rename)
season_list <- c()
season_levels <- c()
for (i in 1:length(season_rename)) {
  season_list <- c(season_list, names(temp[i]))
  season_levels <- c(season_levels, temp[[i]])
}

# -------------------------
# Power Plant Capacity Factors
table = 'CapacityFactorTech'
savename = 'Inputs_PowerPlants_CapacityFactor.png'
# -------------------------

# read-in data
tbl <- dbReadTable(con, table)

# process data
tbl <- tbl[tbl$tech %in% tech_list, ]
tbl <- transform(tbl, tech = tech_rename[as.character(tech)])
tbl <- transform(tbl, season_name = season_rename[as.character(season_name)])
tbl <- transform(tbl, time_of_day_name = tod_rename[as.character(time_of_day_name)])
tbl$tech <- factor(tbl$tech,levels = tech_levels)  # Plot in specified order
tbl$season_name <- factor(tbl$season_name,levels = season_levels)
names(tbl)[names(tbl) == "tech"] <- "Technologies" # rename column

# plot
ggplot(data=tbl, aes_string(x='time_of_day_name',y='cf_tech',color='Technologies',linetype='Technologies'))+
  geom_line()+
  facet_wrap('season_name')+
  scale_linetype_manual(values=line_styles,labels=parse_format())+
  scale_color_manual(values=tech_palette,labels=parse_format())+
  scale_y_continuous(expand = c(0, 0), limits = c(0, NA)) + 
  labs(x='Hour (-)', y='Capacity factor (-)',
       col='Technologies')+
  theme(axis.text.x = element_text(angle = 0,vjust=0., hjust = 0.5),
        panel.background = element_rect(fill = NA, colour ="black"),
        panel.border = element_rect(linetype="solid", fill=NA),
        legend.background=element_rect(fill = alpha("white", 0)),
        legend.key = element_rect(colour = "transparent", fill = "white"),
        strip.background = element_rect(colour = NA, fill = NA),
        panel.spacing = unit(1, "lines"))

# save
ggsave(savename, device="png", width=7.48, height=5.5, units="in",dpi=300)

# -------------------------
# Demand - Yearly
table1 = 'Demand'
savename = 'Inputs_Demand_Yearly.png'
conversion = 277.777778 # PJ to GWh
# -------------------------

# read-in data
tbl1 <- dbReadTable(con, table1)

# process data
tbl1$demand <- tbl1$demand * conversion
tbl1$demand <- tbl1$demand * 1.0/1000.0 # GWh to TWh

# plot
plot_demand <- ggplot(data=tbl1, aes_string(x='periods',y='demand'))+
  geom_line() +
  geom_point() +
  labs(x='Hour (-)', y='Demand (TWh)')+
  scale_y_continuous(expand = c(0, 0), limits = c(0, 250)) + 
  theme(axis.text.x = element_text(angle = 0,vjust=0., hjust = 0.5),
        panel.background = element_rect(fill = NA, colour ="black"),
        panel.border = element_rect(linetype="solid", fill=NA),
        legend.background=element_rect(fill = alpha("white", 0)),
        legend.key = element_rect(colour = "transparent", fill = "white"),
        strip.background = element_rect(colour = NA, fill = NA),
        panel.spacing = unit(1, "lines"))

plot_demand_gray <- ggplot(data=tbl1, aes_string(x='periods',y='demand'))+
  geom_line() +
  geom_point() +
  labs(x='Year (-)', y='Demand (TWh)')+
  scale_y_continuous(expand = c(0, 0), limits = c(0, 250)) + 
  theme(axis.text.x = element_text(angle = 0,vjust=0., hjust = 0.5),
        panel.border = element_rect(linetype="solid", fill=NA),
        legend.background=element_rect(fill = alpha("white", 0)),
        legend.key = element_rect(colour = "transparent"),
        strip.background = element_rect(colour = NA, fill = NA),
        panel.spacing = unit(1, "lines"))

# save
# ggsave(savename, device="png", width=7.48, height=5.5, units="in",dpi=300)

# -------------------------
# Emission limits
table1 = 'Demand'
savename = 'Inputs_Demand_Yearly.png'
conversion = 277.777778 # PJ to GWh
# -------------------------
emi <- read.csv('emission_pathways.csv')
names(emi) <- c('Pathway', 'year', 'limit', 'units')

emi$limit <- emi$limit * 1.0/1000.0 # convert kton to Mton

# Set color palette
# predefined palette # http://www.cookbook-r.com/Graphs/Colors_(ggplot2)/
# The palette with black:
pathway_Palette <- c("#E69F00", "#56B4E9", "#009E73","#0072B2", "#D55E00", "#000000", "#CC79A7")
options(ggplot2.discrete.fill = pathway_Palette)
options(ggplot2.discrete.color = pathway_Palette)
options(ggplot2.continuous.color = pathway_Palette)
options(ggplot2.continuous.color = pathway_Palette)

plot_emi <- ggplot(data=emi, aes_string(x='year',y='limit', color='Pathway'))+
  geom_line() +
  geom_point() +
  labs(x='Year (-)', y=expression(paste("Emission limit (Mton CO"[2],")")))+
  scale_y_continuous(expand = c(0, 0), limits = c(0, 25)) + 
  theme(axis.text.x = element_text(angle = 0,vjust=0., hjust = 0.5),
        panel.background = element_rect(fill = NA, colour ="black"),
        panel.border = element_rect(linetype="solid", fill=NA),
        legend.background=element_rect(fill = alpha("white", 0)),
        legend.key = element_rect(colour = "transparent", fill = "white"),
        strip.background = element_rect(colour = NA, fill = NA),
        panel.spacing = unit(1, "lines"),
        legend.position = "bottom")

plot_emi_gray <- ggplot(data=emi, aes_string(x='year',y='limit', color='Pathway'))+
  geom_line() +
  geom_point() +
  labs(x='Year (-)', y=expression(paste("Emission limit (Mton CO"[2],")")))+
  scale_y_continuous(expand = c(0, 0), limits = c(0, 25)) + 
  theme(axis.text.x = element_text(angle = 0,vjust=0., hjust = 0.5),
        panel.border = element_rect(linetype="solid", fill=NA),
        legend.background=element_rect(fill = alpha("white", 0)),
        legend.key = element_rect(colour = "transparent"),
        strip.background = element_rect(colour = NA, fill = NA),
        panel.spacing = unit(1, "lines"),
        legend.position = "bottom")

ggarrange(plot_demand, plot_emi, nrow=2, ncol=1, heights = c(1,1.2), align="v", 
          labels= c("A", "B"), label.x = 0.0, label.y = 1.0)

savename = 'Fig4_demand_emissions.png'
ggsave(savename, device="png", width=3.54, height=7.0, units="in",dpi=500)


ggarrange(plot_demand_gray, plot_emi_gray, nrow=2, ncol=1, heights = c(1,1.2), align="v",  
          labels= c("A", "B"), label.x = 0.0, label.y = 1.0)

savename = 'Fig4_demand_emissions_gray.png'
ggsave(savename, device="png", width=3.54, height=7.0, units="in",dpi=500)

# -------------------------
# Demand
table1 = 'Demand'
table2 = 'DemandSpecificDistribution'
savename = 'Inputs_Demand.pdf'
conversion = 277.777778 # M$/PJ to $/kWh
# -------------------------

# read-in data
tbl1 <- dbReadTable(con, table1)
tbl2 <- dbReadTable(con, table2)

# process data
tbl1$demand <- tbl1$demand * conversion
tbl2 <- transform(tbl2, season_name = season_rename[as.character(season_name)])
tbl2 <- transform(tbl2, time_of_day_name = tod_rename[as.character(time_of_day_name)])


# periods <- unique(tbl1$periods)
# tbl2$year <- periods[1]
# tbl3 <- tbl2
# tbl3$dds <- tbl3$dds * tb


for (i in 1:length(tbl1$periods)){
  print(i)
  print(tbl1$periods[i])
  print(tbl1$demand[i])
  tbl_x <- tbl2
  tbl_x$year <- toString(tbl1$periods[i])
  tbl_x$dds <- tbl_x$dds * tbl1$demand[i]
  if (i==1){
    tbl3 <- tbl_x
  }
  else {
    tbl3 <- rbind(tbl3, tbl_x)
  }
  
}

# plot order
tbl3$season_name <- factor(tbl3$season_name,levels = season_levels)

# Set color palette
demand_palette <- brewer.pal(n=length(tbl1$periods),name="Greys") # predefined palette # http://www.cookbook-r.com/Graphs/Colors_(ggplot2)/
options(ggplot2.discrete.fill = demand_palette)
options(ggplot2.discrete.color = demand_palette)
options(ggplot2.continuous.color = demand_palette)
options(ggplot2.continuous.color = demand_palette)

# plot
ggplot(data=tbl3, aes_string(x='time_of_day_name',y='dds',color='year'))+
  geom_line() +
  labs(x='Hour (-)', y='Demand (GWh)',
       col='Year')+
  facet_wrap('season_name')+
  scale_y_continuous(expand = c(0, 0), limits = c(0, NA)) + 
  theme(axis.text.x = element_text(angle = 0,vjust=0., hjust = 0.5),
        panel.background = element_rect(fill = NA, colour ="black"),
        panel.border = element_rect(linetype="solid", fill=NA),
        legend.background=element_rect(fill = alpha("white", 0)),
        legend.key = element_rect(colour = "transparent", fill = "white"),
        strip.background = element_rect(colour = NA, fill = NA),
        panel.spacing = unit(1, "lines"))

# save
ggsave(savename, device="pdf", width=7.48, height=5.5, units="in",dpi=300)


# -------------------------
# Combine Demand and Capacity Factor TOD
# -------------------------

custom_palette <- c('#000000', tech_palette)

# Set color palette
options(ggplot2.discrete.fill = custom_palette)
options(ggplot2.discrete.color = custom_palette)
options(ggplot2.continuous.color = custom_palette)
options(ggplot2.continuous.color = custom_palette)

# Normalize demand by season
for (i in 1:length(season_rename)){
  tbl2[tbl2$season_name == season_rename[i],'dds'] <- tbl2[tbl2$season_name == season_rename[i],'dds'] / max(tbl2[tbl2$season_name == season_rename[i],'dds'])
}
# Rename demand columns to match capacity factor table
tbl2 <- tbl2 %>% rename(tech='demand_name', cf_tech='dds')
# Rename entries in demand
demand_rename = c('ELC_DMD'='Demand')
tbl2 <- transform(tbl2, tech = demand_rename[as.character(tech)])
# Remove note columns
tbl = subset(tbl, select = -c(cf_tech_notes) )
tbl2 = subset(tbl2, select = -c(dds_notes) )

names(tbl2)[names(tbl2) == "tech"] <- "Technologies" # rename column
# Combine dataframes
tbl_comb <- rbind(tbl2,tbl)

# set order for plotting
levels <- c("Demand", tech_levels)
tbl_comb$Technologies <- factor(tbl_comb$Technologies,levels = levels)
tbl_comb$season_name <- factor(tbl_comb$season_name,levels = season_levels)

# Set color palette - add black for Demand
line_styles <- c('solid', line_styles)
newPalette <- c('#000000',tech_palette)


# plot
ggplot(data=tbl_comb, aes_string(x='time_of_day_name',y='cf_tech',color='Technologies', linetype='Technologies'))+
  geom_line()+
  facet_wrap('season_name')+
  scale_linetype_manual(values=line_styles,labels=parse_format())+
  scale_color_manual(values=newPalette,labels=parse_format())+
  scale_y_continuous(expand = c(0, 0), limits = c(0, NA)) + 
  labs(x='Hour (-)', y='Normalized demand and resource availability (-)',
       col='Technologies')+
  theme(axis.text.x = element_text(angle = 0,vjust=0., hjust = 0.5),
        panel.background = element_rect(fill = NA, colour ="black"),
        panel.border = element_rect(linetype="solid", fill=NA),
        legend.background=element_rect(fill = alpha("white", 0)),
        legend.key = element_rect(colour = "transparent", fill = "white"),
        strip.background = element_rect(colour = NA, fill = NA),
        panel.spacing = unit(1, "lines"),
        legend.position = "bottom")

# save
savename = 'Fig2_Inputs_Demand_CapacityFactor.png'
ggsave(savename, device="png", width=7.48, height=5.5, units="in",dpi=300)

# plot
ggplot(data=tbl_comb, aes_string(x='time_of_day_name',y='cf_tech',color='Technologies', linetype='Technologies'))+
  geom_line()+
  facet_wrap('season_name')+
  scale_linetype_manual(values=line_styles,labels=parse_format())+
  scale_color_manual(values=newPalette,labels=parse_format())+
  scale_y_continuous(expand = c(0, 0), limits = c(0, NA)) + 
  labs(x='Hour (-)', y='Normalized demand and resource availability (-)',
       col='Technologies')+
  theme(axis.text.x = element_text(angle = 0,vjust=0., hjust = 0.5),
        panel.background = element_rect(colour ="black"),
        legend.background=element_rect(fill = alpha("white", 0)),
        legend.key = element_rect(colour = "transparent"),
        strip.background = element_rect(colour = NA, fill = NA),
        panel.spacing = unit(1, "lines"),
        legend.position = "bottom")

# save
savename = 'Fig2_Inputs_Demand_CapacityFactor_gray.png'
ggsave(savename, device="png", width=7.48, height=5.5, units="in",dpi=300)


# -------------------------
# finish program and tidy up
# -------------------------
# disconnect from database
dbDisconnect(con)
