library(RSQLite)
library(ggplot2)


# inputs
dbs = c('all.sqlite') # list of databases to analyze, assumed to be in results directory
tables = c('CostInvest', 'CostVariable', 'CostFixed') # list of SQLite tables to plot

# ======================== #
# begin code
# ======================== #
dir_work = dirname(rstudioapi::getSourceEditorContext()$path)
setwd(dir_work)
setwd('databases')

#dir_dbs = dir_work + '/databases'
# dir_results = dir_work + '/inputs'

# iterate through databases, connecting to each one at a time
for (db in dbs){
  con <- dbConnect(SQLite(),db)
  setwd('../results')
  
  # iterate through tables, plotting one at a time
  for (i in 1:length(tables) ){
    tbl <- dbReadTable(con, tables[i])
    
    # ggplot(data=tbl, aes_string(x=x_var[i],y=y_var[i]))+geom_line()+facet_wrap(series_var[i])
    
    if (tables[i] == 'CostInvest')
    {
      ggplot(data=tbl, aes_string(x='vintage',y='cost_invest'))+geom_line()+facet_wrap('tech')
    }
    
    if (tables[i] == 'CostVariable')
    {
      ggplot(data=tbl, aes_string(x='periods',y='cost_variable',color='vintage'))+geom_line()+facet_wrap('tech')
    }
    
    if (tables[i] == 'CostFixed')
    {
      ggplot(data=tbl, aes_string(x='periods',y='cost_fixed',color='vintage'))+geom_line()+facet_wrap('tech')
    }
    
    
    savename = paste(tools::file_path_sans_ext(db),tables[i],'.pdf')
    ggsave(savename, device="pdf", width=11.0, height=8.5, units="in",dpi=300)
    
    
    
    
    
    # series_var = c('tech', 'tech','tech')
    # x_var = c('vintage','periods','periods')
    # y_var = c('cost_invest','','')
    # 
    # x_label = c('Year (-)','Year (-)', 'Year (-)')
    # y_label = c('Investment Cost (M USD/GW','Variable Cost (M USD/PJ','Fixed Cost (M USD/GW')
    
  }
  setwd('../databases')
}
