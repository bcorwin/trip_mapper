library(shiny)
library(dplyr)
library(leaflet)

# Load data ####
processed_data_path <- file.path("..", "data", "processed")

stops <- readRDS(file.path(processed_data_path, "stops.Rds"))
routes <- readRDS(file.path(processed_data_path, "routes.Rds"))

# Shiny server ####
shinyServer(function(input, output) {

    ## Outputs ####
    ### Map ####
    output$map <- renderLeaflet({
      icon <- makeAwesomeIcon(
        icon='home',
        library='glyphicon',
        markerColor = 'blue',
        iconColor = 'black'
      )
      
      leaflet() %>%
        addTiles() %>%
        addAwesomeMarkers(
          data = stops,
          label = ~name,
          icon = icon
        ) %>% 
        addPolylines(data = routes)
    })
    
})
