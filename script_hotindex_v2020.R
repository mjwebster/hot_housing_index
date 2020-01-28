#this is revised version for 2020 publication
#runs analysis and generates JSON files needed for online: http://www.startribune.com/ranking-the-hottest-housing-markets-in-the-twin-cities/502089881/#place-25
#generates data needed for "HotIndex.RMD" file to share with reporter Jim Buchta

#TO DO:
#update datafile variable to point it to the correct data file
# decide on closed sale minimums for the 3 indices (right now it's 70, 40 and 40)
#update years variable for the Census data to the latest available (new data comes out each December)
#update the year variables (currentyear, lastyear)
#add annual data to misc/metro16_dom_ppsf_historical.xlsx
#get metro-wide data historical data for charts: median dom; median sale price; end of year inventory; NEED ONE OTHER CHART TO REPLACE PCT NEW CONSTRUCTION 


# load required packages
library(tidyverse)
library(ggplot2) #making charts
library(lubridate) #date functions
library(tidyr)
library(janitor) #use this for doing crosstabs
library(readxl)
library(jsonlite)
library(stringr)
library(tidycensus)
library(purrr)


#Census API key
census_api_key(Sys.getenv("CENSUS_API_KEY"))


#set year variables here so that code below doesn't need to refer to 
#specific years
currentyear='x2019'
lastyear='x2018'


#What year to pull for census data - ACS 5-year
#will be able to update this to 2018 after Christmas
years <- lst(2018)

datafile <-  './data/Hot Housing Index Annual Data 2019 (Values, 2020-01-14).xlsx'


# LOAD DATA ---------------------------------------------------------------

#load the city croswalk file
#filter to exclude records for cities that are outside the 13-county metro
#Create a new field that only grabs the state code and county subidivision code
#this is needed for joining to census data later
cities <- read_csv("./data/city_crosswalk.csv")  %>%
  clean_names()%>% 
  filter(county13!='n')%>%
  mutate(geoid2=substr(geoid,8,14)) 

neighborhoods <- cities %>%  filter(type=='neighborhood')



#closed sales data for 3 price ranges + neighborhoods
#import and then pivot longer and add labels
closed_all <- read_xlsx(datafile, sheet='CS-C', range='B14:G5894') %>% clean_names() %>% 
  rename(place=x1) %>%
  pivot_longer(-place, names_to="year", values_to = "closed_sales") %>% 
  mutate(price_range='all')

closed_starter <-  read_xlsx(datafile, sheet='CS-C', range='J14:O5894') %>% clean_names() %>% 
  rename(place=x1) %>%
  pivot_longer(-place, names_to="year", values_to = "closed_sales") %>% 
  mutate(price_range='starter')

closed_moveup <-  read_xlsx(datafile, sheet='CS-C', range='R14:W5894') %>% clean_names() %>% 
  rename(place=x1) %>%
  pivot_longer(-place, names_to="year", values_to = "closed_sales") %>% 
  mutate(price_range='moveup')


closed_hoods <- read_xlsx(datafile, sheet='CS-N', range='B14:G119') %>% clean_names() %>% 
  rename(place=x1) %>%
  pivot_longer(-place, names_to="year", values_to = "closed_sales") %>% 
  mutate(price_range='neighborhood')


#append them all together
closed <-  bind_rows(closed_all, closed_starter, closed_moveup, closed_hoods)

#join with cities data
closed  <- inner_join(closed, cities %>% select(name_in_realtors_data, geoid2), by=c("place"="name_in_realtors_data"))

#populate closed sales where it's NULL
closed$closed_sales[is.na(closed$closed_sales)] <-  0


#Days on market
dom_all <- read_xlsx(datafile, sheet='CDOM-C', range='B14:G5894') %>% clean_names() %>% 
  rename(place=x1) %>%
  pivot_longer(-place, names_to="year", values_to = "dom") %>% 
  mutate(price_range='all')

dom_starter <-  read_xlsx(datafile, sheet='CDOM-C', range='J14:O5894') %>% clean_names() %>% 
  rename(place=x1) %>%
  pivot_longer(-place, names_to="year", values_to = "dom") %>% 
  mutate(price_range='starter')

dom_moveup <-  read_xlsx(datafile, sheet='CDOM-C', range='R14:W5894') %>% clean_names() %>% 
  rename(place=x1) %>%
  pivot_longer(-place, names_to="year", values_to = "dom") %>% 
  mutate(price_range='moveup')

