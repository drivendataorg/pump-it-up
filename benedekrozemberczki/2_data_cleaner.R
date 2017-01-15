#--------------------------------------------------------------
# First the raw datasets are loaded with the list of keywords.
#--------------------------------------------------------------

test <- read.csv("./raw_dataset/test.csv", stringsAsFactors = FALSE)
train <- read.csv("./raw_dataset/train.csv", stringsAsFactors = FALSE)
keywords <- read.csv("./clean_dataset/keywords.csv", stringsAsFactors = FALSE)

#---------------------------------------------------------------------
# The dummygen function helps in the production of consistent tables.
#---------------------------------------------------------------------

dummygen <- function(new_table, original_table, dummified_column, column_values, new_name){ 
  
  #------------------------------------------------------------------------------
  # INPUT 1. -- The new cleaned table -- I will attach the dummies to this table.
  # INPUT 2. -- The original table that is being cleaned.
  # INPUT 3. -- The column that has the strings.
  # INPUT 4. -- The unique values in the column encoded.
  # INPUT 5. -- The new name of the columns.
  # OUTPUT -- The new table with the dummy variables.
  #------------------------------------------------------------------------------
  
  i <- 0
  
  for (val in column_values){
    i <- i + 1
    new_variable <- data.frame(matrix(0, nrow(new_table), 1))
    new_variable[original_table[,dummified_column] == val, 1] <- 1
    colnames(new_variable) <- paste0(new_name, i)
    new_table <- cbind(new_table,new_variable)
  }
  
  return(new_table)
}

#---------------------------------------------------------------------------------------------------
# The data cleaning process is done by a function which calls the dummifier function multiple times.
#---------------------------------------------------------------------------------------------------

