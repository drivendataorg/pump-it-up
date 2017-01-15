library(xgboost)
library(plyr)
library(caret)
library(magrittr)

# Load data.
train <- "C:/Users/me/Documents/datasets/pump_train_for_models.csv"
train <- read.csv(train)

test <- "C:/Users/me/Documents/datasets/pump_test_for_models.csv"
test <- read.csv(test)

# Select target variable.
target <- as.numeric(train$status_group)
train$status_group <- NULL

# Convert to matrix.
train1 <- train %>% as.matrix
test1 <- test %>% as.matrix

# Set up grid search.

xgbGrid <- expand.grid(
  nrounds = c(100, 200),
  max_depth = c(2),
  eta = c(0.001),
  gamma = c(0, 1),
  colsample_bytree = c(0.5),
  min_child_weight = c(2)
)

xgbTrControl <- trainControl(
  method = "repeatedcv",
  number = 5,
  repeats = 2,
  verboseIter = FALSE,
  returnData = FALSE,
  allowParallel = TRUE
)

xgbTrain <- train(
  x = train1, 
  y = target,
  objective = 'multi:softmax',
  num_class = 3,
  trControl = xgbTrControl,
  tuneGrid = xgbGrid,
  method = 'xgbTree',
  eval_metric = 'merror'
)
        
best_params <- list('max.depth' = 2,
                    'eta' = 0.010,
                    'gamma' = 1,
                    'colsample_bytree' = 0.5,
                    'min_child_weight' = 2,
                    'objective' = "multi:softmax",
                    'num_class' = 3,
                    'eval_metric' = 'merror'
                    )

model <- xgboost(train1, target, params=best_params, nrounds=100)

pred <- predict(model, test1)

vals_to_replace = {2:'functional', 1:'functional needs repair',
  0:'non functional'}

test <- "C:/Users/me/Documents/datasets/pump_test.csv"
test <- read.csv(test)

submit <- data.frame(test$id, pred)
names(submit) <- c("test.id", "status_group")
submit$status_group[submit$status_group==2] <- 'functional'
submit$status_group[submit$status_group==1] <- 'functional needs repair'
submit$status_group[submit$status_group==0] <- 'non functional'

write.csv(submit, file = "pump_predictions.csv",row.names=FALSE)

# 0.6936


