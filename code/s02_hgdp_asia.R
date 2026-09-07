#### asia case study ####
# Custom gGraph for Central/South + East Asia HGDP populations:
# shows that, within a single landmass, accounting for terrain ruggedness
# improves the fit between geographic and genetic distance.

library(geoGraph)
library(terra)
library(sf)
library(elevatr)
library(readr)
library(vegan)
library(dplyr)

set.seed(1)  

########################################
# 1. Build a hexagonal grid over Asia
########################################

aoi.bound <- st_sf(geometry = st_as_sfc(
  st_bbox(c(xmin = 55, xmax = 145, ymin = 5, ymax = 70), crs = 4326)
))

hexGraph <- makeHexGrid(geo.box = aoi.bound, spacing = 55)
hexGraph <- findLand(hexGraph)
hexGraph <- setColors(hexGraph, data.frame(
  habitat = c("sea", "land"),
  color   = c("#b0d4e8", "#90c090")
))

# sea cells cost 100, land cells cost 1 then drop the sea edges
hexGraph <- setCosts(hexGraph, method = "mean", attr.name = "habitat",
                     cost.rules = data.frame(habitat = c("sea", "land"),
                                             cost    = c(100, 1)))
hexGraph <- dropDeadEdges(hexGraph, thres = 100)

########################################
# 2. Add per-node ruggedness (SD of elevation)
########################################

elevation.data <- get_elev_raster(locations = aoi.bound, z = 4, clip = "locations")
spatr <- rast(elevation.data)

elevGraph <- assignByRaster(graph = hexGraph, raster = spatr,
                            layer.name = "elevation", fun = "sd")

# set sea nodes and missing values to zero ruggedness
node_attr <- getNodesAttr(elevGraph)
is_sea    <- as.character(node_attr$habitat) == "sea"
node_attr$elevation[is_sea] <- 0
node_attr$elevation[is.na(node_attr$elevation)] <- 0
elevGraph@nodes.attr <- node_attr

########################################
# 3. HGDP Asia subset and FST matrix
########################################

data(fst_hgdp)
data(hgdp)

# Continental East Asian + Central/South Asian populations 
asia <- hgdp[hgdp@data$Region %in% c("EAST_ASIA", "CENTRAL_SOUTH_ASIA")]
asia <- asia[!asia@data$Population %in% c("Japanese"), ] #keep only continental pops

asia_data  <- asia@data 
pops       <- asia_data$Population #25 populations
fst_shared <- fst_hgdp[pops, pops]

# Create new gData object with populations and gGraph
coords <- data.frame(lon = asia_data$Longitude, lat = asia_data$Latitude)
asiaGD <- new("gData", coords = coords, data = asia_data, gGraph.name = "elevGraph")

########################################
# 5. Grid search for the best ruggedness threshold
########################################

base_habitat <- getNodesAttr(elevGraph)$habitat  # snapshot before reclassification
sd_ele       <- getNodesAttr(elevGraph)$elevation

run_threshold <- function(threshold) {
  # reclassify cells above the threshold as 'rugged' (high cost)
  habitat_new <- dplyr::case_when(
    base_habitat == "sea" ~ "sea",
    is.na(sd_ele)         ~ "land",
    sd_ele > threshold    ~ "rugged",
    TRUE                  ~ "land"
  )
  g_local <- setNodesAttr(elevGraph, attr.name = "habitat", values = habitat_new)
  g_local <- setCosts(g_local, method = "mean", attr.name = "habitat",
                      cost.rules = data.frame(habitat = c("sea", "land", "rugged"),
                                              cost    = c(100, 1, 100)))
  
  # expose the graph by name so the gData can resolve it
  assign(".gg_current_graph", g_local, envir = globalenv())
  on.exit(rm(".gg_current_graph", envir = globalenv()), add = TRUE)
  
  gd <- asiaGD
  gd@gGraph.name <- ".gg_current_graph"
  
  tryCatch({
    d <- as.matrix(gPath2dist(dijkstraBetween(gd)))
    dimnames(d) <- list(pops, pops)                     
    d <- d[rownames(fst_shared), colnames(fst_shared)]  
    cor(as.numeric(as.dist(fst_shared)),
        as.numeric(as.dist(d)), method = "pearson")    
  })
}

