
#Driven data water pumps in Tanzania challenge
#Using Random forest for classification
#github: https://github.com/aratikrishna/Waterpump

#what all does this code involve?
#-feature engineering
#-missing value imputation using averages, logical assumptions, decision trees
#-cutting the tails of continuous variables
#-dropping levels of categorical variables
#-random forest
#-ggplot to visualize feature effects on dependent variables

################################################################
#INITIAL PREP
setwd("~/analytics/waterpump")

#clear the environment
rm(list=ls())

#load libraries
install.packages("dplyr")
install.packages("randomForest")
install.packages("rpart")
install.packages("ggplot2")

library(dplyr)
library(randomForest)
library(rpart)
library(ggplot2)


#set seed
set.seed(42)

#########################################################################################
#IMPORT DATA

# Define train_values_url
train_values_url <- "http://s3.amazonaws.com/drivendata/data/7/public/4910797b-ee55-40a7-8668-10efd5c1b960.csv"

# Import train_values

train_values <- read.csv(train_values_url)

# Define train_labels_url
train_labels_url <- "http://s3.amazonaws.com/drivendata/data/7/public/0bf8bc6e-30d0-4c50-956a-603fc693d966.csv"

# Import train_labels
train_labels <- read.csv(train_labels_url)

# Define test_values_url
test_values_url <- "http://s3.amazonaws.com/drivendata/data/7/public/702ddfc5-68cd-4d1d-a0de-f5f566f76d91.csv"

# Import test_values
test_values <- read.csv(test_values_url)

# Merge data frames to create the data frame train
train <- merge(train_labels, train_values)
test <- test_values
rm(train_labels)  
rm(train_values)
rm(test_values)
rm(train_labels_url)
rm(train_values_url)
rm(test_values_url)

# Look at the number of pumps in each functional status group
table(train$status_group)

# As proportions
prop.table(table(train$status_group))
################################################################################
############################################################################
#EXPLORE AND VISUALIZE

# Create bar plot for quantity
qplot(quantity, data=train, geom="bar", fill=status_group) + 
  theme(legend.position = "top")
qplot(status_group, data=train, geom="bar", fill=quantity) + 
  theme(legend.position = "top")


# Create bar plot for quality_group
qplot(quality_group, data=train, geom="bar", fill=status_group) + 
  theme(legend.position = "top")

# Create bar plot for waterpoint_type
qplot(waterpoint_type, data=train, geom="bar", fill=status_group) + 
  theme(legend.position = "top") + 
  theme(axis.text.x=element_text(angle = -20, hjust = 0))
#################################################################################
#CONTINUOUS VARIABLE VISUALIZATION

# Create a histogram for `construction_year` grouped by `status_group`
ggplot(train, aes(x = construction_year)) + 
  geom_histogram(bins = 20) + 
  facet_grid( ~ status_group)

# Now subsetting when construction_year is larger than 0
ggplot(subset(train, construction_year > 0), aes(x =construction_year)) +
  geom_histogram(bins = 20) + 
  facet_grid( ~ status_group)
#############################################################################



#ADDING FEATURES

test$status_group<-""

all<- rbind(train,test)
write.csv(all, file ="waterpumpsall.csv", row.names = FALSE)

#looking at a map of tanzania, values should be in the following range
#latitude slightly less than 0 upto -15
#longitude slightly more than 30 to slightly more than 40

summary(all$latitude)
hist(all$latitude)
length(all$latitude[all$latitude>=0])
length(all$latitude[all$latitude>=-1])

summary(all$longitude)
hist(all$longitude)
nrow(all[all$longitude==0,])

#so latitude is ok.
#longitude = 0 is probably missing values

longsummary <- aggregate(longitude~region,data=all[(all$longitude!=0),], FUN=mean)
str(longsummary)
print(longsummary)

#meanlong <- mean(all$longitude[all$longitude!=0])
#meanlong

all$finallongitude<-all$longitude
nrow(all[all$finallongitude==0,])

