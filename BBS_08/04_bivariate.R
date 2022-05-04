# paquetes
library(tidyverse)
library(sf)
library(biscale)
library(patchwork)
library(terra)
library(janitor)

## -------------------------------------------------


# raster de CORINE LAND COVER 2018
urb <- rast("./data/U2018_CLC2018_V2020_20u1.tif")

# datos de renta y Gini
renta <- read_csv2("./data/30824.csv") %>% clean_names()
edad <- read_csv2("./data/30832.csv") %>% clean_names()

# límites censales del INE y municipios
limits <- st_read("./data/SECC_CE_20200101.shp") 
muni <- st_read("./data/au_AdministrativeUnit_4thOrder0.gml") 



## -------------------------------------------------
# filtramos la Comunidad Autanoma de Madrid
limits <- filter(limits, NCA == "Comunidad de Madrid")


## -------------------------------------------------
# proyectamos los limites 
limits_prj <- st_transform(limits, crs(urb))

# acortamos y enmascaramos 
urb_mad <- crop(urb, limits_prj) %>% 
              mask(vect(limits_prj))

# eliminamos pixeles no urbanos 
urb_mad[!urb_mad %in% 1:2] <- NA 

# plot del raster
plot(urb_mad)

# proyectamos 
urb_mad <- project(urb_mad, "EPSG:25830")


## -------------------------------------------------
# transformamos el raster a xyz y objeto sf 
urb_mad_sf <- as.data.frame(urb_mad, xy = TRUE) %>%
                st_as_sf(coords = c("x", "y"), crs = 25830)


## -------------------------------------------------
## datos renta y edad media

renta_sec <- mutate(renta, GEOCODE = str_extract(unidades_territoriales, 
                                                 "[0-9]{5,10}"),
                    nc_len = str_length(GEOCODE),
                    mun_name = str_remove(unidades_territoriales, 
                                          GEOCODE) %>% str_trim()) %>%
             filter(nc_len > 5)

edad_sec <- mutate(edad, GEOCODE = str_extract(unidades_territoriales, 
                                               "[0-9]{5,10}"), 
               nc_len = str_length(GEOCODE),
               mun_name = str_remove(unidades_territoriales, 
                                     GEOCODE) %>% str_trim()) %>%
             filter(nc_len > 5)


## -------------------------------------------------
renta_sec <- filter(renta_sec, 
                    indicadores_de_renta_media == "Renta neta media por persona",
                    periodo == 2019) %>% 
            select(GEOCODE, renta = total) %>%
             mutate(renta = parse_number(renta, 
                                       locale = locale(decimal_mark = ",", 
                                                       grouping_mark = ".")))

edad_sec <- filter(edad_sec, 
                    indicadores_demograficos == "Edad media de la poblaciÃ³n",
                    periodo == 2019) %>% 
            select(GEOCODE, edad = total) %>% 
            mutate(edad = parse_number(edad, 
                                       locale = locale(decimal_mark = ",", 
                                                       grouping_mark = ".")))


## -------------------------------------------------
# unimos ambas tablas de renta y edad media con los limites censales
mad <- left_join(limits, renta_sec, by = c("CUSEC"="GEOCODE")) %>% 
          left_join(edad_sec, by = c("CUSEC"="GEOCODE"))


## -------------------------------------------------
## creamos clasificacion bivariante
mapbivar <- bi_class(mad, renta, edad, style = "quantile", dim = 3) %>% 
             mutate(bi_class = ifelse(str_detect(bi_class, "NA"), NA, bi_class))

# resultado
head(dplyr::select(mapbivar, renta, edad, bi_class))


## -------------------------------------------------
## redistribuimos los pixeles urbanos a la desigualdad
mapdasi <- st_join(urb_mad_sf, mapbivar)


## -------------------------------------------------
# leyenda bivariante
legend2 <- bi_legend(pal = "DkViolet",
                     dim = 3,
                     xlab = "Más renta",
                     ylab = "Más edad",
                     size = 9)


## -------------------------------------------------
muni <- filter(muni, str_sub(nationalCode, 3, 4) == 13) %>%
            st_transform(25830) 
          


## -------------------------------------------------
legend_pos <- st_bbox(c(xmin = -3.25,  ymin = 40.55, 
                        xmax = -2.65, ymax = 40.95), crs = 4326) %>% 
                st_as_sfc() %>% 
                st_transform(25830) %>% 
                st_bbox()

legend_pos


## -------------------------------------------------
p2 <- ggplot(mapdasi) + 
  geom_tile(aes(fill = bi_class,
                geometry = geometry), 
            stat = "sf_coordinates",
            show.legend = FALSE) +
  geom_sf(data = muni,  
          color = "grey70", 
          fill = NA, 
         size = 0.1) +
  annotation_custom(ggplotGrob(legend2), 
                    xmin = legend_pos[1], xmax = legend_pos[3],
                    ymin = legend_pos[2], ymax = legend_pos[4]) +
  bi_scale_fill(pal = "DkViolet", 
                dim = 3, 
                na.value = "grey90") +
  labs(title = "dasimÃ©trico", x = "", y = "") +
  theme_void(base_family = "Bahnschrift") +
  theme(plot.title = element_text(hjust = .5,
                                  size = 30, 
                                  face = "bold")
        
        ) +
  coord_sf()



## -------------------------------------------------
p1 <- ggplot(mapbivar) + 
  geom_sf(aes(fill = bi_class), 
          colour = NA, 
          size = .1, 
          show.legend = FALSE) +
  geom_sf(data = muni,  
          color = "white", 
          fill = NA, 
          size = 0.1) +
  bi_scale_fill(pal = "DkViolet", 
                dim = 3, 
                na.value = "grey90") +
  labs(title = "coroplÃ©tico",  x = "", y ="") +
  bi_theme(base_family = "Bahnschrift") +
  theme(plot.title = element_text(hjust = .5,
                                  size = 30, 
                                  face = "bold")
        
        ) +
  coord_sf()


## -------------------------------------------------
# Combinamos
p <- p1 | p2

p

