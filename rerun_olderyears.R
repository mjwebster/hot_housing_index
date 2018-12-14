
# load required packages
library(readr) #importing csv files
#library(plyr) #needed for stacked bar chart label positions
library(dplyr) #general analysis 
library(ggplot2) #making charts
library(lubridate) #date functions
library(reshape2) #use this for melt function to create one record for each team
library(tidyr)
library(janitor) #use this for doing crosstabs

library(scales) #needed for stacked bar chart axis labels
library(knitr) #needed for making tables in markdown page
library(car)
library(aws.s3) #needed for uploading to amazon S3 server
library(rmarkdown)
library(DT) #needed for making  searchable sortable data tble

#UPDATE THIS  -- to reflect the years you want to use
yr1='2003'
yr2='2004'
yr3='2005'
yr4='2006'
yr5='2007'
yr6='2008'
yr7='2009'
yr8='2010'
yr9='2011'
yr10='2012'
yr11='2013'
yr12='2014'
yr13='2015'
yr14='2016'
yr15='2017'
yr16='2018'


currentyear='2017'
lastyear='2016'
twoyearsago <- '2015'
threeyearsago <- '2014'
fouryearsago <- '2013'


#Make sure the PPSF file has at least 5 years of data in it
#The first column in each file should be "Place" capitalized


#LOAD DATA
#load the city croswalk file
cities <- read_csv("city_crosswalk.csv") %>% filter(County13=='y')

#load this year's data files and melt them (normalize)
closed <- melt(read_csv("closedsales.csv"), id.vars="Place")  #closed sales data for all years by community
dom <- melt(read_csv("dom.csv"), id.vars="Place")  #days on market data for all years by community
polp <- melt(read_csv("polp.csv"), id.vars="Place")  #pct of original list price data for all years by community
ppsf <- melt(read_csv("ppsf.csv"), id.vars = "Place")  #price per sq foot data for all years by community 

#load other data files that don't need to be melted
#UPDATE THIS!!!!
#other <- read_csv("othermetrics2018.csv")  
other <- read_csv("othermetrics2017.csv")  #other metrics for 2017 (pct new construction, pct townhouse, pct distressed) 
other2016 <- read_csv("othermetrics2016.csv")  #other metrics for 2016
#lastindex <- read_csv("hotindex2017.csv", col_types=cols(GEOID=col_character(), index_rank=col_double()))  #final index scores for last index we ran 




#data cleanup

#Create a new field that only grabs the state code and county subidivision code
#this is needed for joining to census data later
cities <- cities %>% mutate(geoid2=substr(GEOID,8,14))


#fix city name for Minneapolis in the other metrics file
other$place[other$place =="Minneapolis - (Citywide)"] <- "Minneapolis"



#BUILD INDEX

#CLOSED SALES -- need most recent two years
closednew <- closed%>%filter(variable ==currentyear | variable==lastyear)

#the variable in dcast refers to the field in closednew; syntax is dataframe, what to make rows ~ what to make columns
closednew <- dcast(closednew, Place ~ variable)

index_table <- inner_join(cities %>%
                            select(NameInRealtorsData, FullName, geoid2, location, COUNTY, STATE), closednew,
                          by=c("NameInRealtorsData"="Place"))



index_table <- index_table%>%select(Place=NameInRealtorsData, geoid2, FullName, location, COUNTY, STATE, cs_prev=lastyear, cs_curr=currentyear)





#repeat that for other data tables

#DAYS ON MARKET -- need most recent two years
domnew <- dom%>%filter(variable ==lastyear | variable==currentyear)
domnew <- dcast(domnew, Place ~variable)
domnew <- domnew%>%select(Place, dom_prev=lastyear, dom_curr=currentyear)

#PCT ORIG LIST PRICE -- need most recent year only
polpnew <- polp%>%filter(variable==currentyear)%>%select(Place, pctorigprice=value)


#Price per square foot (PPSF) -- at least last 5 years

ppsfnew <- dcast(ppsf, Place ~ variable)
ppsfnew <- ppsfnew%>%select(Place, ppsf_yr1=fouryearsago, ppsf_yr2=threeyearsago, ppsf_yr3=twoyearsago,
                            ppsf_y4=lastyear, ppsf_yr5=currentyear)



#distressed, new construction, townhousecondo -- most recent year --from othermetrics
#make sure the fields are decimals (without percent signs)
distress <- other%>%select(place) %>%
  mutate(NewConstruct=round(other$NewConstruction*100,1), TownCondo=round(other$TownhouseCondo*100,1), PctDistressed=round(other$Distressed*100,1))


#join the index_table with other metrics
index_table <- left_join(index_table, ppsfnew, by=c("Place"="Place"))
index_table <- left_join(index_table, domnew, by=c("Place"="Place"))
index_table <- left_join(index_table, polpnew, by=c("Place"="Place"))
index_table <- left_join(index_table, distress, by=c("Place"="place"))

#some of the key fields in index_table are not populated for all the cities




#ADD VARIABLES:
#pct change in closed sales
#diff in days on market
#average PPSF for previous four years (columns 9 through 12 in the table, yrs1-4)
index_table <- index_table%>%
  mutate(cs_pctchange= (cs_curr-cs_prev)/cs_prev, 
         dom_diff=dom_curr-dom_prev,
         avgPPSF= rowMeans(index_table[,9:12]))

#ADD VARIABLE:
#Pct change between PPSF for most recent year and prior 4-yr average
index_table <- index_table%>%mutate(ppsf_pctchange = round((ppsf_yr5-avgPPSF)/avgPPSF*100,1))




#RANKINGS:
#rank days on market (1=highest number) Notice the minus sign in front of the field name
#rank Pct of original price (1=low percentage)
#rank PPSF change (1=lowest percentage)  
#rank distressed (1=high percentage) Notice the minus sign in front of the field name
#the na.last=false on the distressed one is to look for NULL values in the PctDistressed field; if so, they get a low rank score

index_table_rankings <- index_table%>%
  filter(cs_curr>=75) %>% 
  mutate(dom_rank=rank(-dom_curr),
         polp_rank=rank(pctorigprice),
         ppsf_rank=rank(ppsf_pctchange),
         distress_rank=rank(-PctDistressed, na.last=FALSE))


#total index score -combine the ranking scores
index_table_rankings <- index_table_rankings%>%
  mutate(index_score = dom_rank+polp_rank+ppsf_rank+distress_rank)

#rank the index score (1=highest)
#notice the minus sign in front of index_score so that the highest score gets the rank of #1
index_table_rankings <- index_table_rankings%>%mutate(index_rank = rank(-index_score))



#and add back to all the cities

final_table <-  left_join(index_table, index_table_rankings %>% select(geoid2, dom_rank, polp_rank, ppsf_rank, 
                                                                       distress_rank, index_score, index_rank),
                          by=c("geoid2"="geoid2"))



write.csv(final_table, "hotindex2017_revised.csv", row.names=FALSE)



