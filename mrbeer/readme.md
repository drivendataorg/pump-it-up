### Main features

1. Reading the data
2. Preprocessing:
    1. 2 stages of imputations. GPS_Height and then amount_tsh
    2. Recorded date parsing to year, weekday, week of the year, month, and age of well
    3. Labeling changed from strings to numbers (and back)
    4. Using frequency of the str variables with a lot of sparse factors
    5. Factorized str typed variables
3. Stratified cross validation
    1. Optimize hyper-parameters using custom accuracy function (xgboost doesn't have one)
    2. Finding best number of rounds
    3. Create Full prediction trainset
    4. Using n Monte Carlo experiments to find the standard deviation in the metric function
     and if neccesary measuring a small improvement.
4. Train the model on all the train data
5. Predict test results
6. Write results file
