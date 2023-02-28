# -------------------
# Run workflows
# -------------------

run_incident_pull <- function(pg_num) {
  
  try({
    dps_incidents <- get_incidents(pg_num)
    incident_df <- create_incident_df(dps_incidents)
  })
  
  return(incident_df)
  
}

run_vehicle_pull <- function(pg_num) {
  
  try({
    dps_incidents <- get_incidents(pg_num)
    vehicles_df <- create_vehicles_df(dps_incidents)
  })
  
  return(vehicles_df)
  
}

# ----------------------
# Incident functions
# Vehicles functions
# ----------------------

# GUI: https://app.dps.mn.gov/MSPMedia2/
get_incidents <- function(pg_num) {
  
  dps_incidents <- read_html(glue("https://app.dps.mn.gov/MSPMedia2/IncidentDisplay/{pg_num}"))
  
  return(dps_incidents)
  
}

get_incident_values <- function(dps_incidents) {
  
  incident_vals <- dps_incidents %>%
    html_node('#incident-body') %>%
    xml_children() %>%
    xml_children() %>%
    html_text() %>%
    as.data.frame() %>%
    rename(value = 1) %>%
    mutate(value = str_squish(str_replace_all(value, '\\\r\\\n|', ''))) %>%
    filter(value != '')
  
  return(incident_vals)
  
  
}

create_incident_df <- function(dps_incidents) {
  
  incident_vals_df  <- get_incident_values(dps_incidents)
  
  incident_df <- incident_vals_df %>%
    mutate(ends_with_noncolon = ifelse(str_sub(value, start = -1) == ':', 0, 1),
           lag_noncolon = lag(ends_with_noncolon, default = 1),
           noncolon_cumulsum = cumsum(lag_noncolon)) %>%
    group_by(noncolon_cumulsum) %>%
    summarize(value = paste(value, collapse = " ")) %>%
    ungroup() %>%
    separate(value, into = c('variable', 'value'), sep = ':', extra = 'merge') %>%
    select(-noncolon_cumulsum) %>%
    mutate(addtl_info_col = ifelse(is.na(value), 1, 0 )) %>%
    group_by(addtl_info_col) %>%
    mutate(addtl_info = paste(variable, collapse = '_')) %>%
    ungroup() %>%
    mutate(variable = ifelse(is.na(value), 'addtl_info', str_replace_all(str_to_lower(variable), ' |\\/', '_')),
           value = ifelse(is.na(value), addtl_info, value),
           value = str_squish(value)) %>%
    select(-addtl_info_col, -addtl_info) %>%
    distinct() %>%
    spread(variable, value = value)
  
  return(incident_df)
  
}

create_vehicles_df <- function(dps_incidents) {
  
  incident_vals <- get_incident_values(dps_incidents)
  
  icr_df <- incident_vals %>%
    mutate(row_id = row_number(),
           icr_row = ifelse(value == 'ICR:', 1, 0),
           icr_val = lag(icr_row, default = 0)) %>%
    filter(icr_val == 1)
  
  
  vehicles_involved <- dps_incidents %>%
    html_node("#collapseVehicle") %>%
    xml_children() %>%
    xml_children() %>%
    html_nodes("div") %>% 
    html_text()
  
  
  vehicles_df <- map(vehicles_involved, function(x) str_squish(str_replace_all(x, '\\\r\\\n|', ''))) %>% 
    unlist() %>% 
    as.data.frame() %>%
    rename(value = 1) %>%
    filter(value != '') %>%
    mutate(value_lagged = lag(value),
           previous_value_diff = ifelse(value == value_lagged | is.na(value_lagged), 0, 1),
           value_cumulsum = cumsum(previous_value_diff)) %>%
    group_by(value_cumulsum) %>%
    mutate(group_id = row_number()) %>%
    ungroup() %>%
    filter(group_id == 1) %>%
    select(value) %>%
    mutate(value = ifelse(value %in% c('Vehicle', 'Driver', 'Passenger'), paste0(value, ':'), value),
           ends_with_noncolon = ifelse(str_sub(value, start= -1) == ':', 0, 1),
           lag_noncolon = lag(ends_with_noncolon, default = 1),
           noncolon_cumulsum = cumsum(lag_noncolon)) %>%
    group_by(noncolon_cumulsum) %>%
    summarize(value = paste(value, collapse = " ")) %>%
    select(value) %>%
    separate(value, into = c('variable', 'value'), sep = ':', extra = 'merge') %>%
    mutate(value = str_squish(ifelse(is.na(value) & str_detect(variable, 'USA'), variable, value)),
           variable = str_to_lower(ifelse(str_detect(variable, 'USA'), 'location', variable)),
           variable = str_replace_all(variable, ' ', '_')) %>%
    filter(value != 'Yes Helmet') %>%
    mutate(var_lead = lead(variable, default = 'other'),
           next_var_same = ifelse(variable == var_lead, 1, 0)) %>%
    filter(next_var_same == 0) %>%
    select(-var_lead, -next_var_same) %>%
    mutate(vehicle_row = ifelse(variable == 'vehicle', 1, 0),
           vehicle_id = cumsum(vehicle_row),
           person_row = ifelse(variable %in% c('driver', 'passenger'), 1, 0),
           person_id = cumsum(person_row),
           gender = ifelse(str_detect(variable, 'age'), str_replace_all(variable, '_age', ''), NA),
           person_type = ifelse(variable %in% c('driver', 'passenger'), variable, NA),
           variable = case_when(str_detect(variable, 'age') ~ 'age', 
                                variable %in% c('driver', 'passenger') ~ 'name',
                                TRUE ~ variable)) %>%
    select(-vehicle_row, -person_row) %>%
    group_by(vehicle_id, person_id) %>%
    tidyr::fill(gender, .direction = 'updown') %>%
    tidyr::fill(person_type, .direction = 'updown') %>%
    ungroup() %>%
    spread(variable, value = value) %>%
    select(-person_id) %>%
    group_by(vehicle_id) %>%
    fill(vehicle, .direction = 'updown') %>%
    fill(airbag_deployed, .direction = 'updown') %>%
    ungroup() %>%
    filter(!is.na(person_type)) %>%
    mutate(incident_case_record = icr_df$value) %>% #incident_df$icr
    select(-vehicle_id)
  
  return(vehicles_df)
}
