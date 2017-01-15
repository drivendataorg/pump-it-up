library(xgboost)

#------------------------------------------------------------------------------------
# The cleaned train and labels are loaded in.
# The target is encoded as a numeric vector.
# The ID variable is dropped and the training set is transformed into a data matrix. 
#-------------------------------------------------------------------------------------

train <- read.csv("./clean_dataset/train.csv", stringsAsFactors = FALSE)
labels <- read.csv("./raw_dataset/target.csv", stringsAsFactors = FALSE)
  
target <- rep(0,nrow(train))
target[labels$status_group == "non functional"] <- 1
target[labels$status_group == "functional needs repair"] <- 2
  
train <- train[, -1] 
predictors <- data.matrix(train)
rm(train)

#-----------------------------------------------------------------------------------------------------------
# The parameters used in the grid searh are the depth, learning rate and the variable/observation sampling. 
# The cross-validation is used with 5 folds.
# Early stopping is based on the multi-class error rate.
# The results are dumped as csv files.
#-----------------------------------------------------------------------------------------------------------
  
depth <- c(21, 19, 17, 15, 13, 11, 9, 7, 5, 3)
eta <- c(20:2) / 100
subsample <- c(5:10) / 10
colsample <- c(5:10) / 10

for (d in depth){
  for (e in eta){
    for (s in subsample){
      for (c in colsample){
        
          bst_model <- xgb.cv(data = predictors,
                              nfold = 5,
                              early.stop.round = 30,
                              label = target,
                              num_class = 3,
                              max_depth = d,
                              eta = e,
                              nthread = 12,
                              subsample = s,
                              colsample_bytree = c,
                              min_child_weight = 1,
                              nrounds = 600, 
                              objective = "multi:softprob",
                              maximize = FALSE)
          
          write.csv(bst_model, file = paste0("./cross_validation/results_depth_", d, "_eta_", e, "_subsample_", s, "_colsample_", c, ".csv"), row.names = FALSE)
      }
    }
  }
}
