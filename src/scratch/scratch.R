# TODO: show future plans (non booked) in a different color, label as State (Month)
# TODO: use dotted lines between future plans (when no kml available in general)
# TODO: animate
# TODO: combine this with the weather mapper?
# TODO: add in eco regions to see where we're staying (and hiking?). DO KOPPEN INSTEAD

library(ggplot2)
library(ggmap)
library(maps)
library(mapdata)
library(sf)
library(maptools)
library(dplyr)
library(readr)
library(tidyr)
library(gganimate)
library(rjson)
library(vistime)

usa <- map_data("state")
base_map <- ggplot() +
  geom_polygon(
    data = usa,
    aes(x=long, y = lat, group = group),
    fill = "white",
    color = "grey"
  ) + 
  coord_fixed(1.3) +
  theme_nothing()

chk <- st_read("routes/history-2023-07-10.kml")

eco_level <- 1
if(eco_level == 1) {
  eco_regions <- st_read("na_cec_eco_l1", layer = "NA_CEC_Eco_Level1")
  eco_regions$eco_region <- eco_regions$NA_L1NAME
  eco_region_colors <- c(
    "#0000FF",
    "#5d9ad1",
    "#ffdb71",
    "#d1e8ba",
    "#dfd696",
    "#bbdd90",
    "#fd7f62",
    "#c975b8",
    "#99b4dd",
    "#8dcfee",
    "#44bac3",
    "#ace5e8",
    "#5dc15a",
    "#4dcac2",
    "#bbdd90",
    "#fece9f"
  )
} else if(eco_level == 2) {
  eco_regions <- st_read("na_cec_eco_l2", layer = "NA_CEC_Eco_Level2")
  eco_regions$eco_region <- eco_regions$NA_L2NAME
} else if(eco_level == 3) {
  eco_regions <- st_read("us_eco_l3", layer = "us_eco_l3")
  eco_regions$eco_region <- eco_regions$NA_L3NAME
}
eco_regions <- st_transform(eco_regions, 2163)

# fix this! levels needs to be unique in the order I want
eco_regions$eco_region <- ordered(eco_regions$eco_region, 
                                  levels = eco_regions$NA_L1CODE,
                                  labels = eco_regions$eco_region)

read_kml <- function(file_name) {
  kml_route <- getKMLcoordinates(file_name)
  route_coords <- lapply(kml_route, as.data.frame)
  route_coords <- bind_rows(route_coords)
  route_coords$V3 <- NULL
  colnames(route_coords) <- c("long", "lat")
  route_coords$file_name <- sub("\\.kml", "", basename(file_name))
  route_coords
}

trello_data <- fromJSON(file = "trello_exports/0qMwrQwk.json")

trello_lists <- lapply(trello_data[["lists"]],
                       function(x) data.frame(
                         list_id = x$id,
                         list_name = x$name
                       )
                 )
trello_lists <- do.call(rbind, trello_lists)

trello_cards <- lapply(trello_data[["cards"]],
                       function(x) data.frame(
                         card_id = x$id,
                         name = x$name,
                         arrival = coalesce(x$start, NA),
                         departure = coalesce(x$due, NA),
                         lat = coalesce(x$coordinates[["latitude"]], NA),
                         long =  coalesce(x$coordinates[["longitude"]], NA),
                         list_id = x$idList
                       )
                )
trello_cards <- do.call(rbind, trello_cards) %>%
  left_join(trello_lists, by = "list_id")

stops <- read_csv("stops.csv", show_col_types = FALSE) %>%
  filter(show == 1) %>%
  replace_na(list(vjust = 0.5)) %>%
  left_join(trello_cards, "card_id", suffix = c("", "_card")) %>%
  mutate(
    lat = coalesce(lat, lat_card),
    long = coalesce(long, long_card),
    arrival = as.Date(arrival),
    route_file = format(arrival, "history-%Y-%m-%d"),
    arrival_month = lubridate::month(arrival)
  )

# Identify eco region for stops
lat_long_to_sf_pt <- function(long, lat) {
  mapply(
    function(long, lat) {
      st_transform(st_sfc(st_point(c(long, lat)),crs = 4326), 2163)
    },
    long = long,
    lat=lat
  )
}
stop_pts <- lat_long_to_sf_pt(stops$long, stops$lat)
poly_num <- sapply(stop_pts, function(pt) st_intersects(pt, eco_regions))
poly_num <- sapply(poly_num, function(x) x[1])
stops$eco_region <- eco_regions[poly_num, ]$eco_region

# Make a plot with colors
stops %>%
  group_by(eco_region) %>%
  count() %>%
  arrange(n)

# Get driven routes
route_files <- list.files("routes", pattern = "\\.kml$", full.names = TRUE)
all_routes <- bind_rows(lapply(route_files, read_kml))

stops$route_file = if_else(stops$route_file %in% unique(all_routes$file_name),
                           stops$route_file,
                           NA)

all_routes <- all_routes %>%
  filter(file_name %in% stops$route_file) %>%
  left_join(
    select(stops, route_file, arrival_month),
    by=c("file_name"="route_file")
  ) %>%
  mutate(arrival_month = as.character(arrival_month))

future_routes <- stops %>%
  filter(!is.na(lat)) %>%
  mutate(
    lat_prev = lag(lat),
    long_prev = lag(long)
  ) %>%
  filter(is.na(route_file) & !is.na(lat_prev))

p <- base_map +
  geom_point(data = all_routes, aes(x=long, y=lat, color=arrival_month), size = 1) +
  scale_colour_brewer(palette="Set3") +
  geom_segment(data=future_routes, aes(x=long_prev, y=lat_prev, xend=long, yend=lat), lty="longdash") +
  geom_point(data=stops, aes(x=long, y=lat, fill=list_name), size=3) +
  geom_text(data=stops, aes(x=long, y=lat, label=name, hjust=hjust, vjust=vjust), color="black", size=4.5)

p

 

stops %>%
  arrange(arrival) %>%
  mutate(
    arrival = as.Date(arrival),
    departure = as.Date(departure),
    name = glue::glue("{name}\n{arrival} to {departure}"),
    # group = row_number() %% 2,
  ) %>%
  filter(
    departure >= Sys.Date(),
    arrival <= Sys.Date() + 90
  ) %>%
  gg_vistime(
    col.event = "name",
    col.start = "arrival",
    col.end = "departure",
    optimize_y = FALSE
  )