all$finallongitude[all$region=="Arusha" & all$longitude==0] <- 36.55407
all$finallongitude[all$region=="Dar es Salaam" & all$longitude==0] <- 39.21294
all$finallongitude[all$region=="Dodoma" & all$longitude==0] <- 36.04196
all$finallongitude[all$region=="Iringa" & all$longitude==0] <- 34.89592
all$finallongitude[all$region=="Kagera" & all$longitude==0] <- 31.23309
all$finallongitude[all$region=="Kigoma" & all$longitude==0] <- 30.21889
all$finallongitude[all$region=="Kilimanjaro" & all$longitude==0] <- 37.50546
all$finallongitude[all$region=="Lindi" & all$longitude==0] <- 38.98799
all$finallongitude[all$region=="Manyara" & all$longitude==0] <- 35.92932
all$finallongitude[all$region=="Mara" & all$longitude==0] <- 34.15698
all$finallongitude[all$region=="Mbeya" & all$longitude==0] <- 33.53351
all$finallongitude[all$region=="Morogoro" & all$longitude==0] <- 37.04678
all$finallongitude[all$region=="Mtwara" & all$longitude==0] <- 39.38862
all$finallongitude[all$region=="Mwanza" & all$longitude==0] <- 33.09477
all$finallongitude[all$region=="Pwani" & all$longitude==0] <- 38.88372
all$finallongitude[all$region=="Rukwa" & all$longitude==0] <- 31.29116
all$finallongitude[all$region=="Ruvuma" & all$longitude==0] <- 35.72784
all$finallongitude[all$region=="Shinyanga" & all$longitude==0] <- 33.24037
all$finallongitude[all$region=="Singida" & all$longitude==0] <- 373950
all$finallongitude[all$region=="Tabora" & all$longitude==0] <- 32.87830
all$finallongitude[all$region=="Tanga" & all$longitude==0] <- 38.50195

nrow(all[all$finallongitude==0,])

hist(all$longitude)
hist(all$finallongitude)

summary(all$amount_tsh)
summary(all$amount_tsh[all$amount_tsh>0])

hist(all$amount_tsh)
hist(all$amount_tsh[all$amount_tsh>10000
#                    & all$amount_tsh<100000
                    ])
table(all$status_group[all$amount_tsh>10000],all$amount_tsh[all$amount_tsh>10000])
#amount_tsh>10000 does not seem to be indicative of status group. 
#collapse all to 10000
all$amount_tsh[all$amount_tsh>=10000]<- 10000
hist(all$amount_tsh)
hist(all$amount_tsh[all$amount_tsh>5000
                    ])

nrow(all[all$amount_tsh==0,])
#52049 rows of all have amount_tsh 0; so set a flag for these rows
nrow(train[train$amount_tsh==0,])
nrow(test[test$amount_tsh==0,])

all$tsh0flag <- 0
all$tsh0flag[all$amount_tsh==0]<-1
table(all$tsh0flag)

#same for gps_height

all$gps0flag <- 0
all$gps0flag[all$gps_height==0]<-1
table(all$gps0flag)

hist(all$gps_height)
summary(all$gps_height)
nrow(all[all$gps_height==0,])
#25649 rows of all have gps_height 0; so set a flag for these rows
nrow(all[all$gps_height<=0,])
summary(all$gps_height[all$gps_height<=0])
hist(all$gps_height[all$gps_height<0])

#using a decision tree to fill missing gps_height values
gpsFit <- rpart(gps_height ~ latitude+finallongitude
                , data=all[(all$gps_height!=0),]
                , method="anova")
all$gps_height[all$gps0flag==1] <- predict(gpsFit,all[(all$gps0flag==1),])
summary(all$gps_height)
hist(all$gps_height)
hist(all$gps_height[all$gps0flag ==1])

#population = 0 or 1 flag
hist(all$population)
all$pop01flag <- 0
all$pop01flag[all$population ==0]<-1
table(all$pop01flag)
all$population[all$population==0]<- round(mean(all$population[all$population!=0]),digits = 0)
hist(all$population)
table(all$population)
table(all$status_group[all$population>5000],all$population[all$population>5000])
#population>10000 does not seem to be indicative of status group. 
#collapse all to 10000
all$population[all$population>5000]<-5000

all$age<- max(all$construction_year)-all$construction_year
table(all$age)

all$year0flag<-0
all$year0flag[all$age==max(all$construction_year)]<-1
table(all$age)
table(all$year0flag)
all$age[all$age==max(all$construction_year)]<- round(mean(all$age[all$age!=max(all$construction_year)]),digits = 0)
table(all$age)
hist(all$age)

