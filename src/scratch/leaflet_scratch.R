library(leaflet)

source("stops.R")
source("routes.R")

stops <- get_stops()
routes <- get_routes(stops)

icon <- makeAwesomeIcon(
  icon='home',
  library='glyphicon',
  markerColor = 'blue',
  iconColor = 'black'
)

leaflet(data = stops) %>%
  addTiles() %>%
  addAwesomeMarkers(
    label = ~name,
    lng = ~long,
    lat = ~lat,
    icon = icon
  ) %>% 
  addPolylines(data = routes)