dom_hoods <- read_xlsx(datafile, sheet='CDOM-N', range='B14:G119') %>% clean_names() %>% 
  rename(place=x1) %>%
  pivot_longer(-place, names_to="year", values_to = "dom") %>% 
  mutate(price_range='neighborhood')

#append files together
dom <-  bind_rows(dom_all, dom_starter, dom_moveup, dom_hoods)

#join with cities data
dom  <- inner_join(dom, cities%>% select(name_in_realtors_data, geoid2), by=c("place"="name_in_realtors_data"))





#Pct of original list price
#this one isn't needed for neighborhoods

polp_all <- read_xlsx(datafile, sheet='POLP-C', range='B14:G5894') %>% clean_names() %>% 
  rename(place=x1) %>%
  pivot_longer(-place, names_to="year", values_to = "polp") %>% 
  mutate(price_range='all')

polp_starter <-  read_xlsx(datafile, sheet='POLP-C', range='J14:O5894') %>% clean_names() %>% 
  rename(place=x1) %>%
  pivot_longer(-place, names_to="year", values_to = "polp") %>% 
  mutate(price_range='starter')

polp_moveup <-  read_xlsx(datafile, sheet='POLP-C', range='R14:W5894') %>% clean_names() %>% 
  rename(place=x1) %>%
  pivot_longer(-place, names_to="year", values_to = "polp") %>% 
  mutate(price_range='moveup')

#append files together
polp  <- bind_rows(polp_all, polp_starter, polp_moveup)

rm(polp_all, polp_starter, polp_moveup)

#join with city data
polp  <- inner_join(polp, cities%>% select(name_in_realtors_data, geoid2), by=c("place"="name_in_realtors_data"))




#Price per square foot
ppsf_all <- read_xlsx(datafile, sheet='PPSF-C', range='B14:G5894') %>% clean_names() %>% 
  rename(place=x1) %>%
  pivot_longer(-place, names_to="year", values_to = "ppsf") %>% 
  mutate(price_range='all')

ppsf_starter <-  read_xlsx(datafile, sheet='PPSF-C', range='J14:O5894') %>% clean_names() %>% 
  rename(place=x1) %>%
  pivot_longer(-place, names_to="year", values_to = "ppsf") %>% 
  mutate(price_range='starter')

ppsf_moveup <-  read_xlsx(datafile, sheet='PPSF-C', range='R14:W5894') %>% clean_names() %>% 
  rename(place=x1) %>%
  pivot_longer(-place, names_to="year", values_to = "ppsf") %>% 
  mutate(price_range='moveup')

ppsf_hoods <- read_xlsx(datafile, sheet='PPSF-N', range='B14:G119') %>% clean_names() %>% 
  rename(place=x1) %>%
  pivot_longer(-place, names_to="year", values_to = "ppsf") %>% 
  mutate(price_range='neighborhood')

#append files together
ppsf  <-  bind_rows(ppsf_all, ppsf_starter, ppsf_moveup, ppsf_hoods)

#join with cities data
ppsf  <- inner_join(ppsf, cities%>% select(name_in_realtors_data, geoid2), by=c("place"="name_in_realtors_data"))



#Inventory
inv_all <- read_xlsx(datafile, sheet='INV-C', range='B14:G5894') %>% clean_names() %>% 
  rename(place=x1) %>%
  pivot_longer(-place, names_to="year", values_to = "inv") %>% 
  mutate(price_range='all')

inv_starter <-  read_xlsx(datafile, sheet='INV-C', range='J14:O5894') %>% clean_names() %>% 
  rename(place=x1) %>%
  pivot_longer(-place, names_to="year", values_to = "inv") %>% 
  mutate(price_range='starter')

inv_moveup <-  read_xlsx(datafile, sheet='INV-C', range='R14:W5894') %>% clean_names() %>% 
  rename(place=x1) %>%
  pivot_longer(-place, names_to="year", values_to = "inv") %>% 
  mutate(price_range='moveup')

inv_hoods <- read_xlsx(datafile, sheet='INV-N', range='B14:G119') %>% clean_names() %>% 
  rename(place=x1) %>%
  pivot_longer(-place, names_to="year", values_to = "inv") %>% 
  mutate(price_range='neighborhood')

#append files together
inv <- bind_rows(inv_all, inv_starter, inv_moveup, inv_hoods)

#join with cities data
inv  <- inner_join(inv, cities%>% select(name_in_realtors_data, geoid2), by=c("place"="name_in_realtors_data"))




