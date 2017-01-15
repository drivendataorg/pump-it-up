import xgboost
import pandas as pd
import numpy as np
from sklearn.preprocessing import LabelEncoder
from sklearn.grid_search import ParameterGrid
from sklearn.cross_validation import StratifiedKFold
from sklearn.metrics import accuracy_score
import datetime


def date_parser(df):
    date_recorder = list(map(lambda x: datetime.datetime.strptime(str(x), '%Y-%m-%d'),
                             df['date_recorded'].values))
    df['year_recorder'] = list(map(lambda x: int(x.strftime('%Y')), date_recorder))
    df['weekday_recorder'] = list(map(lambda x: int(x.strftime('%w')), date_recorder))
    df['yearly_week_recorder'] = list(map(lambda x: int(x.strftime('%W')), date_recorder))
    df['month_recorder'] = list(map(lambda x: int(x.strftime('%m')), date_recorder))
    df['age'] = df['year_recorder'].values - df['construction_year'].values
    del df['date_recorded']
    return df

"""
Import data
"""
train = pd.DataFrame.from_csv('train.csv')
train_index = train.index.values
test = pd.DataFrame.from_csv('test.csv')
test_index = test.index.values

# combing tran and test data
# helps working on all the data and removes factorization problems between train and test
dataframe = pd.concat([train, test], axis=0)

train_labels = pd.DataFrame.from_csv('labels.csv')

submission_file = pd.DataFrame.from_csv("SubmissionFormat.csv")

"""
Preprocess
"""
# Change labels to ints in order to use as y vector
label_encoder = LabelEncoder()
train_labels.iloc[:, 0] = label_encoder.fit_transform(train_labels.values.flatten())

# Parse date (removing is the easiest)
dataframe = date_parser(dataframe)

# Factorize str columns
print(dataframe.columns.values)
num_cols = []
for col in dataframe.columns.values:
    if dataframe[col].dtype.name == 'object':
        print(dataframe[col].value_counts())
        dataframe[col] = dataframe[col].factorize()[0]
    else:
        num_cols.append(col)

# No need for normalizing in xgboost (using a factor of the derivative as a vector of convergence)

"""
Split into train and test
"""

train = dataframe.loc[train_index]
test = dataframe.loc[test_index]

"""
CV
"""
best_score = 0
best_params = 0
best_train_prediction = 0
best_prediction = 0
meta_solvers_train = []
meta_solvers_test = []
best_train = 0
best_test = 0

# Optimization parameters
early_stopping = 50
param_grid = [
              {
               'silent': [1],
               'nthread': [3],
               'eval_metric': ['mlogloss'],
               'eta': [0.1],
               'objective': ['multi:softmax'],
               'max_depth': [6],
               # 'min_child_weight': [1],
               'num_round': [1000],
               'gamma': [0],
               'subsample': [0.75],
               'colsample_bytree': [0.5],
               'n_monte_carlo': [1],
               'cv_n': [4],
               'test_rounds_fac': [1.2],
               'count_n': [0],
               'mc_test': [True],
               'num_class': [3]
               }
              ]

