# Libraries ####

library(magrittr)
library(dplyr)
library(rjson)
library(sf)

# Parameters ####
raw_data_path <- file.path("data", "raw")
processed_data_path <- file.path("data", "processed")

# Functions ####
get_stops <- function() {
  
  # TODO: Automate this (API or directly download?)
  trello_data <- fromJSON(file = file.path(raw_data_path, "0qMwrQwk.json"))
  
  trello_lists <- lapply(trello_data[["lists"]],
                         function(x) data.frame(
                           list_id = x$id,
                           list_name = x$name
                         )
  )
  trello_lists <- do.call(rbind, trello_lists)
  
  trello_cards_list <- lapply(trello_data[["cards"]],
                              function(x) data.frame(
                                card_id = x$id,
                                name = x$name,
                                arrival = coalesce(x$start, NA),
                                departure = coalesce(x$due, NA),
                                lat = coalesce(x$coordinates[["latitude"]], NA),
                                long =  coalesce(x$coordinates[["longitude"]], NA),
                                list_id = x$idList,
                                archived = x$closed
                              )
  )
  
  trello_cards <-  do.call(rbind, trello_cards_list) %>%
    left_join(trello_lists, by = "list_id")
  
  trello_cards %<>%
    filter(
      !archived, 
      list_name %in% c("Booked", "Done"),
      !is.na(lat) & !is.na(long),
      departure >= as.Date("2023-07-09"),
      departure <= Sys.Date()
    ) %>%
    mutate(
      arrival = as.Date(arrival),
      departure = as.Date(departure),
      route_file = format(arrival, "%Y-%m-%d"),
      arrival_month = lubridate::month(arrival),
      stay_length = as.numeric(departure - arrival),
      
    ) %>%
    arrange(arrival) %>%
    st_as_sf(coords = c("long", "lat"), crs = 4326)
  
  trello_cards
}

get_routes <- function(stops) {
  
  all_route_files <- list.files(file.path(raw_data_path, "routes"), full.names = TRUE)
  
  all_routes <- lapply(all_route_files, sf::st_read, quiet = TRUE)
  names(all_routes) <- stringr::str_extract(
    all_route_files,
    "history-(\\d{4}-\\d{2}-\\d{2})",
    group = 1
  )
  
  all_routes <- bind_rows(all_routes, .id = "route_file") %>%
    st_collection_extract("LINESTRING") %>%
    filter(route_file %in% stops$route_file) %>%
    mutate(geometry = st_zm(geometry)) %>%
    st_cast("POINT") %>%  # Group days' routes into one linestring
    group_by(route_file) %>%
    summarize(do_union=FALSE) %>%
    st_cast("LINESTRING")
  
  # TODO: :filter out any after stop  
  
  as(all_routes, "Spatial")
}


# Process data ####
stops <- get_stops()
routes <- get_routes(stops)

# Save data ####
saveRDS(stops, file.path(processed_data_path, "stops.Rds"))
saveRDS(routes, file.path(processed_data_path, "routes.Rds"))