#Join them all together into one file
alldata <- left_join(closed, dom %>% select(-place), by=c("geoid2"="geoid2", "year"="year", "price_range"="price_range"))
alldata <- left_join(alldata, polp %>% select(-place), by=c("geoid2"="geoid2", "year"="year", "price_range"="price_range"))
alldata <- left_join(alldata, ppsf %>% select(-place), by=c("geoid2"="geoid2", "year"="year", "price_range"="price_range"))
alldata <- left_join(alldata, inv %>% select(-place), by=c("geoid2"="geoid2", "year"="year", "price_range"="price_range"))










# CREATE INDEX ------------------------------------------------------------



#Create index data -- only need the most current year
index <- alldata %>% filter(year==currentyear)


#Need to get the ppsf average for the four years prior
ppsf_avg <-  ppsf %>% filter(year!=currentyear) %>%
  group_by(geoid2, price_range) %>%
  summarise(ppsfavg = mean(ppsf))

#add ppsf avg to the index data and calculate pct change

index <-  left_join(index, ppsf_avg, by=c("geoid2"="geoid2", "price_range"="price_range")) %>% 
  mutate(ppsf_pctchange = ((ppsf-ppsfavg)/ppsfavg))

#avg the closed sales for the four years prior
closed_avg <- closed %>% filter(year!=currentyear) %>% 
  group_by(geoid2, price_range) %>% 
  summarise(closedavg = mean(closed_sales))

#add closed avg to the index data and calculate percent change

index <-  left_join(index, closed_avg, by=c("geoid2"="geoid2", "price_range"="price_range")) %>% 
  mutate(closed_pctchange = ((closed_sales-closedavg)/closedavg))


#calculate the difference in DOM between the year before and current year
#and add that to the index

dom_lastyear<-  dom %>% filter(year==lastyear) %>%
  select(geoid2, price_range, dom) %>% 
  rename(dom_lastyr = dom)

index <-  left_join(index, dom_lastyear, by=c("geoid2"="geoid2", "price_range"="price_range")) %>% 
  mutate(dom_diff = dom-dom_lastyr)


# ALL MARKET INDEX --------------------------------------------------------

#this grabs the cities that won't be in the index but will be in the online lookup
index_missing <- index %>% filter(price_range=='all', closed_sales<70)



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

#index_all %>% arrange(desc(index_score)) %>%
#  select(place, closed_sales, ppsf_pctchange, closed_pctchange, dom_diff, index_score)


#NEED TO PUT NEIGHBORHOODS BACK INTO THIS INDEX_ALL FILE

index_neighborhoods <-  index %>% 
  filter(price_range=='neighborhood')

index_all <-  bind_rows(index_all, index_neighborhoods, index_missing)


# STARTER HOME MARKET INDEX -----------------------------------------------
#starter home = under $300k sale price
#only includes cities with 40 or more sales in this price range
index_starter <-  index %>% 
  filter(price_range=='starter', closed_sales>=40) %>% 
  mutate(dom_rank=rank(-dom),
         polp_rank=rank(polp),
         ppsf_rank=rank(ppsf_pctchange),
         closed_rank = rank(closed_pctchange),
         dom_change_rank = rank(-dom_diff),
         index_score = dom_rank+polp_rank+ppsf_rank+closed_rank+dom_change_rank)

#index_starter %>% arrange(desc(index_score)) %>%
#  select(place, closed_sales, ppsf_pctchange, closed_pctchange, dom_diff, index_score)


# MOVE UP MARKET INDEX ----------------------------------------------------

#move up market = $300k to $750k sale price
#only includes cities with 40 or more sales in this price range
index_moveup <-  index %>% 
  filter(price_range=='moveup', closed_sales>=40) %>% 
  mutate(dom_rank=rank(-dom),
         polp_rank=rank(polp),
         ppsf_rank=rank(ppsf_pctchange),
         closed_rank = rank(closed_pctchange),
         dom_change_rank = rank(-dom_diff),
         index_score = dom_rank+polp_rank+ppsf_rank+closed_rank+dom_change_rank)

#index_moveup %>% arrange(desc(index_score)) %>%
#  select(place, closed_sales, ppsf_pctchange, closed_pctchange, dom_diff, index_score)


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






# TIME SERIES FOR CHARTS ONLINE --------------------------------------------------

#dom
#ppsf
#closed sales
#inventory


#this first batch of code grabs data for the cities

timeseries_cities <-  left_join(cities %>%
                                  filter(type=='city') %>% 
                           select(strib_id, name_in_realtors_data, geoid2, full_name, location, type),
                         dom_all %>% select(place, year, dom),
                         by=c("name_in_realtors_data"="place"))

