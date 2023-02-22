
# ************************************************************************************************************************************
# Cron set-up steps
# The cron scheduler automatically runs this script.
# To allow it to do so, I had to go in to Systems Preferences > Security and Privacy > Full Disk Access (on the left) and then:
# Add RStudio
# Follow the instructions to add cron: https://apple.stackexchange.com/questions/378553/crontab-operation-not-permitted


# Cron maintenance notes
# To view the crontab schedule, in the terminal (in any location), run: crontab -l
# To edit the crontab schedule, in the terminal, run: crontab -e; then hit i once in the vim
# To save and exit the vim editor, run: :wq and hit ENTER

# CronR
# With R specifically, you can run install.packages("cronR")
# Then click on "Addins" at the top of RStudio, then click on "Schedule R scripts..." and add the script
# Click "Create Job"

# Helpful links:
# * https://blog.dennisokeeffe.com/blog/2021-01-19-running-cronjobs-on-your-local-mac
# * https://crontab.guru/

# ************************************************************************************************************************************

# --------------------
# Imports
# --------------------

library(tidyverse)
library(xml2)
library(stringr)
library(glue)

wd_path <- '/Users/nicolesullivan/Documents/Academic/2021-2023/MS_in_DS/Coursework/2023/Spring/CSCI_8980/data'
save_prefix <- glue('{wd_path}/traffic_data')

source(glue('{wd_path}/mndot_functions.R'))

# For saving clean df's
approx_time <- Sys.time()
approx_time_str <- str_replace_all(approx_time, ':', '_')

# --------------------
# Sensor attributes
# --------------------

det_sample <- load_xmlgz('http://data.dot.state.mn.us/iris_xml/det_sample.xml.gz')

sensor_args <- list(xml_data = list(det_sample),
                    node = rep('//sample', 4),
                    attribute = c('sensor', 'flow', 'speed', 'occ'))

# Pull attributes for each sample and rename columns
sample_df <- create_attribute_df(sensor_args)

write_csv(sample_df, glue('{save_prefix}/sensors/sensors_{approx_time_str}.csv'))

# ----------------------
# Sensor configuration
# ----------------------

metro_config <- load_xmlgz('http://data.dot.state.mn.us/iris_xml/metro_config.xml.gz')

# Detector paths & args
detector_paths <- data.frame('detector_path' = xml_path(xml_find_all(metro_config, '//detector'))) %>%
  mutate(detector_path = str_replace(detector_path, '/tms_config/', '')) %>%
  separate(detector_path, into = c('corridor_id', 'rnode_id', 'detector_id'), sep = '/')


detector_args <- list(xml_data = list(metro_config),
                      node = '//detector',
                      attribute = c('name', 'label', 'category', 'lane', 'field', 'controller', 'abandoned'))


# Rnode paths & args
rnode_paths <- data.frame(rnode_path = xml_path(xml_find_all(metro_config, "//r_node"))) %>%
  mutate(rnode_path = str_replace(rnode_path, '/tms_config/', '')) %>%
  separate(rnode_path, into = c('corridor_id', 'rnode_id'), sep = '/')

rnode_args <- list(xml_data = list(metro_config),
                   node = '//r_node',
                   attribute = c('name', 'n_type', 'transition', 'label', 'lon', 'lat', 'lanes',
                                 'shift', 's_limit', 'station_id', 'attach_side'))

# Corridor paths & args
corridor_paths <- data.frame(corridor_id = xml_path(xml_find_all(metro_config, "//corridor"))) %>%
  mutate(corridor_id = str_replace(corridor_id, '/tms_config/', ''))

corr_args <- list(xml_data = list(metro_config),
                  node = rep('//corridor', 2), 
                  attribute = c('route', 'dir'))

detector_df <- create_attribute_df(detector_args, detector_paths)
rnode_df <- create_attribute_df(rnode_args, rnode_paths)
corridor_df <- create_attribute_df(corr_args, corridor_paths)


save_args <- list(x = list(corridor_df, rnode_df, detector_df),
                  file = c(glue('{save_prefix}/configs/corridors_{approx_time_str}.csv'), 
                           glue('{save_prefix}/configs/rnodes_{approx_time_str}.csv'), 
                           glue('{save_prefix}/configs/detectors_{approx_time_str}.csv')))


pwalk(save_args, write_csv)

# --------------------
# Incident attributes
# --------------------
incidents <- load_xmlgz('http://data.dot.state.mn.us/iris_xml/incident.xml.gz')

incident_paths <- data.frame(incident_id = xml_path(xml_find_all(incidents, "//incident")))

incident_args <- list(xml_data = list(incidents),
                      node = '//incident',
                      attribute = c('name', 'replaces', 'event_type', 'event_date', 'lane_code', 'road',
                                    'dir', 'location', 'lon', 'lat', 'camera', 'impact', 'cleared', 'confirmed'))

# Pull attributes for each sample and rename columns
incident_df <- create_attribute_df(incident_args, incident_paths)

write_csv(incident_df, glue('{save_prefix}/incidents/incidents_{approx_time_str}.csv'))