# sweep thresholds across the upper quantiles of the ruggedness distribution
thresholds <- quantile(sd_ele, probs = seq(0.7, 0.999, by = 0.001), na.rm = TRUE)
profile <- data.frame(
  quantile  = names(thresholds),
  threshold = as.numeric(thresholds),
  mantel_r  = vapply(as.numeric(thresholds), run_threshold, numeric(1))
)

########################################
# 6. Build the ruggedness-weighted graph at the best threshold
########################################

best_idx       <- which.max(profile$mantel_r)
best_threshold <- round(profile$threshold[best_idx], 1)  # 580.1

habitat_final <- dplyr::case_when(
  base_habitat == "sea"   ~ "sea",
  is.na(sd_ele)           ~ "land",
  sd_ele > best_threshold ~ "rugged",
  TRUE                    ~ "land"
)

optiGraph <- setNodesAttr(hexGraph, attr.name = "habitat", values = habitat_final)
optiGraph <- setColors(optiGraph, data.frame(
  habitat = c("sea", "land", "rugged"),
  color   = c("#b0d4e8", "#90c090", "#8b6340")
))
optiGraph <- setCosts(optiGraph, method = "mean", attr.name = "habitat",
                      cost.rules = data.frame(habitat = c("sea", "land", "rugged"),
                                              cost    = c(100, 1, 100)))
plot(optiGraph, reset = TRUE)

########################################
# 7. Distances and Mantel tests
########################################

hgdp.sub.raw <- setGraph(asiaGD, "hexGraph")   # plain land grid
hgdp.sub.ele <- setGraph(asiaGD, "optiGraph")  # ruggedness-weighted grid

gc_dist   <- sp::spDists(getCoords(asiaGD), longlat = TRUE)           # great-circle (km)
lcp_dist  <- as.matrix(gPath2dist(dijkstraBetween(hgdp.sub.raw)))     # plain land least-cost
rugg_dist <- as.matrix(gPath2dist(dijkstraBetween(hgdp.sub.ele)))     # ruggedness-weighted least-cost

# label with population names and align all matrices to the FST ordering
dimnames(gc_dist)   <- list(pops, pops)
dimnames(lcp_dist)  <- list(pops, pops)
dimnames(rugg_dist) <- list(pops, pops)

gc_dist   <- gc_dist[rownames(fst_shared), colnames(fst_shared)]
lcp_dist  <- lcp_dist[rownames(fst_shared), colnames(fst_shared)]
rugg_dist <- rugg_dist[rownames(fst_shared), colnames(fst_shared)]

mantel_r_gc   <- vegan::mantel(as.dist(fst_shared), as.dist(gc_dist),   method = "pearson")
mantel_r_lcp  <- vegan::mantel(as.dist(fst_shared), as.dist(lcp_dist),  method = "pearson")
mantel_r_rugg <- vegan::mantel(as.dist(fst_shared), as.dist(rugg_dist), method = "pearson")

mantel_r_gc$statistic    # 0.548  great-circle
mantel_r_lcp$statistic   # 0.536  plain land least-cost
mantel_r_rugg$statistic  # 0.700  ruggedness-weighted least-cost

########################################
# 8. Save outputs
########################################
out_dir <- "data/intermediate/hgdp_asia"
if (!dir.exists(out_dir)) dir.create(out_dir, recursive = TRUE)

saveRDS(hexGraph,     file.path(out_dir, "hexGraph.rds"))
saveRDS(elevGraph,     file.path(out_dir, "elevGraph.rds"))
saveRDS(optiGraph,     file.path(out_dir, "optiGraph.rds"))
saveRDS(asiaGD,        file.path(out_dir, "asiaGD.rds"))
saveRDS(profile,       file.path(out_dir, "profile.rds"))
saveRDS(mantel_r_gc,   file.path(out_dir, "mantel_r_gc.rds"))
saveRDS(mantel_r_lcp,  file.path(out_dir, "mantel_r_lcp.rds"))
saveRDS(mantel_r_rugg, file.path(out_dir, "mantel_r_rugg.rds"))