#this is revised version for January 2020 publication


#install.packages("jsonlite")

# load required packages
library(readr) #importing csv files
#library(plyr) #needed for stacked bar chart label positions
library(dplyr) #general analysis 
library(ggplot2) #making charts
library(lubridate) #date functions
library(reshape2) #use this for melt function to create one record for each team
library(tidyr)
library(janitor) #use this for doing crosstabs
library(readxl)
library(scales) #needed for stacked bar chart axis labels
library(knitr) #needed for making tables in markdown page
library(car)
library(aws.s3) #needed for uploading to amazon S3 server
library(rmarkdown)
library(DT) #needed for making  searchable sortable data tble
library(jsonlite)
library(stringr)
library(tidycensus)
library(purrr)


#set year variables here so that code below doesn't need to refer to 
#specific years
currentyear='x2019'
lastyear='x2018'
twoyearsago <- 'x2017'
threeyearsago <- 'x2016'
fouryearsago <- 'x2015'

#Census API key
census_api_key(Sys.getenv("CENSUS_API_KEY"))

#What year to pull for census data - ACS 5-year
#will be able to update this to 2018 after Christmas
years <- lst(2017)


# LOAD DATA ---------------------------------------------------------------

#load the city croswalk file
#filter to exclude records for cities that are outside the 13-county metro
#Create a new field that only grabs the state code and county subidivision code
#this is needed for joining to census data later
cities <- read_csv("./data/city_crosswalk.csv")  %>%
  clean_names()%>% 
  filter(county13=='y')%>%
  mutate(geoid2=substr(geoid,8,14)) 



#closed sales data for 3 price ranges
#import and then pivot longer and add labels
closed_all <- read_xlsx('./data/data2019_test.xlsx', sheet='CS-C', range='B14:G5894') %>% clean_names() %>% 
  rename(place=row_labels) %>%
  pivot_longer(-place, names_to="year", values_to = "closed_sales") %>% 
  mutate(price_range='all')

closed_starter <-  read_xlsx('./data/data2019_test.xlsx', sheet='CS-C', range='J14:O5894') %>% clean_names() %>% 
  rename(place=row_labels) %>%
  pivot_longer(-place, names_to="year", values_to = "closed_sales") %>% 
  mutate(price_range='starter')

closed_moveup <-  read_xlsx('./data/data2019_test.xlsx', sheet='CS-C', range='R14:W5894') %>% clean_names() %>% 
  rename(place=row_labels) %>%
  pivot_longer(-place, names_to="year", values_to = "closed_sales") %>% 
  mutate(price_range='moveup')

#append them all together
closed <-  bind_rows(closed_all, closed_starter, closed_moveup)

#join with cities data
closed  <- inner_join(closed, cities %>% select(name_in_realtors_data, geoid2), by=c("place"="name_in_realtors_data"))

#populate closed sales where it's NULL
closed$closed_sales[is.na(closed$closed_sales)] <-  0

#check to make sure we have 170 rows
#closed %>% group_by(place) %>% summarise(count=n())

#Days on market
dom_all <- read_xlsx('./data/data2019_test.xlsx', sheet='CDOM-C', range='B14:G5894') %>% clean_names() %>% 
  rename(place=row_labels) %>%
  pivot_longer(-place, names_to="year", values_to = "dom") %>% 
  mutate(price_range='all')

dom_starter <-  read_xlsx('./data/data2019_test.xlsx', sheet='CDOM-C', range='J14:O5894') %>% clean_names() %>% 
  rename(place=row_labels) %>%
  pivot_longer(-place, names_to="year", values_to = "dom") %>% 
  mutate(price_range='starter')

dom_moveup <-  read_xlsx('./data/data2019_test.xlsx', sheet='CDOM-C', range='R14:W5894') %>% clean_names() %>% 
  rename(place=row_labels) %>%
  pivot_longer(-place, names_to="year", values_to = "dom") %>% 
  mutate(price_range='moveup')

#append files together
dom <-  bind_rows(dom_all, dom_starter, dom_moveup)

#join with cities data
dom  <- inner_join(dom, cities%>% select(name_in_realtors_data, geoid2), by=c("place"="name_in_realtors_data"))

#check to make sure we have 170 rows
#dom %>% group_by(place) %>% summarise(count=n())

#Pct of original list price
polp_all <- read_xlsx('./data/data2019_test.xlsx', sheet='POLP-C', range='B14:G5894') %>% clean_names() %>% 
  rename(place=row_labels) %>%
  pivot_longer(-place, names_to="year", values_to = "polp") %>% 
  mutate(price_range='all')

