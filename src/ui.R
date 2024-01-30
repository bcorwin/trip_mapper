library(shiny)
library(leaflet)

# TODO: Host
# TODO: Animate travel
# TODO: Remove extra travel after arrival on travel days
# TODO: Add eco region to data
# TODO: Change marker color by: eco region, arrival/departure month, stay length
# TODO: Change route color: month, length of drive, length of stay
# TODO: Marker size -> stay length
# TODO: Add hiking / activity / other driving days window or zoom in on it
# TODO: Add pictures from stops
# TODO: Include rest / fuel / tourist stops and such on travel days?

if (FALSE) source("src/process_data.R", local = new.env())

shinyUI(fluidPage(
  titlePanel("Trip MappR"),
  leafletOutput("map", height = 800)
))
