import pandas as pd

train_value = pd.read_csv("train_value.csv")
train_label = pd.read_csv("train_label.csv")
test = pd.read_csv("test.csv")

train_data = train_value.merge(train_label, how = "outer", on = "id", sort = True)
train_data = train_data.fillna(train_data.median())

train_data.to_csv("train_data.csv", index = False)