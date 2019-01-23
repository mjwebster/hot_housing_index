# hot_housing_index
This contains the R scripts and Markdown page for the annual "hot housing index" that we run each January. 

Data comes from David Arbit at the Minneapolis Area Association of Realtors. He sends an end-of-year file - in Excel - that has several sheets worth of data on various metrics for communities in the metro area. It's important to ask David if he can provide all this data at least several days in advance of the press conference that they hold when releasing this data to the public. In fact, put in this request with David in December, if possible, before he gets busy in the weeks leading up to the press conference.

We decided to only include incorporated cities (no townships) from the 13-county metro area. There is a file called "city_crosswalk" that has the names of all the cities in the Realtors data and matches it to the Census fips codes for places. There is also a field called "County13" where I have manually said "y" or "n" to include in the analysis. This also includes the neighborhoods of St. Paul and Minneapolis because we included them in the interactive (but not the index).

When the data arrives, you have to export the data out of the Excel file into csv files. I thought about writing R code that would pull it from Excel, but the file never seems to come in the same format every year and I just don't think I can trust that. 

So you need to make these .csv files, which should include multiple years of data (back to 2003, hopefully):
1) dom.csv -- days on market for cities (data prior to 2007 is unreliable)
2) ppsf.csv -- price per square foot for cities
3) inventory.csv - inventory of homes for cities
4) closedsales.csv -- number of closed sales for cities
5) polp.csv -- percent of original list price for cities
6) dom_neighborhood.csv -- days on market for neighborhoods
7) ppsf_neighborhood.csv -- price per square foot for neighborhoods
8) inventory_neighborhood.csv -- inventory for neighborhoods
9) closedsales_neighborhood.csv -- closed sales for neighborhoods

You will also need in a separate file from David Arbit, the market share ("other metrics") for each city, which includes the percentage of sales that were new construction and percentage that were distressed sales.

And you will need the following Census (ACS-5 year) tables for all places in MN and WI:  
1) B19013 - median household income
2) B25106 - tenure by housing costs as a percentage of household income (this one I scaled down considerably in Excel and made a separate csv file with only the fields I wanted)

In the future, it would be possible to pull this data directly via the census API. I just didn't have time to learn that this year. 

It's important to maintain data files from older years in case you have to change the index in the future. 

In December 2018, I created a separate script to re-run older years of data. 

The main script -- "script_hotindex.R" -- pulls in all the data files, generates the index for the current year, marries the data with census data and also pulls in the index ranking for each community from the previous year, then spits out JSON files for the online interactive.  Before running this script there are a lot of things that might need to updated. I tried to keep them at the top of the script and minimize the changes needed. The main thing is making sure all the right data is queued up in the "data" directory. 

Note on the 2018 index (published in January 2019):
We got the updated 2018 data from Arbit ahead of publication date, but he wasn't able to give us revisions to 2003 to 2015 data. We went ahead and published our index and data using the 2003 to 2015 data from last year, plus the 2016 to 2018 data we got just prior to publication.  

He sent the revised older data right after we published. I tried putting it in and running the script. It changed the results of our index. The only data from those older years that the index relies on is the price per square foot. It pulls the four prior years. So in this case, any changes to the 2014 and 2015 prices would have the ability to skew our index results slightly. 

So I saved a ppsf file named 'ppsf_usedforindex_Jan2019.csv' that has the ppsf data that we actually used for the index results that were published in January. All the other files in the data directory are currently updated to reflect the revisions from all years. 