#cannot have missing values for random forest
table(all$permit)
all$permit<- as.character(all$permit)
all$permit[all$permit==""]<-"unknown"
all$permit<-as.factor(all$permit)
table(all$permit)
table(all$scheme_management)
all$scheme_management<- as.character(all$scheme_management)
all$scheme_management[all$scheme_management==""]<-"unknown"
all$scheme_management<-as.factor(all$scheme_management)
table(all$scheme_management)
table(all$public_meeting)
all$public_meeting<- as.character(all$public_meeting)
all$public_meeting[all$public_meeting==""]<-"unknown"
all$public_meeting<-as.factor(all$public_meeting)
table(all$public_meeting)

#reduce factor levels if the proportion of a factor level is very small
prop.table((table(all$extraction_type_class)))
all$extraction_type_class[all$extraction_type_class=="rope pump"] <- "other"
all$extraction_type_class[all$extraction_type_class=="wind-powered"] <- "other"
all$extraction_type_class<-droplevels(all$extraction_type_class)
prop.table((table(all$extraction_type_class)))

prop.table(table(all$waterpoint_type_group))
all$waterpoint_type_group[all$waterpoint_type_group=="cattle trough"] <- "other"
all$waterpoint_type_group[all$waterpoint_type_group=="dam"] <- "other"
all$waterpoint_type_group[all$waterpoint_type_group=="improved spring"] <- "other"
all$waterpoint_type_group<-droplevels(all$waterpoint_type_group)
prop.table((table(all$waterpoint_type_group)))

prop.table(table(all$scheme_management))
all$scheme_management[all$scheme_management=="None"]<-"Other"
all$scheme_management[all$scheme_management=="SWC"]<-"Other"
all$scheme_management[all$scheme_management=="Trust"]<-"Other"
all$scheme_management[all$scheme_management=="unknown"]<-"Other"
all$scheme_management<-droplevels(all$scheme_management)
prop.table(table(all$scheme_management))

#########################################################################
#PREPARE DATA
end_train <- nrow(train)
end <- nrow(all)

rm(train)
rm(test)

trainm <- all[1:end_train, c(
  "id"
  ,"region"
  ,"amount_tsh"
  ,"tsh0flag"
  #,"date_recorded" 
  # ,"funder"
  ,"gps_height"
  ,"gps0flag"
  #  ,"installer"
  ,"finallongitude"
  #,"longitude"
  ,"latitude"           
  ,"basin"          
  #,"region_code"         
  #,"district_code"
  #,"lga"
  #,"ward"                 
  ,"population"
  ,"pop01flag"
  ,"public_meeting"
  ,"scheme_management"
  #,"scheme_name"
  ,"permit"   
  #,"construction_year"
  ,"age"
  ,"year0flag"
  #,"extraction_type" 
  #,"extraction_type_group"
  ,"extraction_type_class"
  #,"management"
  ,"management_group"
  #,"payment"
  #,"payment_type"
  #,"water_quality"        
  ,"quality_group"        
  #,"quantity"           
  ,"quantity_group"       
  #,"source"
  ,"source_type"         
  ,"source_class"         
  #,"waterpoint_type"
  
  ,"waterpoint_type_group"
  ,"status_group"
)
]


testm <- all[(end_train+1):end, c(
  "id"
  ,"region"
  ,"amount_tsh"
  ,"tsh0flag"
  #,"date_recorded" 
  # ,"funder"
  ,"gps_height"
  ,"gps0flag"
  #  ,"installer"
  ,"finallongitude"
  #,"longitude"
  ,"latitude"           
  ,"basin"          
  #,"region_code"         
  #,"district_code"
  #,"lga"
  #,"ward"                 
  ,"population"
  ,"pop01flag"
  ,"public_meeting"
  ,"scheme_management"
  #,"scheme_name"
  ,"permit"   
  #,"construction_year"
  ,"age"
  ,"year0flag"
  #,"extraction_type" 
  #,"extraction_type_group"
  ,"extraction_type_class"
  #,"management"
  ,"management_group"
  #,"payment"
  #,"payment_type"
  #,"water_quality"        
  ,"quality_group"        
  #,"quantity"           
  ,"quantity_group"       
  #,"source"
  ,"source_type"         
  ,"source_class"         
  #,"waterpoint_type"
  
  ,"waterpoint_type_group"
  ,"status_group"
)
]


