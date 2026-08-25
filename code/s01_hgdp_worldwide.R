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

Fst_pairwise <- read_csv("data/raw/hgdp/Fst_pairwise.csv",
                         show_col_types = FALSE)

fst_mat <- as.matrix(as.data.frame(Fst_pairwise)[, -1])
rownames(fst_mat) <- Fst_pairwise[[1]]
hgdpData <- getData(hgdp)

########################################
# 2. Standardise population names and identify shared populations
########################################

# HGDP-side rename
hgdpData$pop_canonical <- hgdpData$Population
hgdpData$pop_canonical[hgdpData$Population == "Han (pooled)"] <- "Han"

# FST-side rename
rownames(fst_mat)[rownames(fst_mat) == "NAN-Melanesian"] <- "Melanesian"
colnames(fst_mat)[colnames(fst_mat) == "NAN-Melanesian"] <- "Melanesian"

# intersection: 49 populations
shared_pops <- intersect(hgdpData$pop_canonical, rownames(fst_mat))

########################################
# 3. Subset both datasets to shared populations
########################################

fst_shared <- fst_mat[shared_pops, shared_pops]
keep <- hgdpData$pop_canonical %in% shared_pops
hgdp.sub <- hgdp[keep]
hgdp.sub@data$pop_canonical <- hgdpData$pop_canonical[keep]

# create the gData on a land-only worldgraph with uniform costs
myGraph  <- dropCosts(worldgraph.40k)
hgdp.sub <- setGraph(hgdp.sub, "myGraph")

########################################
# 4. Great-circle and land least-cost distances
########################################

coords <- getCoords(hgdp.sub)

# great-circle distance (km)
gc_dist <- sp::spDists(coords, longlat = TRUE)

# land-restricted least-cost distance (graph steps)
lcp_dist <- as.matrix(gPath2dist(dijkstraBetween(hgdp.sub)))

# label with canonical names and align both to the FST ordering
dimnames(gc_dist)  <- list(hgdp.sub@data$pop_canonical, hgdp.sub@data$pop_canonical)
dimnames(lcp_dist) <- list(hgdp.sub@data$pop_canonical, hgdp.sub@data$pop_canonical)
gc_dist  <- gc_dist[shared_pops, shared_pops]
lcp_dist <- lcp_dist[shared_pops, shared_pops]

########################################
# 5. Compare the distances with FST
########################################
mantel_r_gc  <- vegan::mantel(as.dist(fst_shared), as.dist(gc_dist),  method = "pearson")
mantel_r_lcp <- vegan::mantel(as.dist(fst_shared), as.dist(lcp_dist), method = "pearson")
mantel_r_gc$statistic   # 0.749
mantel_r_lcp$statistic  # 0.8671

########################################
# 6. Save outputs
########################################
out_dir <- "data/intermediate/hgdp_worldwide"
if (!dir.exists(out_dir)) dir.create(out_dir, recursive = TRUE)

saveRDS(hgdp.sub, file.path(out_dir, "hgdp.sub.rds"))
saveRDS(mantel_r_gc, file.path(out_dir, "mantel_r_gc"))
saveRDS(gc_dist, file.path(out_dir, "gc_dist"))
saveRDS(lcp_dist, file.path(out_dir, "lcp_dist"))
saveRDS(fst_shared, file.path(out_dir, "fst_shared"))
