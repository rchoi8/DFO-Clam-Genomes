# Create Figure 1 Map for paper -------------------------------------------

#load libraries
library(tidyverse)
library(sf)
library(rnaturalearth)
library(viridis)
library(MarConsNetData)
library(ggspatial)
library(Mar.utils)
library(Mar.data)

source("https://raw.githubusercontent.com/dfo-mar-mpas/MCRG_functions/refs/heads/main/code/trim_img_ws.R")



#map projections
latlong <- "+init=epsg:4326 +proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs +towgs84=0,0,0"
CanProj <- "+proj=lcc +lat_1=49 +lat_2=77 +lat_0=63.390675 +lon_0=-91.86666666666666 +x_0=6200000 +y_0=3000000 +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +units=m +no_defs"

#download basemap
basemap <- ne_states(country = "Canada",returnclass = "sf")%>%
  dplyr::select(name_en,geometry)%>%
  st_as_sf()%>%
  st_union()%>%
  st_transform(latlong)%>%
  st_as_sf()%>%
  mutate(country="Canada")%>%
  rbind(.,ne_states(country = "United States of America",returnclass = "sf")%>%
          dplyr::select(name_en,geometry)%>%
          st_as_sf()%>%
          st_union()%>%
          st_transform(latlong)%>%
          st_as_sf()%>%
          mutate(country="US"),
        ne_states(country = "Greenland",returnclass = "sf")%>%
          dplyr::select(name_en,geometry)%>%
          st_as_sf()%>%
          st_union()%>%
          st_transform(latlong)%>%
          st_as_sf()%>%
          mutate(country="Greenland"),
        ne_states(country = "Iceland",returnclass = "sf")%>%
          dplyr::select(name_en,geometry)%>%
          st_as_sf()%>%
          st_union()%>%
          st_transform(latlong)%>%
          st_as_sf()%>%
          mutate(country="Iceland"))%>%
  st_transform(CanProj)


#load bathymetry contour
bathy_contours <- read_sf("~/GitHub/offfshore_wind/data/shapefiles/contour_250.shp")%>%st_transform(CanProj)

#load banks from Mar.data package
class(banks_sf)

clam_banks <- banks_sf %>%
  filter(Name %in% c("Banquereau Bank", "Grand Banks")) %>%
  st_transform(CanProj)

#Get NAFO divisions
NAFO <- read_sf("~/GitHub/Fundian/data/NAFO_Divisions_Shapefiles/Divisions.shp")%>%
  st_transform(CanProj)

plot_region <- c(-60, -50, 40, 50)
#plot map

p1 <- ggplot()+
  geom_sf(data=bathy_contours, colour="grey70")+
  geom_sf(data=basemap%>%filter(country == "Canada"),fill="grey60")+
  #geom_sf(data=NAFO, fill=NA)+
  geom_sf(data=clam_banks, fill="gold", alpha=0.7)+
  theme_bw()+
  coord_sf(xlim=c(-66,-46),ylim=c(39,52),default_crs = sf::st_crs(4326),
           datum = sf::st_crs(4326),
           expand=F)+
  theme_bw()+
  theme(panel.background = element_rect(fill= linearGradient(c("lightskyblue","steelblue"),
                                                             x1 = 0, y1 = 0, # Start at the far left edge
                                                             x2 = 1, y2 = 0 )),
        panel.grid.major = element_line(colour="grey90", linewidth = 0.3))+
  annotation_scale(location="br")+
  annotation_north_arrow(
    location = "br",                    # "tl" = Top-Left corner (can also use "tr", "bl", "br")
    which_north = "true",               # Aligns the arrow to true north based on your CRS
    pad_x = unit(0.3, "in"),            # Padding from the side margin
    pad_y = unit(0.4, "in"),            # Padding from the top margin
    width = unit(1, "cm"),
    height=unit(1, "cm"),
    style = north_arrow_orienteering(   # Style of the arrow
      fill = c("grey35", "white"),
      text_col = "grey20"
    )
    );p1

#save and clean it up
ggsave("results/Fig1_clambanks.png",p1,height=6,width=6,units="in",dpi=300)


