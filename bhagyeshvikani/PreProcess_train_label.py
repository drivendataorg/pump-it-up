import pandas as pd
import numpy as np

train_label = pd.read_csv("Data/train_label.csv")

column_labels = list(train_label.columns.values)
column_labels.remove("id")

for i in column_labels:
	unique_value = train_label[i].unique()
	size = len(unique_value)
	print(size)
	for j in range(size):
		if unique_value[j] != "nan":
			train_label.loc[train_label[i] == unique_value[j], i] = j

train_label.to_csv("train_label.csv", index = False)