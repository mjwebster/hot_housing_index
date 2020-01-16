# hot_housing_index
This contains the R scripts and Markdown page for the annual "hot housing index" that we run each January or early February. 

The primary data we use for the index comes from David Arbit at the Minneapolis Area Association of Realtors. He sends an end-of-year file - in Excel - that has several sheets worth of data on various metrics for home sales in communities in the metro area. It's important to ask David if he can provide all this data at least several days in advance of the press conference that they hold when releasing this data to the public. In fact, put in this request with David in December, if possible, before he gets busy in the weeks leading up to the press conference.

We decided to only include incorporated cities (no townships) from the 13-county metro area. There is a file called "city_crosswalk" that has the names of all the cities in the Realtors data and matches it to the Census fips codes for places. There is also a field called "County13" where I have manually said "y" or "n" to include in the analysis. This also includes the neighborhoods of St. Paul and Minneapolis because we included them in the interactive (but not the index).

Starting with the 2019 data, we asked David to provide us three batches of data (and they come all in one file) -- one if all the metrics for all sales of existing homes in the metro area (excludes sales of new construction); one is for existing home sales where price was below $300,000 (the starter homes); and one for the "moveup" homes priced between $300,000 and 750,000. 

Because we were changing the index anyway, we also eliminated one metric (the percent of distressed sales) and added a new one (percent change in closed sales) to account for the changing market. When we first started this, there were still a lot of pockets with high shares of foreclosures (that has gone away) and now the market is cooling and places with increases in closed sales or a slower decline rate are buoyed in the index by including this metric. 

The data that Arbit provides goes back 5 years. Due to the change in the underlying data (no new construction) we can't compare these most recent years with our older data. 

Other data:
The R script pulls in Census (ACS 5-year) data for the metro as a whole and all places in the metro (including the Wisconsin counties) for median household income (B19013), pct of homeowners who are cost-burdened, paying 30% or more of income on housing costs (B25106), median home values (B25077) and homeownership rates (B25003). This data is used in charts for each city (plotting the city against the rest of the metro). 

We also need to get from Arbit the latest metro-wide "days on market" year-end metric and the median price per square foot metric. This is for the 16-county metro. These are used in 2 charts -- the display ones at the top of the page and as contextual lines in the city-specific charts. Numbers for prior years are stored in an Excel file, so you just need to add the current year to the file. 

Also need median sale price, and end of year inventory to use in charts on the web page.

Output needed for the web page:
1) hot_housing_index_json -- This file contains all of the cities that were included in the overall hot housing index (only cities with 70 or more sales last year), which typically comes out to about 100 cities. It includes the key metrics from the index, as well as values that are auto-filled into a block of text the is displayed when you select a city. This includes the county(s) where the city is located, the index ranking, the percent change in price per square foot, the difference (in days) in the days on market compared to the previous years, the average percentage of original list price received by sellers. It also includes the census metrics needed for the charts at the bottom of the page (median home values, median household income, percent home ownership, percent cost-burdened owners). 

2) timeseries_json -- this file contains the historical metrics for each city that is needed for the "historical real estate trends..." charts. The first two charts -- median days on market and median sale price per square foot -- display both the selected city and the metro as a whole. The data for the metro as a whole comes from a separate source, but the R script merges it together with the city data before spitting out the JSON file.  The other two charts - annual closed sales and homes for sale (inventory) -- can only display the selected city because these are raw numbers and the scale would be wildly off (i.e. 25 sales in the city compared to 10s of thousands in the metro as a whole). 


3) We need to get separate data from Arbit for the 4 metro-wide charts, showing historical trends, that are at the top of the web page. These show median days on market, percent of newly built homes sold through the MLS (we may need to ditch this one), median sale price and end of year inventory. 




