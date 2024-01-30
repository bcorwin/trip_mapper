
library(sf)
library(dplyr)

get_routes <- function(stops) {
  
  all_route_files <- list.files("data/routes/", full.names = TRUE)
  
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
  
  # filter out any after stop  
  
  as(all_routes, "Spatial")
}

class(all_routes$geometry)



i <- 30  # Malibu
i <- 10 # Moab
route <- all_routes[i,]
route

remove_end <- function(g) {
  g[1:2]
}

purrr::modify(all_routes$geometry, .f = remove_end)

all_routes$geometry[[1]][1]




filter_route <- function(route) {
  day_points <- route %>%
    st_cast("POINT") %>%
    st_set_crs(st_crs(stops))
  
  
  
  
  
  arrival_location_index <- data.frame(
    distance = st_distance(stops[i, ], day_points)[1,]
  ) %>%
    mutate(
      index = row_number(),
      closest = min(distance) == distance
    ) %>%
    filter(closest) %>%
    slice(1) %>%
    pull(index)
  
  filtered_route <- head(day_points, arrival_location_index) %>%
    group_by(route_file) %>%
    summarize(do_union=FALSE) %>%
    st_cast("LINESTRING")
  
}

all_routes %>%
  mutate(geometry2 = filter_route(geometry))


leaflet(data=filtered_route) %>% addTiles() %>% addPolylines()