polp_starter <-  read_xlsx('./data/data2019_test.xlsx', sheet='POLP-C', range='J14:O5894') %>% clean_names() %>% 
  rename(place=row_labels) %>%
  pivot_longer(-place, names_to="year", values_to = "polp") %>% 
  mutate(price_range='starter')

polp_moveup <-  read_xlsx('./data/data2019_test.xlsx', sheet='POLP-C', range='R14:W5894') %>% clean_names() %>% 
  rename(place=row_labels) %>%
  pivot_longer(-place, names_to="year", values_to = "polp") %>% 
  mutate(price_range='moveup')

#append files together
polp  <- bind_rows(polp_all, polp_starter, polp_moveup)

#join with city data
polp  <- inner_join(polp, cities%>% select(name_in_realtors_data, geoid2), by=c("place"="name_in_realtors_data"))

#check to make sure we have 170 rows
#polp %>% group_by(place) %>% summarise(count=n())

#Price per square foot
ppsf_all <- read_xlsx('./data/data2019_test.xlsx', sheet='PPSF-C', range='B14:G5894') %>% clean_names() %>% 
  rename(place=row_labels) %>%
  pivot_longer(-place, names_to="year", values_to = "ppsf") %>% 
  mutate(price_range='all')

ppsf_starter <-  read_xlsx('./data/data2019_test.xlsx', sheet='PPSF-C', range='J14:O5894') %>% clean_names() %>% 
  rename(place=row_labels) %>%
  pivot_longer(-place, names_to="year", values_to = "ppsf") %>% 
  mutate(price_range='starter')

ppsf_moveup <-  read_xlsx('./data/data2019_test.xlsx', sheet='PPSF-C', range='R14:W5894') %>% clean_names() %>% 
  rename(place=row_labels) %>%
  pivot_longer(-place, names_to="year", values_to = "ppsf") %>% 
  mutate(price_range='moveup')

#append files together
ppsf  <-  bind_rows(ppsf_all, ppsf_starter, ppsf_moveup)

#join with cities data
ppsf  <- inner_join(ppsf, cities%>% select(name_in_realtors_data, geoid2), by=c("place"="name_in_realtors_data"))

#check to make sure we have 170 rows
#ppsf %>% group_by(place) %>% summarise(count=n())

#Inventory
inv_all <- read_xlsx('./data/data2019_test.xlsx', sheet='INV-C', range='B14:G5894') %>% clean_names() %>% 
  rename(place=row_labels) %>%
  pivot_longer(-place, names_to="year", values_to = "inv") %>% 
  mutate(price_range='all')

inv_starter <-  read_xlsx('./data/data2019_test.xlsx', sheet='INV-C', range='J14:O5894') %>% clean_names() %>% 
  rename(place=row_labels) %>%
  pivot_longer(-place, names_to="year", values_to = "inv") %>% 
  mutate(price_range='starter')

inv_moveup <-  read_xlsx('./data/data2019_test.xlsx', sheet='INV-C', range='R14:W5894') %>% clean_names() %>% 
  rename(place=row_labels) %>%
  pivot_longer(-place, names_to="year", values_to = "inv") %>% 
  mutate(price_range='moveup')

#append files together
inv <- bind_rows(inv_all, inv_starter, inv_moveup)

#join with cities data
inv  <- inner_join(inv, cities%>% select(name_in_realtors_data, geoid2), by=c("place"="name_in_realtors_data"))

#check to make sure we have 170 rows
#inv %>% group_by(place) %>% summarise(count=n())


#Join them all together into one file
alldata <- left_join(closed, dom %>% select(-place), by=c("geoid2"="geoid2", "year"="year", "price_range"="price_range"))
alldata <- left_join(alldata, polp %>% select(-place), by=c("geoid2"="geoid2", "year"="year", "price_range"="price_range"))
alldata <- left_join(alldata, ppsf %>% select(-place), by=c("geoid2"="geoid2", "year"="year", "price_range"="price_range"))
alldata <- left_join(alldata, inv %>% select(-place), by=c("geoid2"="geoid2", "year"="year", "price_range"="price_range"))


#Create index data -- only need the most current year
index <- alldata %>% filter(year==currentyear)


#Need to get the ppsf average for the four years prior
ppsf_avg <-  ppsf %>% filter(year!=currentyear) %>%
  group_by(geoid2, price_range) %>%
  summarise(ppsfavg = mean(ppsf))

#add ppsf avg to the index data and calculate pct change

index <-  left_join(index, ppsf_avg, by=c("geoid2"="geoid2", "price_range"="price_range")) %>% 
  mutate(ppsf_pctchange = ((ppsf-ppsfavg)/ppsfavg)*100)

#avg the closed sales for the four years prior
closed_avg <- closed %>% filter(year!=currentyear) %>% 
  group_by(geoid2, price_range) %>% 
  summarise(closedavg = mean(closed_sales))

