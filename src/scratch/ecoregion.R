library(sf)
library(dplyr)

eco_regions <- st_read("data/na_cec_eco_l2", layer = "NA_CEC_Eco_Level2")
eco_regions <- st_read("data/na_cec_eco_l1", layer = "NA_CEC_Eco_Level1")


eco_regions <- st_transform(eco_regions, 2163)-
str(eco_regions)

library(leaflet)
leaflet(data = eco_regions %>% sample_n(10)) %>%
  addTiles() %>%
  addPolygons()
