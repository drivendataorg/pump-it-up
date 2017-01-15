predictions <- list.files("./predictions/")

#------------------------------------------------------------
# The predictions are averaged for the class - observations.
#------------------------------------------------------------

i <- 0
for (p in predictions){

  i <- i + 1
  single_prediction <-  read.csv(paste0("./predictions/", p), stringsAsFactors = FALSE)
  
  if (i == 1){
    aggregated_prediction <- single_prediction
  }
  else{
    aggregated_prediction[, 2:4] <- aggregated_prediction[, 2:4] + single_prediction[, 2:4]
  }
  
}

aggregated_prediction[, 2:4] <- aggregated_prediction[, 2:4] / 30

#--------------------------------------------------------------------
# The labels with highest probability are chosen as predictions.
# The label is transformed back, the target and ID are concatenated.
# The submission file is dumped.
#--------------------------------------------------------------------

target <- colnames(aggregated_prediction[, 2:4])[apply(aggregated_prediction[, 2:4], 1, which.max)]
target[target == "non.functional"] <- "non functional"
target[target == "functional.needs.repair"] <- "functional needs repair"

submission <- data.frame(aggregated_prediction[, 1], target)

colnames(submission) <- c("id", "status_group")

write.csv(submission, "submission.csv", row.names = FALSE)
