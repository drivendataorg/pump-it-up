import xgboost
import pandas as pd
import numpy as np
from sklearn.grid_search import ParameterGrid
from sklearn.cross_validation import KFold
from sklearn.metrics import mean_squared_error
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
train = pd.DataFrame.from_csv('train_preprocessed_imp_height.csv')
train_index = train.index.values
test = pd.DataFrame.from_csv('test_preprocessed_imp_height.csv')
test_index = test.index.values

# combing tran and test data
# helps working on all the data and removes factorization problems between train and test
dataframe = pd.concat([train, test], axis=0)

"""
Preprocessing already done
"""

"""
Split into imputated train and test
"""
imp_col = 'amount_tsh'
imp_result_col = 'imp_tsh'
imp_val = 0
imp_train = dataframe.iloc[(dataframe[imp_col] != imp_val).values]
imp_train_index = imp_train.index.values
imp_test = dataframe.iloc[(dataframe[imp_col] == imp_val).values]
imp_test_index = imp_test.index.values

imp_y = imp_train[imp_col].values.flatten()
# Using log of amount makes sense
imp_y = np.log(imp_y)
print(imp_y)

del imp_train[imp_col]
del imp_test[imp_col]

print('There are %d samples' % imp_train.shape[0])
# Used parameters (not optimizing due to time limit)
early_stopping = 50
param_grid = [
              {
               'silent': [1],
               'nthread': [3],
               'eval_metric': ['rmse'],
               'eta': [0.1],
               'objective': ['reg:linear'],
               'max_depth': [6],
               # 'min_child_weight': [1],
               'num_round': [10000],
               'gamma': [0],
               'subsample': [0.75],
               'colsample_bytree': [0.75],
               'n_monte_carlo': [1],
               'cv_n': [5],
               'test_rounds_fac': [1.2],
               'count_n': [0],
               'mc_test': [True],
               }
              ]

print('start CV optimization')
meta_solvers_train = []
meta_solvers_test = []
mc_round_list = []
mc_rsme_mean = []
mc_rsme_sd = []
params_list = []
print_results = []
for params in ParameterGrid(param_grid):
    print(params)
    params_list.append(params)
    train_predictions = np.ones((imp_train.shape[0],))
    print('There are %d columns' % train.shape[1])

    # CV
    mc_rsme = []
    mc_round = []
    mc_train_pred = []
    # Use monte carlo simulation if needed to find small improvements
    for i_mc in range(params['n_monte_carlo']):
        cv_n = params['cv_n']
        kf = KFold(imp_train.shape[0], n_folds=cv_n, shuffle=True, random_state=i_mc ** 3)

        xgboost_rounds = []
        # Finding optimized number of rounds
        for cv_train_index, cv_test_index in kf:
            X_train, X_test = imp_train.values[cv_train_index, :], imp_train.values[cv_test_index, :]
            y_train = imp_y[cv_train_index]
            y_test = imp_y[cv_test_index]

            # train machine learning
            xg_train = xgboost.DMatrix(X_train, label=y_train)
            xg_test = xgboost.DMatrix(X_test, label=y_test)

            watchlist = [(xg_train, 'train'), (xg_test, 'test')]

            num_round = params['num_round']
            xgclassifier = xgboost.train(params, xg_train, num_round, watchlist, early_stopping_rounds=early_stopping);
            xgboost_rounds.append(xgclassifier.best_iteration)

        num_round = int(np.mean(xgboost_rounds))
        print('The best n_rounds is %d' % num_round)

        # Calculate train predictions over optimized number of rounds
        for cv_train_index, cv_test_index in kf:
            X_train, X_test = imp_train.values[cv_train_index, :], imp_train.values[cv_test_index, :]
            y_train = imp_y[cv_train_index]
            y_test = imp_y[cv_test_index]

            # train machine learning
            xg_train = xgboost.DMatrix(X_train, label=y_train)
            xg_test = xgboost.DMatrix(X_test, label=y_test)

            watchlist = [(xg_train, 'train'), (xg_test, 'test')]

            xgclassifier = xgboost.train(params, xg_train, num_round, watchlist);

            # predict
            predicted_results = xgclassifier.predict(xg_test)
            train_predictions[cv_test_index] = predicted_results

        print('RMSE score ', np.sqrt(mean_squared_error(imp_y, train_predictions)))
        mc_rsme.append(np.sqrt(mean_squared_error(imp_y, train_predictions)))
        mc_train_pred.append(train_predictions)
        mc_round.append(num_round)

    # Getting the mean integer
    mc_train_pred = (np.mean(np.array(mc_train_pred), axis=0))

    mc_round_list.append(int(np.mean(mc_round)))
    mc_rsme_mean.append(np.mean(mc_rsme))
    mc_rsme_sd.append(np.std(mc_rsme))
    print('The RMSE range is: %.5f to %.5f and best n_round: %d' %
          (mc_rsme_mean[-1] - mc_rsme_sd[-1], mc_rsme_mean[-1] + mc_rsme_sd[-1], mc_round_list[-1]))
    print_results.append('The AUC range is: %.5f to %.5f and best n_round: %d' %
                         (mc_rsme_mean[-1] - mc_rsme_sd[-1], mc_rsme_mean[-1] + mc_rsme_sd[-1], mc_round_list[-1]))
    print('For ', mc_rsme)
    print('The RMSE of the average prediction is: %.5f' % np.sqrt(mean_squared_error(imp_y, train_predictions)))
    meta_solvers_train.append(mc_train_pred)

    # predicting the test set
    if params['mc_test']:
        watchlist = [(xg_train, 'train')]
        num_round = int(mc_round_list[-1] * params['test_rounds_fac'])
        mc_pred = []
        for i_mc in range(params['n_monte_carlo']):
            params['seed'] = i_mc
            xg_train = xgboost.DMatrix(imp_train, label=imp_y)
            xg_test = xgboost.DMatrix(imp_test)

            watchlist = [(xg_train, 'train')]

            xgclassifier = xgboost.train(params, xg_train, num_round, watchlist);
            predicted_results = xgclassifier.predict(xg_test)
            mc_pred.append(predicted_results)

        meta_solvers_test.append(np.mean(np.array(mc_pred), axis=0))

        """
        added imputed results
        """
        imp_train[imp_col] = dataframe[imp_col].loc[imp_train_index].values
        imp_test[imp_col] = meta_solvers_test[-1]
        imp_train[imp_result_col] = np.zeros((imp_train.shape[0]))
        imp_test[imp_result_col] = np.ones((imp_test.shape[0]))

        imp_dataframe = pd.concat([imp_train, imp_test], axis=0)

        """
        Write imputated results
        """
        print(imp_dataframe)
        imp_dataframe.loc[train_index].to_csv('train_preprocessed_imp_height_tsh.csv')
        imp_dataframe.loc[test_index].to_csv("test_preprocessed_imp_height_tsh.csv")

print(params_list)
print(print_results)

# RSME of imputation: 0.43 (of log)
