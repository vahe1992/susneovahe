


validate_csv <- function(df) {
  if(!is.data.frame(df) || length(df) == 0 || ncol(df) != 6)
  {
    return("Invalid CSV structure: must have exactly 6 columns.")
  }
  if(nrow(df) < 1)
  {
    return("CSV file should have at least 2 rows.")
  }
  if(!any("date" %in% colnames(df)))
  {
    return("Missing required column: date")
  }
  if(!any("site" %in% colnames(df)))
  {
    return("Missing required column: site")
  }
  if(!any("type" %in% colnames(df)))
  {
    return("Missing required column: type")
  }
  df$date <- as.Date(df$date, format="%d-%m-%Y")
  if(anyNA(df$date))
  {
    return("Invalid date format in 'date' column. Expected formats: DD-MM-YYYY")
  }
  df = df[order(df$date), ]
  colnames(df)[6] <- 'kg'
  return(df)
}



calc_statistics <- function(df) {
  
  df = validate_csv(df)
  if(!is.data.frame(df))
  {
    return(df) # return error message if validation fails
  }

  total_cost = round(sum(df[,5], na.rm=TRUE),2)
  avg_cost = round(mean(df[,5], na.rm=TRUE),2)
  total_emissions = round(sum(df[,6], na.rm=TRUE),2)
  
  stats = data.frame(
    Metric = c("Total Cost", "Average Cost", "Total Emissions"),
    Value = c(total_cost, avg_cost, total_emissions)
  )


  return(stats)
}

