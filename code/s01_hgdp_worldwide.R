#### worldwide case study ####
# Using the hgdp and worldgraph.40k we show that 
# limiting connections to land improves fit to 
# pairwise fst

library(geoGraph)
library(readr)
library(vegan)

set.seed(1)  

########################################
# 1. Load FST matrix and HGDP data
########################################

data(hgdp)
data(fst_hgdp)

########################################
# 2. Great-circle and land least-cost distances
########################################

coords   <- getCoords(hgdp)
gc_dist  <- sp::spDists(coords, longlat = TRUE)
lcp_dist <- as.matrix(gPath2dist(dijkstraBetween(hgdp)))

########################################
# 3. Compare the distances with FST
########################################

# label with population names (gData order)
dimnames(gc_dist)  <- list(hgdp@data$Population, hgdp@data$Population)
dimnames(lcp_dist) <- list(hgdp@data$Population, hgdp@data$Population)

# align all three matrices to a common population order
pops     <- rownames(fst_hgdp)
gc_dist  <- gc_dist[pops, pops]
lcp_dist <- lcp_dist[pops, pops]

mantel_r_gc  <- vegan::mantel(as.dist(fst_hgdp), as.dist(gc_dist),  method = "pearson")
mantel_r_lcp <- vegan::mantel(as.dist(fst_hgdp), as.dist(lcp_dist), method = "pearson")
mantel_r_gc$statistic #0.7419885
mantel_r_lcp$statistic #0.8437712

########################################
# 4. Save outputs
########################################
out_dir <- "data/intermediate/hgdp_worldwide"
if (!dir.exists(out_dir)) dir.create(out_dir, recursive = TRUE)

saveRDS(mantel_r_gc, file.path(out_dir, "mantel_r_gc.rds"))
saveRDS(gc_dist, file.path(out_dir, "gc_dist.rds"))
saveRDS(lcp_dist, file.path(out_dir, "lcp_dist.rds"))

