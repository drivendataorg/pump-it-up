library(zoo)
library(data.table)
library(FeatureHashing)
library(xgboost) # for extreme booster tree
library(dplyr)
library(Matrix)
library(h2o) # for random forest e deeplearning
library(glmnet) # for glm
library(smbinning) # for optimal binning of continous variable
library(ROCR)
library(caret)

#load data frame
train=fread('/Users/mauropelucchi/Desktop/Work/University/Master_BI_2016/Pump_it_waterpoint/pump_data/training_set.csv') %>% as.data.frame()
labels=fread('/Users/mauropelucchi/Desktop/Work/University/Master_BI_2016/Pump_it_waterpoint/pump_data/training_set_labels.csv') %>% as.data.frame()
test=fread('/Users/mauropelucchi/Desktop/Work/University/Master_BI_2016/Pump_it_waterpoint/pump_data/test_set_values.csv') %>% as.data.frame()






#merge data frame
d1 <- merge(train, labels, by = "id", all.x = T)
d2 <- test

d1$train <- 1
d2$status_group <- -1
d2$status_group_id <- -1
d2$train <- 0

#transorm covariate
d1$funder[d1$funder == 0] = NA;
d1$installer[d1$installer == 0] = NA;

d1$gps_height[d1$gps_height == 0] = 0;
d1$population[d1$population == 0] = 0;
d1$amount_tsh[d1$amount_tsh == 0] = 0;
d1$construction_year[d1$construction_year <= 0] = 0;
d1$construction_year[d1$construction_year <= 0]= median(d1$construction_year[d1$construction_year > 0])
d1$gps_height[d1$gps_height <= 0]= median(d1$gps_height[d1$gps_height > 0])
d1$population[d1$population <= 0]= median(d1$population[d1$population > 0])
d1$amount_tsh[d1$amount_tsh <= 0]= median(d1$amount_tsh[d1$amount_tsh > 0])


d2$funder[d2$funder == 0] = NA;
d2$installer[d2$installer == 0] = NA;

d2$gps_height[d2$gps_height == 0] = 0;
d2$population[d2$population == 0] = 0;
d2$amount_tsh[d2$amount_tsh == 0] = 0;
d2$construction_year[d2$construction_year == 0] = 0;
d2$construction_year[d2$construction_year <= 0]= median(d2$construction_year[d2$construction_year > 0])
d2$gps_height[d2$gps_height <= 0]= median(d2$gps_height[d2$gps_height > 0])
d2$population[d2$population <= 0]= median(d2$population[d2$population > 0])
d2$amount_tsh[d2$amount_tsh <= 0]= median(d2$amount_tsh[d2$amount_tsh > 0])


d1$latitude[d1$latitude > -1e-06] = NA;
d1$longitude[d1$longitude < -1e-06] = NA;

d2$latitude[d2$latitude > -1e-06] = NA;
d2$longitude[d2$longitude < -1e-06] = NA;

var = names(d1)
for (f in var) {
  if (class(d1[[f]])=="character") {
    d1[[f]] = tolower(d1[[f]])
    d2[[f]] = tolower(d2[[f]])
  }
 
}


# compute missing values ()
d1$funder[d1$funder == '']='missing funder'
d1$installer[d1$installer == '']='missing installer'

d2$funder[d2$funder == '']='missing funder'
d2$installer[d2$installer == '']='missing installer'

d1$status_group_id[d1$status_group == 'functional'] = 0;
d1$status_group_id[d1$status_group == 'non functional'] = 2;
d1$status_group_id[d1$status_group == 'functional needs repair'] = 1;

