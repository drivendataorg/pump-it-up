import gc
import pandas as pd
import numpy as np
from sklearn import tree
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import accuracy_score

###Training part###
# Traning data
train = pd.read_csv("train_data.csv")
print("Traning data: successfully")

# Features for trainig
# column_labels = ['installer', 'latitude', 'wpt_name', 'num_private', 'basin', 'subvillage', 'district_code', 'lga', 'population', 'scheme_name', 'extraction_type_class', 'management_group', 'source_type']
# status_group = ["functional", "non functional", "functional needs repair"]
# print("Features for trainig: successfully")
column_labels = list(train.columns.values)
column_labels.remove("id")
column_labels.remove("date_recorded")
column_labels.remove("status_group")
status_group = ["functional", "non functional", "functional needs repair"]
print("Features for trainig: successfully")

train = train.iloc[np.random.permutation(len(train))]

# Assign data for validation
amount = int(0.8*len(train))
validation = train[amount:]
# train = train[:amount]
print("Assign data for validation: successfully")

# Classifier
# clf = tree.DecisionTreeClassifier()
clf = RandomForestClassifier(n_estimators = 200, n_jobs = -1)
print("Classifier: successfully")

# Traning
clf.fit(train[column_labels], train["status_group"])
print("Traning: successfully")

# Accuracy
accuracy = accuracy_score(clf.predict(validation[column_labels]), validation["status_group"])
print("Accuracy = " + str(accuracy))
print("Accuracy: successfully")


# Free some ram
del train, validation
gc.collect()


###Testing part###
# Testing data
test = pd.read_csv("test.csv")
test = test.fillna(test.median())
print("Testing data: successfully")

# Prediction for test data
prediction = clf.predict(test[column_labels])
print("Prediction for test data: successfully")


### Making submission file###
# Dataframe as per submission format
submission = pd.DataFrame({
			"id": test["id"],
			"status_group": prediction
		})
for i in range(len(status_group)):
	submission.loc[submission["status_group"] == i, "status_group"] = status_group[i]
print("Dataframe as per submission format: successfully")

# Store submission dataframe into file
submission.to_csv("submission.csv", index = False)
print("Store submission dataframe into file: successfully")