timeseries_cities <-  left_join(timeseries_cities , ppsf_all %>% select(place, year, ppsf),
                         by=c("name_in_realtors_data"="place", "year"="year"))


timeseries_cities <-  left_join(timeseries_cities , closed_all %>% select(place, year, closed_sales),
                         by=c("name_in_realtors_data"="place", "year"="year"))


timeseries_cities <-  left_join(timeseries_cities , inv_all %>% select(place, year, inv),
                         by=c("name_in_realtors_data"="place", "year"="year"))%>%
  mutate(variable = str_sub(year,2,5)) %>% 
  rename(place=name_in_realtors_data) 


#The data for the metro lines in the time series charts for DOM and PPSF 
# are in this data file
#A new column needs to be added to the Excel file for the latest year

timeseries_metro <-  read_xlsx('./misc/metro16_dom_ppsf_historical.xlsx') %>%
  mutate(variable = as.character(year), type='city', location='Metro', strib_id=220, geoid2='2733460', full_name=place) %>% 
  select(-year)







#merge it all together, including neighborhood label data
timeseries_hoods <-  left_join(neighborhoods %>%
                           select(strib_id, geoid2, name_in_realtors_data, full_name, location, type, neighborhoodname),
                         dom_hoods %>% select(place, year, dom),
                         by=c("name_in_realtors_data"="place"))

timeseries_hoods <-  left_join(timeseries_hoods , ppsf_hoods %>% select(place, year, ppsf),
                         by=c("name_in_realtors_data"="place", "year"="year"))


timeseries_hoods <-  left_join(timeseries_hoods , closed_hoods %>% select(place, year, closed_sales),
                         by=c("name_in_realtors_data"="place", "year"="year"))


timeseries_hoods <-  left_join(timeseries_hoods , inv_hoods %>% select(place, year, inv),
                         by=c("name_in_realtors_data"="place", "year"="year")) %>%
  mutate(variable = str_sub(year,2,5)) %>% 
  rename(place=name_in_realtors_data) %>% 
  select(-year)



#merge thre three timeseries files and reorder columns to match last year

timeseries <-  bind_rows(timeseries_cities, timeseries_metro, timeseries_hoods) %>% 
  select(place, variable, dom, type, 
         strib_id, geoid2, full_name, location, neighborhoodname,
         ppsf, closed=closed_sales, inventory=inv)






#export to JSON
timeseries_json <-  toJSON(timeseries, pretty=TRUE)
write(timeseries_json, "./output/timeseries.json")






#generate as a JSON file
hot_housing_index_json <-  toJSON(index_for_web, pretty=TRUE)
write(hot_housing_index_json, "./output/hot_housing_index.json")



#other analysis

pctstarter <-  pivot_wider(alldata %>% filter(year=='x2019') %>%
                             select(place, price_range, closed_sales), names_from=price_range, values_from = closed_sales) %>% 
  mutate(pctstarter = starter/all,
         pctmoveup = moveup/all)


pctstarter2018 <-  pivot_wider(alldata %>% filter(year=='x2018') %>%
                             select(place, price_range, closed_sales), names_from=price_range, values_from = closed_sales) %>% 
  mutate(pctstarter = starter/all,
         pctmoveup = moveup/all)

polp %>% filter(place=='Wayzata')


inventory  <- pivot_wider(inv_all %>% filter(price_range=='all'), names_from=year, values_from=inv)  %>% 
  mutate(pctchange = (x2019-x2017)/x2017)

inventory <-  left_join(cities %>% select(name_in_realtors_data, location), inventory, by=c("name_in_realtors_data"="place")) %>% filter(x2019!='NA' & x2019>=10)



hoods <-  left_join(ppsf_hoods %>% select(-price_range), closed_hoods %>% select(place, year, closed_sales), by=c("place"="place", "year"="year")) 


hoods_sales_2019 <-  closed_hoods %>% filter(year=='x2019', place!='Unknown', closed_sales>=25)

hoods <- inner_join(hoods, hoods_sales_2019 %>% select(place), by=c("place"="place"))

hoods_ppsf_wide <-  pivot_wider(hoods %>% select(-closed_sales), names_from=year, values_from=ppsf) 

hoods_ppsf_wide <-  hoods_ppsf_wide %>% mutate(pctchange = (x2019-x2015)/x2015)
hoods_ppsf_wide %>% arrange(desc(pctchange))

write.csv(hoods_ppsf_wide, './output/hoods_ppsf_change.csv', row.names=FALSE)
