# DrivenData-PumpItUp

This repository contains R code for the [Pump it Up: Data Mining the Water Table](http://www.drivendata.org/competitions/7/) competition on [Driven Data](http://www.drivendata.org).

The data is provided by [Taarifa](http://taarifa.org) and the [Tanzanian Ministry of Water](http://maji.go.tz). The goal is to predict whether a water pump is functional, functional but needs repairs or non functional.

I use [H2O](http://h2o.ai)'s random forest to get a score 0.821. I have uploaded my best (current) submission but not the data. Sign up at Driven Data to download the following files:

* `SubmissionFormat.csv`
* `Test set values.csv`
* `Training set labels.csv`
* `Training set values.csv`

## Read the data and do some preprocessing

The first step is to read the data and set some values to missing (`NA` in R): See `read-data.md`.

## Engineer features

The next step is to clean up the features (transform some, remove others) and possibly engineer some new features: See `transform-data.md`.

## Predict status with a random forest

Use a random forest to predict the functionality status of pumps in the test set: See `predict-data.md`.

### Update

Added a Makefile, which `spin`s the `R` scripts to produces the `md` files. See how to [Build a report based on an R script](http://yihui.name/knitr/demo/stitch/).
