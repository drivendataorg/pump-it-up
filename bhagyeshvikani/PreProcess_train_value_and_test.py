import pandas as pd
import numpy as np

train_value = pd.read_csv("Data/train_value.csv")
test = pd.read_csv("Data/test.csv")

column_labels = list(train_value.columns.values)
column_labels.remove("id")
column_labels.remove("amount_tsh")
column_labels.remove("date_recorded")
column_labels.remove("gps_height")
column_labels.remove("longitude")
column_labels.remove("latitude")
column_labels.remove("num_private")
column_labels.remove("region_code")
column_labels.remove("district_code")
column_labels.remove("population")
column_labels.remove("construction_year")

test = test.fillna(test.median())

for i in column_labels:
	unique_value = list(set(np.concatenate((train_value[i].unique() , test[i].unique()))))
	size = len(unique_value)
	print(size)
	for j in range(size):
		if unique_value[j] != "nan":
			# train_value.loc[train_value[i] == unique_value[j], i] = j
			test.loc[test[i] == unique_value[j], i] = j

# train_value = train_value.fillna(train_value.median())
test = test.fillna(test.median())

# train_value.to_csv("train_value.csv", index = False)
test.to_csv("test.csv", index = False)