library(tidyverse)
library(sf)
library(leaflet)
library(here)

get_shape <- function(URL, geometry = TRUE){
    temp <- tempfile()
    temp_dir <- tempfile()
    download.file(URL, destfile = temp)
    unzip(temp, exdir = temp_dir)
    
    out_shape <- st_read(temp_dir)
    if(geometry == FALSE) out_shape <- out_shape %>% st_drop_geometry() %>% as_tibble()

    return(out_shape)
    on.exit({file.remove(temp)
        unlink(temp_dir)}, add = TRUE)
}

# Get tracts
de_tracts_URL <- "https://www2.census.gov/geo/tiger/GENZ2018/shp/cb_2018_10_tract_500k.zip"
de_tracts <- get_shape(de_tracts_URL)
# de_blocks_URL <- "https://www2.census.gov/geo/tiger/TIGER2020/TABBLOCK20/tl_2020_10_tabblock20.zip"
# de_blocks <- get_shape(de_blocks_URL)
delaware_places_URL <- "https://www2.census.gov/geo/tiger/TIGER2020/PLACE/tl_2020_10_place.zip"
de_places <- get_shape(delaware_places_URL)

# Default anchor for the leaflet view

# Plot leaflet map for Newark for the example
leaflet_default <-  leaflet() %>%
    addProviderTiles(providers$CartoDB.Positron)

# Join the tracts with places
joined <- de_tracts %>% 
    st_join(de_places, join = st_intersects, 
            suffix = c("_tract", "_place"))

joined_nogeo <- joined %>%
    st_drop_geometry()

# Save the output
write_rds(joined, here("output/de_tract_places_geo.rds"))
write_rds(joined_nogeo, here("output/de_tract_places_nogeo.rds"))


# Plot Newark
leaflet_default %>%
    addPolygons(data = de_places %>% filter(NAME == "Newark"), color = "red", popup = ~NAME) %>% 
    addPolygons(data = joined %>% filter(NAME_place == "Newark"), 
                popup = ~NAME_place,
                highlight = highlightOptions(fillOpacity = 0.8,
                                             weight = 2))


# ## Blocks
# joined <- de_blocks %>% 
#     st_join(de_places, join = st_intersects, 
#             suffix = c("_tract", "_place"))
# 
# leaflet_default %>%
#     addPolygons(data = de_places %>% filter(NAME == "Newark"), color = "red", popup = ~NAME) %>% 
#     addPolygons(data = joined %>% filter(NAME == "Newark"), 
#                 popup = ~NAME,
#                 highlight = highlightOptions(fillOpacity = 0.8,
#                                              weight = 2))
# 

# # Plot tracts and places files separately
# leaflet_default %>%
#     addPolygons(data = de_tracts,
#                 highlight = highlightOptions(fillOpacity = 0.8,
#                                              weight = 2)) %>% 
#     addPolygons(data = de_places,
#                 color = "red")