print('start CV optimization')
mc_round_list = []
mc_acc_mean = []
mc_acc_sd = []
params_list = []
print_results = []
for params in ParameterGrid(param_grid):
    print(params)
    params_list.append(params)
    train_predictions = np.ones((train.shape[0],))
    print('There are %d columns' % train.shape[1])

    # CV
    mc_auc = []
    mc_round = []
    mc_train_pred = []
    # Use monte carlo simulation if needed to find small improvements
    for i_mc in range(params['n_monte_carlo']):
        cv_n = params['cv_n']
        kf = StratifiedKFold(train_labels.values.flatten(), n_folds=cv_n, shuffle=True, random_state=i_mc ** 3)

        xgboost_rounds = []

        for cv_train_index, cv_test_index in kf:
            X_train, X_test = train.values[cv_train_index, :], train.values[cv_test_index, :]
            y_train = train_labels.iloc[cv_train_index].values.flatten()
            y_test = train_labels.iloc[cv_test_index].values.flatten()

            # train machine learning
            xg_train = xgboost.DMatrix(X_train, label=y_train)
            xg_test = xgboost.DMatrix(X_test, label=y_test)

            watchlist = [(xg_train, 'train'), (xg_test, 'test')]

            num_round = params['num_round']
            xgclassifier = xgboost.train(params, xg_train, num_round, watchlist,
                                         early_stopping_rounds=early_stopping
                                         );
            xgboost_rounds.append(xgclassifier.best_iteration)

        num_round = int(np.mean(xgboost_rounds))
        print('The best n_rounds is %d' % num_round)

        for cv_train_index, cv_test_index in kf:
            X_train, X_test = train.values[cv_train_index, :], train.values[cv_test_index, :]
            y_train = train_labels.iloc[cv_train_index].values.flatten()
            y_test = train_labels.iloc[cv_test_index].values.flatten()

            # train machine learning
            xg_train = xgboost.DMatrix(X_train, label=y_train)
            xg_test = xgboost.DMatrix(X_test, label=y_test)

            watchlist = [(xg_train, 'train'), (xg_test, 'test')]

            xgclassifier = xgboost.train(params, xg_train, num_round, watchlist);

            # predict
            predicted_results = xgclassifier.predict(xg_test)
            train_predictions[cv_test_index] = predicted_results

        print('AUC score ', accuracy_score(train_labels.values, train_predictions))
        mc_auc.append(accuracy_score(train_labels.values, train_predictions))
        mc_train_pred.append(train_predictions)
        mc_round.append(num_round)

    mc_train_pred = (np.mean(np.array(mc_train_pred), axis=0) + 0.5).astype(int)

    mc_round_list.append(int(np.mean(mc_round)))
    mc_acc_mean.append(np.mean(mc_auc))
    mc_acc_sd.append(np.std(mc_auc))
    print('The accuracy range is: %.5f to %.5f and best n_round: %d' %
          (mc_acc_mean[-1] - mc_acc_sd[-1], mc_acc_mean[-1] + mc_acc_sd[-1], mc_round_list[-1]))
    print_results.append('The AUC range is: %.5f to %.5f and best n_round: %d' %
                         (mc_acc_mean[-1] - mc_acc_sd[-1], mc_acc_mean[-1] + mc_acc_sd[-1], mc_round_list[-1]))
    print('For ', mc_auc)
    print('The accuracy of the average prediction is: %.5f' % accuracy_score(train_labels.values, mc_train_pred))
    meta_solvers_train.append(mc_train_pred)

    # train machine learning
    xg_train = xgboost.DMatrix(train.values, label=train_labels.values)
    xg_test = xgboost.DMatrix(test.values)

    if params['mc_test']:
        watchlist = [(xg_train, 'train')]

        num_round = int(mc_round_list[-1] * params['test_rounds_fac'])
        mc_pred = []
        for i_mc in range(params['n_monte_carlo']):
            params['seed'] = i_mc
            xg_train = xgboost.DMatrix(train, label=train_labels.values.flatten())
            xg_test = xgboost.DMatrix(test)

            watchlist = [(xg_train, 'train')]

            xgclassifier = xgboost.train(params, xg_train, num_round, watchlist);
            predicted_results = xgclassifier.predict(xg_test)
            mc_pred.append(predicted_results)

        meta_solvers_test.append((np.mean(np.array(mc_pred), axis=0) + 0.5).astype(int))
        """ Write opt solution """
        print('writing to file')
        mc_train_pred = label_encoder.inverse_transform(mc_train_pred.astype(int))
        print(meta_solvers_test[-1])
        meta_solvers_test[-1] = label_encoder.inverse_transform(meta_solvers_test[-1])
        pd.DataFrame(mc_train_pred).to_csv('results/train_xgboost_d6.csv')
        submission_file['status_group'] = meta_solvers_test[-1]
        submission_file.to_csv("results/test_xgboost_d6.csv")

    if mc_acc_mean[-1] < best_score:
        print('new best log loss')
        best_score = mc_acc_mean[-1]
        best_params = params
        best_train_prediction = mc_train_pred
        if params['mc_test']:
            best_prediction = meta_solvers_test[-1]

print(best_score)
print(best_params)

print(params_list)
print(print_results)
print(mc_acc_mean)
print(mc_acc_sd)
"""
Final Solution
"""
# optimazing:
# CV = 4, eta = 0.1
# Added measurement year, weekday, month, week of the year and age: 0.80591
# Optimizing Subsample and colsample_bytree:
