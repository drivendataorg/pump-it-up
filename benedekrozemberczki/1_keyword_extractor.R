#---------------------------------------------------------------------------------------------
# The train dataset has a large number of string variables that are not uniformly distributed.
#---------------------------------------------------------------------------------------------

train <- read.csv("./raw_dataset/train.csv", stringsAsFactors = FALSE)

#------------------------------------------------------------------------------------------------
# The 100 most common values of string variables are extracted.
# If the variable has fewer unique values than 100 the remaining elements of the vector are NAs.
#------------------------------------------------------------------------------------------------

unique_values_1 <- sort(table(train$installer), decreasing = TRUE)[1:100]
unique_values_2 <- sort(table(train$lga), decreasing = TRUE)[1:100]
unique_values_3 <- sort(table(train$scheme_name), decreasing = TRUE)[1:100]
unique_values_4 <- sort(table(train$funder), decreasing = TRUE)[1:100]
unique_values_5 <- sort(table(train$wpt_name), decreasing = TRUE)[1:100]
unique_values_6 <- sort(table(train$ward), decreasing = TRUE)[1:100]
unique_values_7 <- sort(table(train$date_recorded), decreasing = TRUE)[1:100]
unique_values_8 <- sort(table(train$subvillage), decreasing = TRUE)[1:100]
unique_values_9 <- sort(table(train$region), decreasing = TRUE)[1:100]
unique_values_10 <- sort(table(train$scheme_management), decreasing = TRUE)[1:100]
unique_values_11 <- sort(table(train$extraction_type), decreasing = TRUE)[1:100]

#-----------------------------------------------
# The vectors are concatenated into a dataframe.
#-----------------------------------------------

keywords <- data.frame(names(unique_values_1),
                       names(unique_values_2),
                       names(unique_values_3),
                       names(unique_values_4),
                       names(unique_values_5),
                       names(unique_values_6),
                       names(unique_values_7),
                       names(unique_values_8),
                       names(unique_values_9),
                       names(unique_values_10),
                       names(unique_values_11),                       
                       stringsAsFactors = FALSE)

#---------------------------------------------------
# The columns are named after the original variable.
#---------------------------------------------------

colnames(keywords) <- c("installer",
                        "lga",
                        "scheme_name",
                        "funder",
                        "wpt_name",
                        "ward",
                        "date_recorded",
                        "subvillage",
                        "region",
                        "scheme_management",
                        "extraction_type")

#-------------------------------------------------------
# The dataframe is saved for the data cleaning process.
#-------------------------------------------------------

write.csv(keywords, "./clean_dataset/keywords.csv", row.names = FALSE)