#add closed avg to the index data and calculate percent change

index <-  left_join(index, closed_avg, by=c("geoid2"="geoid2", "price_range"="price_range")) %>% 
  mutate(closed_pctchange = ((closed_sales-closedavg)/closedavg)*100)


#calculate the difference in DOM between the year before and current year
#and add that to the index

dom_lastyear<-  dom %>% filter(year==lastyear) %>%
  select(geoid2, price_range, dom) %>% 
  rename(dom_lastyr = dom)

index <-  left_join(index, dom_lastyear, by=c("geoid2"="geoid2", "price_range"="price_range")) %>% 
  mutate(dom_diff = dom-dom_lastyr)


# ALL MARKET INDEX --------------------------------------------------------


#index -- all sales; markets with 70 or more sales
index_all <-  index %>% 
  filter(price_range=='all', closed_sales>=70) %>% 
  mutate(dom_rank=rank(-dom),
         polp_rank=rank(polp),
         ppsf_rank=rank(ppsf_pctchange),
         closed_rank = rank(closed_pctchange),
         dom_change_rank = rank(-dom_diff),
         index_score = dom_rank+polp_rank+ppsf_rank+closed_rank+dom_change_rank,
         index_rank =rank(-index_score, ties.method = c("max")))

index_all %>% arrange(desc(index_score)) %>%
  select(place, closed_sales, ppsf_pctchange, closed_pctchange, dom_diff, index_score)



# STARTER HOME MARKET INDEX -----------------------------------------------

index_starter <-  index %>% 
  filter(price_range=='starter', closed_sales>=40) %>% 
  mutate(dom_rank=rank(-dom),
         polp_rank=rank(polp),
         ppsf_rank=rank(ppsf_pctchange),
         closed_rank = rank(closed_pctchange),
         dom_change_rank = rank(-dom_diff),
         index_score = dom_rank+polp_rank+ppsf_rank+closed_rank+dom_change_rank)

index_starter %>% arrange(desc(index_score)) %>%
  select(place, closed_sales, ppsf_pctchange, closed_pctchange, dom_diff, index_score)


# MOVE UP MARKET INDEX ----------------------------------------------------

index_moveup <-  index %>% 
  filter(price_range=='moveup', closed_sales>=40) %>% 
  mutate(dom_rank=rank(-dom),
         polp_rank=rank(polp),
         ppsf_rank=rank(ppsf_pctchange),
         closed_rank = rank(closed_pctchange),
         dom_change_rank = rank(-dom_diff),
         index_score = dom_rank+polp_rank+ppsf_rank+closed_rank+dom_change_rank)

index_moveup %>% arrange(desc(index_score)) %>%
  select(place, closed_sales, ppsf_pctchange, closed_pctchange, dom_diff, index_score)


#export files
write.csv(index_all, './output/index_all_2019.csv', row.names=FALSE)
write.csv(index_starter, './output/index_starter_2019.csv', row.names=FALSE)
write.csv(index_moveup, './output/index_moveup_2019.csv', row.names=FALSE)



# ADD OTHER METRICS FOR ONLINE --------------------------------------------

#from census : 
#pct owner occupied
#pct cost-burdened owners
#median household income
#median home values



#need to get places from both MN and WI
my_states <- c("MN", "WI")



#HOME OWNERSHIP

ownership_variables <-  c(housingunits = "B25003_001",
                          owner_units = "B25003_002",
                          renter_units = "B25003_003")

metro_tenure <-  map_dfr(
  years,
  ~ get_acs(
    geography = "metropolitan statistical area/micropolitan statistical area",
    variables = ownership_variables,
    year = .x,
    survey = "acs5"
  ),
  .id = "year"
) %>%
  clean_names() %>% 
  filter(geoid=='33460')


place_tenure <-  map_dfr(
  years,
  ~ get_acs(
    geography = "place",
    variables = ownership_variables,
    state=my_states,
    year = .x,
    survey = "acs5"
  ),
  .id = "year"
) %>% clean_names()

tenure <-  bind_rows(place_tenure, metro_tenure)

tenure <-  pivot_wider(tenure %>% select(-moe, -year), names_from = "variable", values_from="estimate") %>% 
  mutate(pct_owner = owner_units/housingunits) %>% 
  select(geoid, pct_owner)



#MEDIAN HOUSEHOLD INCOME & MEDIAN HOME VALUES

income_variables <- c(median_hh_income = "B19013_001")

metro_income <-  map_dfr(
  years,
  ~ get_acs(
    geography = "metropolitan statistical area/micropolitan statistical area",
    variables = income_variables,
    year = .x,
    survey = "acs5"
  ),
  .id = "year"
) %>%
  clean_names() %>% 
  filter(geoid=='33460')


