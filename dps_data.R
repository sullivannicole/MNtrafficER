# --------------
# Libraries
# --------------
library(rvest)
library(xml2)
library(stringr)
library(tidyverse)
library(glue)

path_prefix <- '/Users/nicolesullivan/Documents/Academic/2021-2023/MS_in_DS/Coursework/2023/Spring/CSCI_8980/data'
source(glue('{path_prefix}/dps_functions.R'))

# ---------------
# Pull data
# ---------------

current_dttm <- str_replace_all(Sys.time(), ':|CST', '_')

pg_nums <- 40400:40480

incident_df <- map_dfr(pg_nums, run_incident_pull)
vehicles_df <- map_dfr(pg_nums, run_vehicle_pull)

write_csv(incident_df, glue('{path_prefix}/dps_data/incidents_{current_dttm}.csv'))
write_csv(vehicles_df, glue('{path_prefix}/dps_data/vehicles_{current_dttm}.csv'))
