predictors = c("funder_p","installer_p","management",
               "region","lga","population",
               "latitude","longitude",
               "gps_height",
               "construction_year","amount_tsh",
               "scheme_management",
               "public_meeting","permit",
               "water_quality","quantity",
               "payment_type","source","source_class",
               "basin","extraction_type","waterpoint_type","subvillage_p",
               "ward_p"
)

target = "status_group_bin"
d2$status_group_bin <- '                                   '

h2o.init(nthreads = -1)
full_data <- rbind(d1, d2)
write.table(full_data[full_data$train==1,], gzfile('/Users/mauropelucchi/Desktop/Work/University/Master_BI_2016/Pump_it_waterpoint/transformed_train.csv.gz'),quote=F,sep=',',row.names=F)
write.table(full_data[full_data$train==0,], gzfile('/Users/mauropelucchi/Desktop/Work/University/Master_BI_2016/Pump_it_waterpoint/transformed_test.csv.gz'),quote=F,sep=',',row.names=F)
write.table(d1valid, gzfile('/Users/mauropelucchi/Desktop/Work/University/Master_BI_2016/Pump_it_waterpoint/transformed_valid.csv.gz'),quote=F,sep=',',row.names=F)

train.hex <- h2o.uploadFile('/Users/mauropelucchi/Desktop/Work/University/Master_BI_2016/Pump_it_waterpoint/transformed_train.csv.gz', destination_frame='p_ex_train')
test.hex <- h2o.uploadFile('/Users/mauropelucchi/Desktop/Work/University/Master_BI_2016/Pump_it_waterpoint/transformed_test.csv.gz', destination_frame='p_ex_test')
valid.hex <- h2o.uploadFile('/Users/mauropelucchi/Desktop/Work/University/Master_BI_2016/Pump_it_waterpoint/transformed_valid.csv.gz', destination_frame='p_ex_valid')



rfHex = h2o.randomForest(
  x = predictors,
  y = target,
  training_frame = train.hex,
  model_id = "rf_1",
  ntrees = 1000, mtries = 15,
  seed = 45678)



#+
h2o.confusionMatrix(rfHex)

out = as.data.frame(h2o.predict(rfHex,valid.hex))[,1]
sub <- data.frame(id = d2$id, status_group= out)
write.csv(sub, file = "/Users/mauropelucchi/Desktop/Work/University/Master_BI_2016/Pump_it_waterpoint/sub_rf2.csv", row.names = F)
