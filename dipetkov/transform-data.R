
#' # Clean up existing predictors. Engineer some new features.

#+ global_options, include=FALSE
library(knitr)
opts_chunk$set(
	fig.width=8, fig.height=7, fig.path='Figures/',
	echo = TRUE, warning = FALSE, message = FALSE)

#' Load the data and a couple of functions to reduce the number of levels that a categorical variable takes.

#+ , results = 'hide', fig.show = 'hide'
source("read-data.R")
source("myRfunctions.R")

#' The data table contains an ID column, a subset indicator (`subset` is either *train* or *test*), a response column (`status_group` is *functional*, *functional needs repair* or *non functional*) and 38 features.

#+
##str(data) ## Use 'str' for more detailed information about the data
names(data) ## Or just print the column names

#' Based on their names alone, some features capture similar information but possibly at different granularity levels (e.g, `extraction_type` and `extraction_type_group`). For each grouping of features, I keep both the coarser and the finer variables but I group some of the smaller levels together so that categorical predictors have about a dosen or so levels.
#'
#' ### `extraction_type`, `extraction_type_group`, `extraction_type_class`

#+
data %>%
  group_by(extraction_type_class, extraction_type_group, extraction_type) %>% tally()
data = data %>%
	mutate(extraction_type = revalue(extraction_type,
	                                 c("cemo" = "other motorpump",
	                                   "climax" = "other motorpump",
	                                   "other - mkulima/shinyanga" = "other handpump",
	                                   "other - play pump" = "other handpump",
	                                   "walimi" = "other handpump",
	                                   "other - swn 81" = "swn",
	                                   "swn 80" = "swn",
	                                   "india mark ii" = "india mark",
	                                   "india mark iii" = "india mark"))) %>%
	select( - extraction_type_group ) 

#' I remove the middle level `extraction_type_group` and combine some of the smaller levels, mostly by brand. For example, I combine *swn 80* and *swn 81* into *swn*.
#'
#' ### `management`, `management_group`

#+
data %>% group_by(management_group, management) %>% tally()

#' I keep both `management` and `management_group` unmodified.
#'
#' ### `scheme_management`, `scheme_name`

#+ 
data %>% group_by(scheme_management, scheme_name) %>% tally()
data = data %>% select( - scheme_name)

#' I remove `scheme name` as it has too many levels, often with one or handful of examples.
#'
#' ### `payment`, `payment_type`

#+
data %>% group_by(payment_type, payment) %>% tally()
data = data %>% select( - payment )

#' Some categories are renamed but otherwise these features are exactly the same. I keep `payment_type`.
#'
#' ### `water_quality`, `quality_group`

#+
data %>% group_by(quality_group, water_quality) %>% tally()
data = data %>% select( - quality_group)

#' I keep the more precise factor `water_quality`.
#'
#' ### `quantity`, `quantity_group`

#+
data %>% group_by(quantity_group, quantity) %>% tally()
data = data %>% select( - quantity_group)

#' These features are exactly the same. I keep `quantity`.
#'
#' ### `source`, `source_type`, `source_class`

#+
data %>% group_by(source_class, source_type, source) %>% tally()
data = data %>%
	mutate(source = revalue(source,c("other" = NA))) %>% select( - source_type)

#' I remove the middle level `source_type`. I am not sure if *other* means other or unknown, so I relabel *other* as NA.
#'
#' ### `waterpoint_type`, `waterpoint_type_group`

#+
data %>% group_by(waterpoint_type_group, waterpoint_type) %>% tally()
data = data %>% select( - waterpoint_type_group)

#' I keep the more precise factor `waterpoint_type`.
#'
#' ### Geographic information
#'
#' Several variables seem to describe the location: `region`, `region_code`, `district_code`, `ward`, `subvillage`, `lga`, `longitude` and `latitude`. The same `district_code` appears in different regions, so I assume this variable indicates a smaller unit within each region.

#+
data %>% group_by(region, region_code, district_code) %>% tally()

#' I guess that, in increasing degree of precision, the geographic information is given by
#'
#' * `region` (or `region_code`)
#' * `district_code` within `region`
#' * `ward` 
#' * `subvillage`
#' * `longitude`x`latitude`
#'
#' I keep the region (as a categorical predictor) and latitude, longitude (as numerical predictors). However, before I remove the other variables, I use the district-within-region information to fill in a few missing longitude and latitude values. The input long/lat coordinates for some points are (0,0), which doesn't make sense as this location is not in Tanzania. But there are no missing values in the region and district columns, so I can substitute missing individual long/lat values with their district *mean* long/lat.

#+
## Compute averages in districts within regions
data = data %>% 
  group_by(region,district_code) %>%
  mutate(district.long = mean(longitude, na.rm = TRUE)) %>%
  mutate(district.lat = mean(latitude, na.rm = TRUE)) %>%
  ungroup()
## Compute averages in regions (just in case the above is also NA)
data = data %>%
  group_by(region) %>%
  mutate(region.long = mean(longitude, na.rm = TRUE)) %>%
  mutate(region.lat = mean(latitude, na.rm = TRUE)) %>%
  ungroup()