data_munger <- function(input_table, keywords){
  
  #-------------------------------------------
  # INPUT 1.: The table to be cleaned.
  # INPUT 2.: The table of frequent keywords.
  # OUTPUT: The cleaned numeric tables.
  #-------------------------------------------
  
  #----------------------------------------------
  # Defining a target table for the cleaned data.
  #----------------------------------------------
  
  new_table <- data.frame(matrix(0, nrow(input_table), 1))
  
  #-----------------------------------------------------
  # The first variable extracted is the ID of the wells.
  #-----------------------------------------------------
  
  colnames(new_table) <- c("id")
  new_table$id <- input_table$id
  
  #-------------------------------------------------------------------------------------------
  # The amount variable is skewed, the log transformation can help during the quantile sketch.
  # Addition of one is needed to avoid missing values.
  # The square is added and a dummy to flag values above the third quantile.
  #-------------------------------------------------------------------------------------------
  
  new_table$amount <- log(input_table$amount_tsh + 1)
  
  new_table$amount_squared <- new_table$amount * new_table$amount
  
  new_table$amount_q3 <- 0
  new_table$amount_q3[new_table$amount > 3.044] <- 1
  
  #--------------------------------------------------
  # I generate three searate dummies for the years.
  # The across year seasonality might matter.
  #--------------------------------------------------
  
  new_table$year_1<- 0
  new_table$year_1[substr(input_table$date_recorded, 1, 4) == "2011"] <- 1
  
  new_table$year_2 <- 0
  new_table$year_2[substr(input_table$date_recorded, 1, 4) == "2012"] <- 1
  
  new_table$year_3 <- 0
  new_table$year_3[substr(input_table$date_recorded, 1, 4) == "2013"] <- 1
  
  #-----------------------------------------------------------
  # The month values are mapped into separate dummy variables.
  # There is possible monthly seasonality.
  # This dummification is needed because of the date format.
  #-----------------------------------------------------------
  
  month_values <- c("01", "02","03", "04", "05", "06",
                    "07", "08", "09", "10", "11", "12")
  
  month_names <-  c("jan", "feb", "mar", "apr", "may", "jun",
                    "jul", "aug", "sep", "oct", "nov", "dec")
  
  for (i in 1:12){
    
    new_table <- cbind(new_table, rep(0, nrow(new_table)))
    new_table[substr(input_table$date_recorded, 6, 7) == month_values[i], ncol(new_table)] <- 1
    colnames(new_table)[ncol(new_table)] <- month_names[i]
    
  }
    
  #---------------------------------------------------------------
  # Sometimes weekends mark anomalies - so a dummy can be helpful.
  #---------------------------------------------------------------
  
  new_table$weekend <- 0
  new_table$weekend[lubridate::wday(input_table$date_recorded) %in% c(1, 7)] <- 1
  
  #----------------------------------------------------------
  # The GPS coordinates are mapped directly to the new table.
  #----------------------------------------------------------
   
  new_table$height <- input_table$gps_height
  new_table$longitude <- input_table$longitude
  new_table$latitude <- input_table$latitude
  
  #---------------------------------------------------------
  # The basin values are not from they keywords config file.
  # They are dummified with my predefined function.
  #---------------------------------------------------------
  
  basins <- c("internal",
              "lake nyasa",
              "lake rukwa",             
              "lake tanganyika",
              "lake victoria",
              "pangani",                
              "rufiji",
              "ruvuma / southern coast",
              "wami / ruvu")
  
  new_table <- dummygen(new_table, input_table, "basin", basins, "basin_")
  
  #-------------------------------------------------------------------------------------
  # The region values are from they keywords config file - the dataframe is unbalanced.
  # The dummifier is applied.
  #-------------------------------------------------------------------------------------
  
  region <- keywords$region[is.na(keywords$region) == FALSE]
    
  new_table <- dummygen(new_table, input_table, "region", region, "region_")
  
  #----------------------------------------------------------------------
  # The population is log transformed.
  # Based on the histogram the log transformed distribution has a saddle.
  # Data points above the saddle are flagged. 
  #----------------------------------------------------------------------
  
  new_table$population <- log(input_table$population + 1)
  new_table$population_below <- 0
  new_table$population_below[new_table$Population < 2] <- 1
  
  #------------------------------------------------------------------------
  # The public meeting variable is dummified - it has three unique values.
  #------------------------------------------------------------------------
  
  public_meeting <- c("False", "True", "")
  
  new_table <- dummygen(new_table, input_table, "public_meeting", public_meeting, "public_meeting_")
  
  #-----------------------------------------------------------------
  # The permit variable is dummified - it has three unique values.
  #-----------------------------------------------------------------
  
  permit <- c("False", "True", "")
  new_table <- dummygen(new_table, input_table, "permit", permit, "permit_")
  
  #-------------------------------------------------------
  # There are unique construction years from 1960 to 2013.
  # This can be dummified.
  #-------------------------------------------------------
  
  construction_year <- c(0, c(1960:2013))
  
  new_table <- dummygen(new_table, input_table, "construction_year", construction_year, "construction_year_")
  
  #--------------------------------------------------------------
  # The scheme management values are included in the config file.
  # After it is loaded from the keywords it can be dummified. 
  #--------------------------------------------------------------
  
  scheme_management <- keywords$scheme_management[!is.na(keywords$scheme_management)]
  
  new_table <- dummygen(new_table, input_table, "scheme_management", scheme_management, "scheme_man_")
  
  #------------------------------------------------------------
  # The extraction type values are included in the config file.
  # After it is loaded from the keywords it can be dummified. 
  #------------------------------------------------------------
  
  extraction_type <- keywords$extraction_type[!is.na(keywords$extraction_type)]
  
  new_table <- dummygen(new_table, input_table, "extraction_type", extraction_type, "ext_type_")
  
  #-------------------------------
  # The sources are defined here.
  #-------------------------------
  
  source <- c("spring",
              "rainwater harvesting",
              "dam",
              "machine dbh",     
              "other",
              "shallow well",
              "river",
              "hand dtw",            
              "lake",
              "unknown")
  
  new_table <- dummygen(new_table, input_table, "source", source, "source_")
  
  #----------------------------------------------------
  # The payment is dummified based on the keyword list.
  #----------------------------------------------------
  
  payment <- c("pay annually",
                "never pay",
                "pay per bucket",
                "unknown",              
                "pay when scheme fails",
                "other",
                "pay monthly")
  
  new_table <- dummygen(new_table, input_table, "payment", payment, "payment_")
  
  #-----------------------------------------------------------------------------------------
  # The waterquality only has a few values, so they are defined here and encoded as dummies.
  #-----------------------------------------------------------------------------------------
  
  water_quality <- c("soft",
                     "salty",
                     "milky",
                     "unknown",
                     "fluoride",          
                     "coloured",
                     "salty abandoned",
                     "fluoride abandoned")
  
  new_table <- dummygen(new_table, input_table, "water_quality", water_quality, "water_quality_")
  
  #-----------------------------------------------------------
  # The quality group is dummified based on the keyword list.
  #-----------------------------------------------------------
  
  quality_group <- c("good",
                     "salty",
                     "milky",
                     "unknown",
                     "fluoride",
                     "colored")
  
  new_table <- dummygen(new_table, input_table, "quality_group", quality_group, "quality_group_")
  
  #-----------------------------------------------------
  # The quantity is dummified based on the keyword list.
  #-----------------------------------------------------
  
  quantity <- c("enough",
                "insufficient",
                "dry",
                "seasonal",
                "unknown")
  
  new_table <- dummygen(new_table, input_table, "quantity", quantity, "quantity_")
  
  #------------------------------------------------------------
  # The waterpoint type is dummified based on the keyword list.
  #------------------------------------------------------------
  
  waterpoint_type <- c("communal standpipe",
                       "communal standpipe multiple",
                       "hand pump",                  
                       "other",
                       "improved spring",
                       "cattle trough",
                       "dam")
  
  new_table <- dummygen(new_table, input_table, "quantity", quantity, "quantity_")
  
  #---------------------------------------------------------
  # The source class is dummified based on the keyword list.
  #---------------------------------------------------------
  
  source_class <- c("groundwater","surface","unknown" )
  
  new_table <- dummygen(new_table, input_table, "source_class", source_class, "source_class_")
  
  #--------------------------------------------------------
  # The scheme name is dummified based on the keyword list.
  #--------------------------------------------------------
  
  scheme_name <- keywords$scheme_name[1:50]
  
  new_table <- dummygen(new_table, input_table, "scheme_name", scheme_name, "scheme_name_")
  
  #----------------------------------------------------------
  # The ward variable is dummified based on the keyword list.
  #----------------------------------------------------------
  
  ward <- keywords$ward[1:50]
  
  new_table <- dummygen(new_table, input_table, "ward", ward, "ward_")
  
  #---------------------------------------------------
  # The funder is dummified based on the keyword list.
  #---------------------------------------------------
  
  funder <- keywords$funder[1:50]
  
  new_table <- dummygen(new_table, input_table, "funder", funder, "funder_")
  
  #---------------------------------------------------------------
  # The installer variable is dummified based on the keyword list.
  #---------------------------------------------------------------
  
  installer <- keywords$installer[1:50]
  
  new_table <- dummygen(new_table, input_table, "installer", installer, "installer_")
  
  #------------------------------------------------
  # The LGA is dummified based on the keyword list.
  #------------------------------------------------
  
  lga <- keywords$lga[1:50]
  
  new_table <- dummygen(new_table, input_table, "lga", lga, "lga_")
  
  #-------------------------------------------------------------
  # The management group is dummified based on the keyword list.
  #-------------------------------------------------------------
  
  management_group <- c("parastatal",
                        "user-group",
                        "other",
                        "commerical",
                        "unknown")
  
  new_table <- dummygen(new_table, input_table,
                        "management_group",
                        management_group,
                        "management_group_")
   
  #------------------------------------------------------------
  # The management type is dummified based on the keyword list.
  #------------------------------------------------------------
  
  management <- c("parastatal",
                  "vwc",
                  "water board",
                  "other - school",
                  "wug",
                  "wua",
                  "private operator",
                  "company",
                  "other",
                  "water authority",
                  "unknown",
                  "trust")
  
  new_table <- dummygen(new_table, input_table, "management", management, "management_")
  
  #------------------------------------------------------------
  # The waterpoint name is dummified based on the keyword list.
  #------------------------------------------------------------
  
  wpt_name <- keywords$wpt_name[1:50]
  
  new_table <- dummygen(new_table, input_table, "wpt_name", wpt_name, "wpt_name_")
  
  #-----------------------------------------------------------
  # The recording date is dummified based on the keyword list.
  #-----------------------------------------------------------
  
  dates <- keywords$date[1:50]
  
  new_table <- dummygen(new_table, input_table, "date_recorded", dates, "date_")
  
  #------------------------------------------------------
  # The subvilage is dummified based on the keyword list.
  #------------------------------------------------------
  
  subvillage <- keywords$subvillage[1:50]
  
  new_table <- dummygen(new_table, input_table, "subvillage", subvillage, "subvillage_")
  
  return(new_table)
}

#----------------------------------------------------------------------
# The data cleaning function is executed on the train and test dataset.
#----------------------------------------------------------------------

train <- data_munger(train, keywords)
test <- data_munger(test, keywords)

#-------------------------------------------------------------
# The clean tables are saved in the ./cleaned_dataset/ folder.
#-------------------------------------------------------------

write.csv(train, file = "./clean_dataset/train.csv", row.names = FALSE)
write.csv(test, file = "./clean_dataset/test.csv", row.names = FALSE)
