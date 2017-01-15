
#' # Random forest with H2O

#+ global_options, include=FALSE
library(knitr)
opts_chunk$set(
	fig.width=8, fig.height=7, fig.path='Figures/',
	echo = TRUE, warning = FALSE, message = FALSE)

#+ , results = 'hide', fig.show = 'hide'
source("transform-data.R")

#' [H2O](http://h2o.ai) is an open-source, fast, scalable and all around wonderful platform for machine learning. It is Java-based but it has an R interface which I use for the Pump it Up competition. (The [caret](http://topepo.github.io/caret/index.html) package is great as well and it contains more models for prediction.)
#' 
#' First install the H2O package by following the instructions for R users in the [H2O documentation](http://docs.h2o.ai). Then start an H2O instance.

#+ , results = 'hide'
library(h2o)
localH2O = h2o.init()

#' Define the set of predictors (all features retained after the data cleaning/engineering phase) and the response to predict.

#+
predictors = c("funder","installer","management",
               "region","lga","population",
               "latitude","longitude","gps_height",
               "scheme_management",
               "public_meeting","permit",
               "water_quality","quantity",
               "payment_type","source","source_class",
               "management","management_group",
               "basin","extraction_type","waterpoint_type",
               "day_of_year","season","operation_years")
target = "status_group"

#' Transform the training and the test sets into H2O data objects called H2O Frames.

#+ , results = 'hide'
trainHex = as.h2o(train, destination_frame = "train.hex")
testHex = as.h2o(test, destination_frame = "test.hex")

#' Train a random forest with 1000 trees. The `mtries` parameter specifies how many variables are sampled as candidates at each split.

#+ , results = 'hide'
rfHex = h2o.randomForest(
  x = predictors,
  y = target,
  training_frame = trainHex,
  model_id = "rf_ntrees1000",
  ntrees = 1000, mtries = 10,
  seed = 123456) ## Set the seed for reproducibility of results

#' The confusion matrix characterizes how well the fitted model predicts the training data. 

#+
h2o.confusionMatrix(rfHex)

#' The classes are quite imbalanced and the random forest predicts the largest class, functional, with the highest accuracy and the smallest class, needs repair, with almost 70% error.
#'
#' If the model is overfitted, the performance might not generalize to the test set. Cross validation can help to avoid this problem. (Use the `nfolds` option in `h2o.randomForest`.)
#'
#' Make predictions for the test data. `h2o.predict` returns both the most likely class and the the probability for belonging to each class. A submission for the Pump it Up challenge needs only the predicted class, in the first column.

#+
predictions = as.data.frame(h2o.predict(rfHex,testHex))[,1]

#' Finally, save the predictions in the required format as a csv file.

#+
submission = tbl_dt(fread("data/SubmissionFormat.csv")) %>%
  mutate(status_group = predictions)
write.csv(submission,row.names = FALSE,quote = FALSE,
          file = "submission-h2o_randomForest-ntrees1000.csv")

#' `h2o.randomForest` is just one of the available algorithms. Other machine learning methods to experiment with are `h2o.gbm`, `h2o.deeplearning` or `h2o.naiveBayes`. 
