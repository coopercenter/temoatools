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
db = 'wEmerg_wFossil_2050.sqlite' # database to analyze, assumed to be in results directory


# This is order that items will be plotted, only items included will be plotted
tech_rename <- c('EC_SOLPV_Util'="'Solar PV'",
                 'EC_WIND_Fix'="'Offshore Wind'")

h <- hash()
h[['EC_WIND_Fix']] <- c('darkblue', 'solid')
h[['EC_SOLPV_Util']] <- c('orange', 'solid')


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


# ======================== #
# begin code
# ======================== #
dir_work = dirname(rstudioapi::getSourceEditorContext()$path)
setwd(dir_work)
setwd('../databases')

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
# -------------------------
table = 'CapacityFactorTech'

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

# -------------------------
# Demand
# -------------------------
table2 = 'DemandSpecificDistribution'

# read-in data
tbl2 <- dbReadTable(con, table2)

# process data
tbl2 <- transform(tbl2, season_name = season_rename[as.character(season_name)])
tbl2 <- transform(tbl2, time_of_day_name = tod_rename[as.character(time_of_day_name)])
tbl2$year <- periods[1]

# Normalize demand by season
for (i in 1:length(season_rename)){
  tbl2[tbl2$season_name == season_rename[i],'dds'] <- tbl2[tbl2$season_name == season_rename[i],'dds'] / max(tbl2[tbl2$season_name == season_rename[i],'dds'])
}

# -------------------------
# Combine Demand and Capacity Factor TOD
# -------------------------

# Rename demand columns to match capacity factor table
tbl2 <- tbl2 %>% rename(tech='demand_name', cf_tech='dds')

# Rename entries in demand
demand_rename = c('ELC_DMD'='Demand')
tbl2 <- transform(tbl2, tech = demand_rename[as.character(tech)])
names(tbl2)[names(tbl2) == "tech"] <- "Technologies" # rename column

# Remove note columns
tbl = subset(tbl, select = -c(cf_tech_notes) )
tbl2 = subset(tbl2, select = -c(dds_notes) )

# Combine dataframes
tbl_comb <- rbind(tbl2,tbl)

# set order for plotting
levels <- c("Demand", tech_levels)
tbl_comb$Technologies <- factor(tbl_comb$Technologies,levels = levels)
tbl_comb$season_name <- factor(tbl_comb$season_name,levels = season_levels)


# -------------------------
# Plot
# -------------------------

# Set color palette - add black for Demand
line_styles <- c('solid', line_styles)
newPalette <- c('#000000',tech_palette)

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

# Column width guidelines https://www.elsevier.com/authors/author-schemas/artwork-and-media-instructions/artwork-sizing
# Single column: 90mm = 3.54 in
# 1.5 column: 140 mm = 5.51 in
# 2 column: 190 mm = 7.48 in

# save
savename = 'Fig2_hourly_demand_availability.png'
ggsave(savename, device="png", width=7.48, height=5.5, units="in",dpi=300)

# -------------------------
# finish program and tidy up
# -------------------------
# disconnect from database
dbDisconnect(con)