str(all$status_group)
str(trainm$status_group)
str(testm$status_group)

table(all$status_group)
table(trainm$status_group)
table(testm$status_group)

trainm$status_group<-droplevels(trainm$status_group)
table(trainm$status_group)
##############################################################################
#MODELING

ntrees <- 300


#remove these variables as first model run shows they are not important
#                             +tsh0flag
#                            +gps0flag
#                            +pop01flag
#                            +public_meeting
#                            +permit   
#                            +year0flag
#                            +management_group
#                            +quality_group        

#second model run has these as least important
#source_type
#basin
#scheme_management

#region can be removed as finallongitude and latitude come out as 2nd and 3rd important and they are subsitutes for region

model_forest <- randomForest(as.factor(status_group) 
                             ~ 
                               #id
#                               region
                             +amount_tsh
#                             +tsh0flag
                             #+date_recorded 
                             # +funder
                             +gps_height
#                            +gps0flag
                             #  +installer
                             +finallongitude
                             #+longitude
                             +latitude           
#                             +basin          
                             #+region_code         
                             #+district_code
                             #+lga
                             #+ward                 
                             +population
#                            +pop01flag
#                            +public_meeting
#                             +scheme_management
                             #+scheme_name
#                            +permit   
                             #+construction_year
                             +age
#                            +year0flag
                             #+extraction_type 
                             #+extraction_type_group
                             +extraction_type_class
                             #+management
#                            +management_group
                             #+payment
                             #+payment_type
                             #+water_quality        
#                            +quality_group        
                             #+quantity           
                             +quantity_group       
                             #+source
#                            +source_type         
#                             +source_class         
                             #+waterpoint_type
                             
                             +waterpoint_type_group
                             
                             ,data = trainm
                             ,importance = TRUE
                             ,ntree = ntrees
                             ,nodesize = 5
)

#exploring the model
importance(model_forest)
varImpPlot(model_forest)
plot(model_forest)
print(model_forest)

table(all$status_group,all$quantity_group)

# Create bar plot for categorical variables
qplot(quantity_group, data=trainm, geom="bar", fill=status_group) + 
  theme(legend.position = "top")

qplot(status_group, data=trainm, geom="bar", fill=quantity_group) + 
  theme(legend.position = "top")

qplot(waterpoint_type_group, data=trainm, geom="bar", fill=status_group) + 
  theme(legend.position = "top")

qplot(extraction_type_class, data=trainm, geom="bar", fill=status_group) + 
  theme(legend.position = "top") 
+ theme(axis.text.x=element_text(angle = -20, hjust = 0))

# Create a histograms for continuous variables
ggplot(trainm, aes(x = finallongitude)) + 
  geom_histogram(bins = 20) +   facet_grid( ~ status_group)

ggplot(trainm, aes(x = latitude)) + 
  geom_histogram(bins = 20) +   facet_grid( ~ status_group)

ggplot(trainm, aes(x = latitude)) + 
  geom_histogram(bins = 20) +   facet_grid( ~ status_group)

ggplot(trainm, aes(x = gps_height)) + 
  geom_histogram(bins = 20) +   facet_grid( ~ status_group)
ggplot(trainm, aes(x = age)) + 
  geom_histogram(bins = 20) +   facet_grid( ~ status_group)
ggplot(trainm, aes(x = population)) + 
  geom_histogram(bins = 20) +   facet_grid( ~ status_group)
ggplot(trainm, aes(x = amount_tsh)) + 
  geom_histogram(bins = 10) +   facet_grid( ~ status_group)


pred_forest_train<- predict(model_forest,trainm)
table(trainm$status_group,pred_forest_train)


pred_forest_test<- predict(model_forest,testm)
submissionForest<-data.frame(testm$id)
submissionForest$status_group<- pred_forest_test
str(submissionForest)
names(submissionForest)[1]<="id"
write.csv(submissionForest,file="waterpumpsForest2.csv",row.names=FALSE)

###############################################################################