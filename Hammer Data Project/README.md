# PumpIt-DrivenData



This repository contains R and SAS code for the [Pump it Up: Data Mining the Water Table](http://www.drivendata.org/competitions/7/) competition on [Driven Data](http://www.drivendata.org) by Giorgio De Caro and Mauro Pelucchi.

The data is provided by [Taarifa](http://taarifa.org) and the [Tanzanian Ministry of Water](http://maji.go.tz).
The original goal is to predict whether a water pump is functional, functional but needs repairs or non functional.
During the [Master BI and Big Data Analytics](http://www.crisp-org.it/school/masters-courses/business-intelligence/)@University of Milano Bicocca, we have presented this work as project of Data Mining course: the target is to predict witch waterpoint is to repare (vs no-repare). 

For SAS we use SAS Base (for pre-processing) and SAS Miner.
In R, we use [H2O](http://h2o.ai)'s random forest to get a score 0.76. We also used a XGB. 

In the repository you can find:
* PumpIt_Presentation.pdf : the presentation of the final work with all details
* preprocessing_and_xgb.R : the R code for preprocessing and XGB model
* randomforest.r : the R code for H2O Random Forest
* preprocessing_binary.r : the R code for preprocessing and XGB model with binary target (to repare / no repare)
* randomforest_binary.r : the R code for H2O Random Forest with binary target (to repare / no repare)

The original file from drivendata.org:
* training_set.csv : the training set
* training_set_labels.csv : labels for training set
* test_set_values.csv : score set
* SubmissionFormat.csv : submission format from drivendata competition


For SAS:
* sas_code.sas : the SAS code for data exploration and preprocessing
* PumpIt2.zip : the SAS Miner Project

On CartoDB there are a lot of nice maps:
* [To repare / Total population maps](https://mauropelucchi.carto.com/viz/0911b77e-81aa-11e6-b45c-0e3ebc282e83/public_map)
* [No repare / Total population maps](https://mauropelucchi.carto.com/viz/7eb99b28-81a9-11e6-a2ad-0e3ff518bd15/public_map)
* [Odds ward vs to_repare waterpoint](https://mauropelucchi.carto.com/viz/2b6a4802-816b-11e6-ac02-0e3ebc282e83/embed_map)
* [Ward vs to_repare vs management_type (profit / no profit / user group)](https://mauropelucchi.carto.com/viz/10848868-8184-11e6-bc81-0e3ebc282e83/embed_map)
* [Outliers maps](https://mauropelucchi.carto.com/viz/8a53299a-819f-11e6-93aa-0e05a8b3e3d7/public_map)

And the final work (for binary classification model):
* [Maps to repare and no repare waterpoint](https://mauropelucchi.carto.com/viz/fc995c9a-8212-11e6-9e8e-0e3ff518bd15/public_map)

# License

This repository is released under the MIT license.

Copyright (c) Giorgio De Caro and Mauro Pelucchi

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
