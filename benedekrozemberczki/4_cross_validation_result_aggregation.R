#---------------------------------------------------------------------------------
# The cross validation results are in different comma separated values files.
# The results can be aggregated into a data frame, where results can be compared.
#---------------------------------------------------------------------------------

cross_validation <- list.files("./cross_validation/")
cross_valitation_aggregated_results <- data.frame(matrix(0, length(cross_validation), 6))
colnames(cross_valitation_aggregated_results) <- c("depth",
                                                   "eta",
                                                   "subsample",
                                                   "colsample",
                                                   "nrounds",
                                                   "error_rate")
                                                   

#---------------------------------------------------------------------------------------------------------
# The table contains the number of trees, depth, eta, the column and row sample ratio and the test error.
#---------------------------------------------------------------------------------------------------------

i <- 0
for (c in cross_validation){
  i <- i + 1
  cross_validation_results <- read.csv(paste0("./cross_validation/", c), stringsAsFactors = FALSE)
  depth <- strsplit(c, "_")[[1]][3]
  eta <- strsplit(c, "_")[[1]][5]
  subsample <- strsplit(c, "_")[[1]][7]
  colsample <- strsplit(strsplit(c, "_")[[1]][9], ".")[[1]][1]
  nrounds <- nrow(cross_validation_results) - 30
  error_rate <- min(cross_validation_results$test.merror.mean)
  cross_valitation_aggregated_results[i,] <- c(depth, eta, subsample, colsample, nrounds, error_rate)
}

write.csv(cross_valitation_aggregated_results, file = "cross_valitation_aggregated_results.csv", row.names = FALSE)