# remove duplicate variables
d1$date_recorded = NULL
d2$date_recorded = NULL
d1$wpt_name = NULL
d2$wpt_name = NULL
d1$num_private = NULL
d2$num_private = NULL
d1$quality_group = NULL
d2$quality_group = NULL
d1$region_code = NULL
d2$region_code = NULL
d1$district_code = NULL
d2$district_code = NULL
d1$recorded_by = NULL
d2$recorded_by = NULL
d1$scheme_name = NULL
d2$scheme_name = NULL
d1$extraction_type_group = NULL
d2$extraction_type_group = NULL
d1$payment = NULL
d2$payment = NULL
d1$quantity_group = NULL
d2$quantity_group = NULL
d1$management_group = NULL
d2$management_group = NULL
d1$source_type = NULL
d2$source_type = NULL
d1$waterpoint_type_group = NULL
d2$waterpoint_type_group = NULL


# remove duplicate
print(paste('Total number of cases:', nrow(d1)))
train2 = copy(d1)
train2$id <- NULL
d1 = d1[!duplicated(train2),]
print(paste('Total number of unique cases:', nrow(d1)))



# Features to transform - usually with large cardinality
features <- c('subvillage', 'funder', 'installer','ward')
#head(d1[, features], 20)
#head(d2[, features], 20)
# Mean of the status group with noise
n <- nrow(d1)
for (f in features){
  g <- paste0(f,"_","p")
  cat(f, "\n")
  status_group_mean <- tapply(d1$status_group_id, d1[[f]], mean)
  d2[[g]] <- status_group_mean[d2[[f]]]
  d1[[g]] <- status_group_mean[d1[[f]]]
  d1[[g]] <-  rnorm(n, 1, 0.01) * (d1[[g]] * n - d1$status_group_id) / (n - 1) 
}



#check data
head(d1, 10)

#undersampling ...
#d1_0 <- d1[d1$status_group == "functional", ]
#d1_1 <- d1[d1$status_group == "functional needs repair", ]
#d1_2 <- d1[d1$status_group == "non functional", ]
#ind_10 <- sample(nrow(d1_0), nrow(d1_1), replace = FALSE)
#d1_0 <- d1_0[ind_10, ]
#ind_12 <- sample(nrow(d1_2), nrow(d1_1), replace = FALSE)
#d1_2 <- d1_2[ind_12, ]
#d1s <- rbind(d1_0,d1_1,d1_2)

#check
#counts <- table(d1s$status_group)
#barplot(counts, main="Check sample",
#        xlab="Status group", col=c("green","blue", "red"),
#        legend = rownames(counts))

#n_valid = nrow(d1s) * 0.3;
#n_train = nrow(d1s) - n_valid;
#d1train_i = sample(nrow(d1s), n_train, replace=FALSE)
#d1valid_i = sample(nrow(d1s), n_valid, replace=FALSE)
#d1valid = d1s[d1valid_i, ]
#d1train = d1s[d1train_i, ]
#d1test = d2


n_valid = round(nrow(d1) * 0.4);
n_train = nrow(d1) - n_valid;
d1train_i = sample(nrow(d1), n_train, replace=FALSE)
d1train = d1[d1train_i, ]
d1valid = d1[-d1train_i, ]
d1test = d2


#####################################
# try extreme gradient booster
set.seed(456789)

Y <- d1train$status_group_id
V <- d1valid$status_group_id

d1train$status_group_id <- NULL
d1valid$status_group_id <- NULL
d1test$status_group_id <- NULL


D=rbind(d1train,d1valid,d1test)
D$i=1:dim(D)[1]
test_id=d1test$id

gc()


# show final dataset
head(D, n=10)

# REMOVE VARIBLES
D$longitude = NULL
D$latitude = NULL
D$subvillage = NULL
D$ward = NULL
D$status_group = NULL





# convert categorical covariate to numeric
char.cols=names(D)
for (f in char.cols) {
  if (class(D[[f]])=="character") {
    levels <- unique(c(D[[f]]))
    D[[f]] <- as.numeric(factor(D[[f]], levels=levels))
  }
  if (class(D[[f]])=="factor") {
    D[[f]] <- as.numeric(D[[f]])
  }
}