place_income <-  map_dfr(
  years,
  ~ get_acs(
    geography = "place",
    variables = income_variables,
    state=my_states,
    year = .x,
    survey = "acs5"
  ),
  .id = "year"
) %>% clean_names()

income <-  bind_rows(place_income, metro_income) %>%
  select(geoid, hhincome=estimate)


#COST BURDENED OWNERS

burden_variables <- c(total_owners = "B25106_002",
                      over30pct_1 = "B25106_010",
                      over30pct_2 = "B25106_014",
                      over30pct_3 = "B25106_018",
                      over30pct_4 = "B25106_022")


metro_burden <-  map_dfr(
  years,
  ~ get_acs(
    geography = "metropolitan statistical area/micropolitan statistical area",
    variables = burden_variables,
    year = .x,
    survey = "acs5"
  ),
  .id = "year"
) %>%
  clean_names() %>% 
  filter(geoid=='33460')


place_burden <-  map_dfr(
  years,
  ~ get_acs(
    geography = "place",
    variables = burden_variables,
    state=my_states,
    year = .x,
    survey = "acs5"
  ),
  .id = "year"
) %>% clean_names()

burden <-  bind_rows(place_burden, metro_burden) 
burden <-  pivot_wider(burden %>% select(-moe, -year), names_from = "variable", values_from="estimate") %>% 
  mutate(pct_burden = (over30pct_1 + over30pct_2 + over30pct_3 + over30pct_4)/total_owners) %>% 
  select(geoid, pct_burden)



#MEDIAN HOME VALUES

value_variables <- c(median_home_value = "B25077_001")

metro_value <-  map_dfr(
  years,
  ~ get_acs(
    geography = "metropolitan statistical area/micropolitan statistical area",
    variables = value_variables,
    year = .x,
    survey = "acs5"
  ),
  .id = "year"
) %>%
  clean_names() %>% 
  filter(geoid=='33460')


place_value <-  map_dfr(
  years,
  ~ get_acs(
    geography = "place",
    variables = value_variables,
    state=my_states,
    year = .x,
    survey = "acs5"
  ),
  .id = "year"
) %>% clean_names()

value <-  bind_rows(place_value, metro_value) %>%
  select(geoid, home_value=estimate)



#Merge census variables with index_all results
#value, burden, income, tenure
index_for_web <-  left_join(index_all, cities %>% select(geoid2, strib_id, full_name, city_name, location, 
                                                         county, state, type), by=c("geoid2"="geoid2"))
index_for_web <-  left_join(index_for_web, income, by=c("geoid2"="geoid") )
index_for_web <-  left_join(index_for_web, tenure, by=c("geoid2"="geoid") )
index_for_web <-  left_join(index_for_web, burden, by=c("geoid2"="geoid") )
index_for_web <-  left_join(index_for_web, value, by=c("geoid2"="geoid") )

#change order of fields to match old version
index_for_web <-  index_for_web %>% 
  select(place, geoid2, full_name, city_name,
         location, county, state, closed_sales, 
         ppsf_pctchange, dom_diff, polp,
         index_score, index_rank, pct_owner,
         pct_burden, hhincome, home_value, strib_id, type)
#generate as a JSON file
hot_housing_index_json <-  toJSON(index_for_web, pretty=TRUE)
write(hot_housing_index_json, "./output/hot_housing_index.json")




# TIME SERIES FOR CHARTS ONLINE --------------------------------------------------

#dom
#ppsf
#closed sales
#inventory


timeseries <-  left_join(cities %>%
                           select(strib_id, name_in_realtors_data, geoid2, full_name, location, type),
                         dom_all %>% select(place, year, dom),
                         by=c("name_in_realtors_data"="place"))

timeseries <-  left_join(timeseries , ppsf_all %>% select(place, year, ppsf),
                         by=c("name_in_realtors_data"="place", "year"="year"))


timeseries <-  left_join(timeseries , closed_all %>% select(place, year, closed_sales),
                         by=c("name_in_realtors_data"="place", "year"="year"))


timeseries <-  left_join(timeseries , inv_all %>% select(place, year, inv),
                         by=c("name_in_realtors_data"="place", "year"="year"))

#remove the "x" from the front of the year column
#reorder columns to match last year
timeseries <-  timeseries %>%
  mutate(variable = str_sub(year,2,5)) %>% 
  rename(place=name_in_realtors_data) %>% 
  select(place, variable, dom, type, 
         strib_id, geoid2, full_name, location,location,
         ppsf, closed=closed_sales, inventory=inv)

#export to JSON
timeseries_json <-  toJSON(timeseries, pretty=TRUE)
write(timeseries_json, "./output/timeseries.json")