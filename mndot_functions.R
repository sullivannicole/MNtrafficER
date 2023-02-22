# Load in xml gz file
load_xmlgz <- function(url) {
  
  tmp <- tempfile()
  download.file(url, tmp)
  xml_file <- read_xml(gzfile(tmp))
  
  return(xml_file)
}

# Function to pull a specific attribute nested under a particular node
get_attribute <- function(xml_data, node, attribute) xml_attr(xml_find_all(xml_data, glue('//{node}')), attribute)

# Create dataframe from nested attributes and paths
create_attribute_df <- function(attr_args, attr_df = NULL) {
  
  attr <- pmap_dfc(attr_args, get_attribute)
  
  # Rename columns
  colnames(attr) <- attr_args$attribute
  
  # If "UNKNOWN" is a value, replace with NA
  attr[attr == 'UNKNOWN'] <- NA
  
  # Add full df back to attributes pulled 
  if(is.null(attr_df)){
    
    full_df <- attr %>%
      mutate(load_ts = approx_time)
    
  } else {
    
    full_df <- bind_cols(attr, attr_df) %>%
      mutate(load_ts = approx_time)
  }
  
  return(full_df)
  
}
