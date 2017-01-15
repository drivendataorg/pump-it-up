
#-----------------------------------------------------------------------
# Authors: Carlos Ortega, Santiago Mota, Pedro Concejero, Manuel Pérez
# Team: madRid
# LeaderBoard position: Second as of August 12th, 2016
#-----------------------------------------------------------------------

#----------------------------------------------------
# LIBRARIES
#----------------------------------------------------

library(lubridate)
library(stringr)
library(geosphere)
library(data.table)
library(Rborist)
library(MLmetrics)
library(caret)

#----------------------------------------------------
# TRAIN AND TEST SETS
#----------------------------------------------------
train_ori <- read.csv("../data/training_values.csv")
test_ori  <- read.csv("../data/test_values.csv")
train_sta <- read.csv("../data/training_labels.csv")

train_y <- train_sta$status_group
train_y_rec <- ifelse(train_y == "functional", 0, ifelse( train_y == "non functional", 1, 2))

all.equal(train_ori$id, train_sta$id)
train_ori <- cbind.data.frame(train_ori, status_group = train_sta$status_group)

all_df <- rbind.data.frame(train_ori[, 1:ncol(test_ori)] , test_ori)

#----------------------------------------------------
# FEATURE ENGINEERING
#----------------------------------------------------
all_df$fe_days <- as.numeric(as.Date("2014-01-01") - as.Date(all_df$date_recorded))
all_df$fe_mont <- month(ymd(all_df$date_recorded))
all_df$fe_dist <- distGeo(as.matrix(all_df[,c('longitude','latitude')]), c(0,0))

all_dt <- as.data.table(all_df)
col_fac <- names(all_dt)[mapply(class, all_dt) == "factor"]

for (i in 1:length(col_fac)) {
  all_dt[, paste(col_fac[i], 'hash', sep = '_') := as.numeric(.N), by = eval(col_fac[i])]
}

n_group <- 5
col_has <- names(all_dt)[ str_detect(names(all_dt), "hash")]
for (i in 1:length(col_has)) {
  all_dt[  get(col_has[i]) < n_group , c(col_has[i]) := -9999  ]
}

all_hash <- as.data.frame(all_dt)
col_fac <- names(all_hash)[mapply(class, all_hash) != "factor"]
all_god <- all_hash[, col_fac]

train_hash <- all_god[1:nrow(train_ori),]
test_hash  <- all_god[ (nrow(train_ori) + 1):nrow(all_god), ]

# ----------------------------------------------------
# # MODEL RBORIST
# ----------------------------------------------------

library(doMC)
numCor <- parallel::detectCores() - 2
registerDoMC(cores = numCor)

n_number <- 1
bootControl <- trainControl(number = n_number, verboseIter = TRUE)

n_mtry <- 5
rbGrid <- expand.grid(predFixed = n_mtry)

rn_v <- c(222222)
set.seed(rn_v)
no_trees <- 1000
n_node <- 1

modFitRbo <-  train(
  x           = train_hash,
  y           = train_y,
  trControl   = bootControl,
  tuneGrid    = rbGrid,
  method      = "Rborist",
  minNode     = n_node,
  nTree       = no_trees,
  minInfo     = 0.01,
  #predProb    = 0.30
)

modFitRbo
mod_perf <- getTrainPerf(modFitRbo)[, "TrainAccuracy"]

Imprf <- varImp( modFitRbo, scale = F)
plot(Imprf, top = (ncol(train_hash) - 1))
plot(Imprf, top = 20)

#--------------------------------------------------------
#-------------- FILE UPLOAD
#--------------------------------------------------------
preds <- predict(modFitRbo, test_hash)

submission <- data.frame(id = test_ori$id, status_group = preds)
cat("saving the submission file\n")

file_out <- c("file_upload_.csv")

write.csv(submission, file = file_out, row.names = F)

#*********************************************
#-------------- END OF PROGRAM
#*********************************************