# show final dataset
head(D, n=10)

D.sparse=
  cBind(sparseMatrix(D$i,D$basin),
        sparseMatrix(D$i,D$region),
        sparseMatrix(D$i,D$lga),
        sparseMatrix(D$i,D$waterpoint_type),
        sparseMatrix(D$i,D$extraction_type),
        sparseMatrix(D$i,D$quantity),
        sparseMatrix(D$i,D$water_quality),
        sparseMatrix(D$i,D$source),
        #
        sparseMatrix(D$i,D$scheme_management),
        sparseMatrix(D$i,D$management),
        sparseMatrix(D$i,D$payment)
  )

D.sparse=
  cBind(D.sparse,
        D$population,
        D$subvillage_p,
        D$ward_p,
        
        D$construction_year,
        D$amount_tsh,
        D$gps_height,
        
        #
        D$funder_p,
        D$installer_p,
        #
        D$binay_sum)

train.sparse=D.sparse[1:n_train,]
valid.sparse=D.sparse[(n_train+1):(n_train+n_valid),]
test.sparse=D.sparse[(n_train+1+n_valid):nrow(D.sparse),]


# Hash train to sparse dmatrix X_train
dtrain <- xgb.DMatrix(train.sparse, label = Y)   
dvalid <- xgb.DMatrix(valid.sparse, label = V)   
dtest  <- xgb.DMatrix(test.sparse)

gc()
watch_list <- list(valid = dvalid, train = dtrain)



### Extreme Gradient Boosted Tree ####

param2 <- list(objective = "multi:softmax", 
               eval_metric = "merror",
               num_class = 3,
               "stratified"=T,
               booster = "gbtree", 
               eta = 0.1,
               subsample = 0.7, # subsample ratio of the training instance
               colsample_bytree = 0.7, # subsample ratio of columns 0.7
               #min_child_weight = 0,
               max_depth = 12 # maximum depth of a tree
               #sscale_pos_weight = 1 #for balanced dataset
)

tab = xgb.cv(data = dtrain, watchlist = watch_list, objective = "multi:softmax", booster = "gbtree",
                 nrounds = 10000, nfold = 10, early.stop.round = 10, 
                 num_class = 3, maximize = FALSE,
                 evaluation = "merror", eta = 0.2, 
                 max_depth = 12, colsample_bytree = 0.7)

#Create variable that identifies the optimal number of iterations for the model
min_error = which.min(tab[, test.merror.mean])

xgb_m2 <- xgb.train(data = dtrain,  
                    param2, nrounds = 10000,
                    watchlist = watch_list,
                    nfold = 10,
                    print_every_n = 100,
                    early.stop.round = 20,
                    maximize = FALSE,
                    save_name = "xgb_m2"
)

#0.7139

#calc confunsion matrix

valid.prd <- predict(xgb_m2, dvalid)
valid.out <- data.frame(id = d1valid$id, status_group_id = valid.prd)
valid.out$status_group[valid.out$status_group_id == 0] = "functional";
valid.out$status_group[valid.out$status_group_id == 2] = "non functional";
valid.out$status_group[valid.out$status_group_id == 1] = "functional needs repair";
valid.out$status_group_id = NULL
confusionMatrix(as.data.frame(valid.out)$status_group, as.data.frame(d1valid)$status_group)


# Predict
out <- predict(xgb_m2, dtest)
sub <- data.frame(id = d1test$id, status_group_id = out)
sub$status_group[sub$status_group_id == 0] = "functional";
sub$status_group[sub$status_group_id == 2] = "non functional";
sub$status_group[sub$status_group_id == 1] = "functional needs repair";
sub$status_group_id = NULL
write.csv(sub, file = "/Users/mauropelucchi/Desktop/Work/University/Master_BI_2016/Pump_it_waterpoint/sub_xgb_5.csv", row.names = F)