## "Impute" missing longitude/latitude values
data = data %>%
  mutate(longitude = ifelse(!is.na(longitude), longitude,
                            ifelse(!is.na(district.long), district.long, region.long))) %>%
  mutate(latitude = ifelse(!is.na(latitude), latitude,
                           ifelse(!is.na(district.lat), district.lat, region.lat)))

#+
data = data %>% select( - region_code, - district_code,
                        - region.long, - region.lat,
                        - district.long, - district.lat,
                        - ward , - subvillage)

#' Finally, `lga` (local geographic area?) is interesting because there are distinct areas (e.g. *arusha*) but some of them are split into rural and urban (e.g., *arusha rural* and *arusha urban*). I transform this variable into a new feature that takes three values: rural, urban and other.

#+
data = data %>% mutate(lga = ifelse( grepl(" rural", lga), "rural",
                                     ifelse( grepl(" urban", lga), "urban","other")))

#' ### Non-random missingness by region
#'
#' There is also information about the number of people who use the pump, `population`. Since `gps_height` has a strong spatial component, it might be related to the elevation above sea level? Both features have more than 30% missing values, and moreover, these are not missing at random. (So I do not attempt to impute them.)

#+ gps_height_population, fig.width=10, fig.height=4
p1 = ggplot(data, aes(x = longitude, y = latitude, color = gps_height)) + geom_point()
p2 = ggplot(data, aes(x = longitude, y = latitude, color = population)) + geom_point()
multiplot(p1, p2, cols=2)

#' ### Day/Month/Year/Time information
#'
#' There is some interesting time information as well: `date_recorded` and `construction_year`. Unfortunately, the year of construction is missing for about 35% of the data points. I convert it to `operation_years` by subtracting the year in which the status was recorded. There are a few negative years of operation! I set those to missing, as a clerical error might have occurred.

#+
data = data %>% mutate(date_recorded = ymd(date_recorded)) %>%
  mutate(operation_years = lubridate::year(date_recorded) - construction_year) %>%
  mutate(operation_years = ifelse(operation_years < 0, NA, operation_years))

#' I wonder if some pumps are more likely to not function during some seasons than others. From [Expert Africa](https://www.expertafrica.com/tanzania/info/tanzania-weather-and-climate): *Tanzania has two rainy seasons: The short rains from late-October to late-December, a.k.a. the Mango Rains, and the long rains from March to May.*
#'
#' So I create a season variable. If there is a seasonal effect, it might be even better to include the recorded day of the year as an integer from 1 to 365. (Another alternative is the recorded month, either as a numerical or a categorical variable.)

#+
data = data %>%
  mutate(day_of_year = yday(date_recorded)) %>%
  mutate(month_recorded = lubridate::month(date_recorded)) %>%
  mutate(season = ifelse( month_recorded <= 2, "dry short",
                          ifelse( month_recorded <= 5, "wet long",
                                  ifelse(month_recorded <= 9, "dry long", "wet short")))) %>%
  select( - date_recorded, - month_recorded, - construction_year)

#' I keep the categorical `season` and the numerical `day_of_year`.
#'
#' ### Other categorical variables
#'
#' There are three more categorical variables, with numerous distinct levels.

#+
cbind(
  data %>% group_by(funder) %>% tally() %>% arrange(desc(n)) %>% slice(1:10),
  data %>% group_by(installer) %>% tally() %>% arrange(desc(n)) %>% slice(1:10),
  data %>% group_by(wpt_name) %>% tally() %>% arrange(desc(n)) %>% slice(1:10)
)

#' Of these `funder` and `installer` have a few large categories (more than 500 instances), so I keep those and group their smaller categories under *other*. I remove `wpt_name` since I am not even sure what this is.

#+
data = data %>% select( - wpt_name) %>%
  mutate(funder = myreduce.levels(funder)) %>%
  mutate(installer = myreduce.levels(installer)) 

#' Finally, `num_private` is mostly 1s; there is only one instance with management == "none" and it is in the training data.

#+
data = data %>% select( - id , - num_private ) %>%
  filter(scheme_management != "none" | is.na(scheme_management))

#' ### Missingness
#'
#' Which features have a lot of missing values?

#+
mean.na = function(x) {	mean(is.na(x)) }
t(data %>% summarise_each(funs(mean.na)))

#' I exclude `amount_tsh` because about 70% of the values are missing.
 
#+
data = data %>% select( - amount_tsh)

#+ , echo = FALSE
## Let each predictor be either numeric or nominal (factor rather than character or logical)                        
chr.cols = data %>% summarise_each(funs(is.character(.))) %>% unlist() %>% which() %>% names()
lgl.cols = data %>% summarise_each(funs(is.logical(.))) %>% unlist() %>% which() %>% names()
data = data %>% mutate_each( funs(as.factor), one_of(chr.cols,lgl.cols))
train = data %>% filter(subset == "train") %>% select( - subset)
test = data %>% filter(subset == "test") %>% select( - subset, - status_group)

