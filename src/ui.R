library(shiny)
library(leaflet)

# TODO: Add pre-commit hooks
# TODO: Get changes into GH
# TODO: Host
# TODO: Animate travel
# TODO: Remove extra travel after arrival on travel days
# TODO: Add eco region to data
# TODO: Ability to change marker color by: eco region, arrival/departure month, stay length
# TODO: Ability to change route color: month, length of drive, length of stay
# TODO: Marker size -> stay length
# TODO: Add hiking / activity / other driving days window or zoom in on it
# TODO: Add pictures from stops
# TODO: Include rest / fuel / tourist stops and such on travel days?

# source("src/process_data.R", local = new.env())

shinyUI(fluidPage(
    titlePanel("Trip MappR"),
    leafletOutput("map", height = 800)
))
