#### manuscript figures ####
# code for figure 2 and 3

library(ggplot2)
library(sf)
library(geoGraph)

########################################
# Fig. 2a
########################################

# get the output from s01
hgdp.sub <- readRDS("data/intermediate/hgdp_worldwide/hgdp.sub.RDS")
myGraph  <- dropCosts(worldgraph.40k)
hgdp.sub <- setGraph(hgdp.sub, "myGraph")

origin.gd   <- hgdp.sub[getData(hgdp.sub)$Population %in% "Druze"]
origin.node <- getNodes(origin.gd)
paths <- dijkstraFrom(hgdp.sub, origin.node)
origin_sf <- st_as_sf(
  as.data.frame(getCoords(worldgraph.40k)[origin.node, , drop = FALSE]),
  coords = c("lon", "lat"), crs = 4326
)

# set projection parameters
lon0 <- 55; lat0 <- 55 #center of plot
ortho_crs <- sprintf("+proj=ortho +lat_0=%s +lon_0=%s +ellps=sphere +units=m +no_defs",
                     lat0, lon0)
R <- 6371000  # sphere radius (matches +ellps=sphere)

## ocean as a filled disc of Earth radius in the ortho plane
ocean <- st_sf(geometry = st_sfc(st_buffer(st_point(c(0, 0)), R), crs = ortho_crs))

## graticule built in lon/lat; coord_sf clips it to the visible hemisphere
grat <- st_graticule(lat = seq(-90, 90, 15), lon = seq(-180, 180, 15))

fig2a <- ggplot() +
  geom_sf(data = ocean, fill = "#EAF2FB", colour = "grey45", linewidth = 0.4) +
  geom_sf(data = grat,  colour = "grey80", linewidth = 0.2) +
  geom_ggraph(data = worldgraph.40k, aes(colour = habitat),
              edges = FALSE, size = 0.15) +
  scale_colour_manual(values = c(land = "grey60"), na.value = "transparent",
                      guide = "none") +
  geom_gpath(data = paths, colour = "firebrick", linewidth = 0.5) +
  geom_gdata(data = hgdp.sub, colour = "black", size = 1.2) +
  geom_sf(data = origin_sf, colour = "dodgerblue", size = 3) +
  coord_sf(crs = ortho_crs) +
  theme_void()

ggsave("results/fig2a.png", plot = fig2a,
       width = 6, height = 6, units = "in", dpi = 300, bg = "white")

########################################
# Fig. 2b 
########################################

# get the output from s01
lcp_dist <- readRDS("data/intermediate/hgdp_worldwide/lcp_dist")
gc_dist <- readRDS("data/intermediate/hgdp_worldwide/gc_dist")
fst_shared <- readRDS("data/intermediate/hgdp_worldwide/fst_shared")

## make all three plain numeric vectors in the same (dist) order
fst   <- as.vector(as.dist(fst_shared))
d_gc  <- as.vector(as.dist(gc_dist))
d_lcp <- as.vector(as.dist(lcp_dist))          

png("results/fig2b.png", width = 8, height = 4, units = "in", res = 300)

par(mfrow = c(1, 2), mar = c(4, 4, 2, 1))
plot(d_gc, fst, pch = 19, col = adjustcolor("grey30", 0.4),
     xlab = "Great-circle distance", ylab = expression(F[ST]))
abline(lm(fst ~ d_gc), col = "firebrick", lwd = 2)
legend("topleft", bty = "n", legend = sprintf("r = %.2f", cor(d_gc, fst)))
plot(d_lcp, fst, pch = 19, col = adjustcolor("grey30", 0.4),
     xlab = "Land least-cost distance (graph steps)", ylab = expression(F[ST]))
abline(lm(fst ~ d_lcp), col = "firebrick", lwd = 2)
legend("topleft", bty = "n", legend = sprintf("r = %.2f", cor(d_lcp, fst)))

dev.off()

########################################
# Fig. 3a
########################################

elevGraph <- readRDS("data/intermediate/hgdp_asia/elevGraph.RDS")
asiaGD    <- readRDS("data/intermediate/hgdp_asia/asiaGD.rds")

## build a node data.frame from public accessors
coords <- getCoords(elevGraph)
node_df <- data.frame(
  lon       = coords[, 1],
  lat       = coords[, 2],
  habitat   = as.character(getNodesAttr(elevGraph)$habitat),
  elevation = getNodesAttr(elevGraph)$elevation
)
node_df$elevation[node_df$habitat == "sea"] <- NA

## to sf points
node_sf <- st_as_sf(node_df, coords = c("lon", "lat"), crs = 4326)

lon0 <- 100; lat0 <- 37
ortho_crs <- sprintf("+proj=ortho +lat_0=%s +lon_0=%s", lat0, lon0)

ramp <- colorRampPalette(c("#f7fcb9", "#addd8e", "#78c679",
                           "#41ab5d", "#238443", "#005a32"))(256)

fig3a <- ggplot() +
  geom_sf(data = node_sf, aes(colour = elevation), size = 0.6) +
  scale_colour_gradientn(colours = ramp, na.value = "lightblue",
                         name = "SD of Elevation (m)") +
  geom_gdata(data = asiaGD, shape = 21, fill = "firebrick",
             colour = "white", size = 3) +
  coord_sf(crs = ortho_crs) +
  theme_void()

ggsave("results/fig3a.png", plot = fig3a,
       width = 6, height = 6, units = "in", dpi = 300, bg = "white")


###################################
# figure 3b
###################################

profile <- readRDS("data/intermediate/hgdp_asia/profile.RDS")
mantel_r_gc <- readRDS("data/intermediate/hgdp_asia/mantel_r_gc.rds")

baseline <- as.numeric(mantel_r_gc$statistic)
best     <- profile[which.max(profile$mantel_r), ]
plateau  <- profile[profile$mantel_r >= max(profile$mantel_r) - 0.01, ]
plat_x   <- range(plateau$threshold)

fig3b <- ggplot(profile, aes(threshold, mantel_r)) +
  # plateau of near-best thresholds
  annotate("rect", xmin = plat_x[1], xmax = plat_x[2],
           ymin = -Inf, ymax = Inf, fill = "#2C6FB0", alpha = 0.10) +
  # baseline: plain grid (no terrain)
  geom_hline(yintercept = baseline, linetype = "dashed",
             colour = "grey55", linewidth = 0.7) +
  annotate("text", x = min(profile$threshold), y = baseline,
           label = "plain grid (no terrain)",
           hjust = 0, vjust = -0.7, size = 4.6, colour = "grey40") +
  # sweep curve
  geom_line(colour = "grey30", linewidth = 0.9) +
  # best-fitting threshold (white halo + red point)
  geom_point(data = best, colour = "white",   size = 5.2) +
  geom_point(data = best, colour = "#B2182B", size = 3.6) +
  annotate("text", x = best$threshold, y = best$mantel_r,
           label = sprintf("best: r = %.2f (%s)", best$mantel_r, best$quantile),
           hjust = -0.05, vjust = -1.0, size = 4.8, colour = "#B2182B",
           fontface = "bold") +
  scale_y_continuous(expand = expansion(mult = c(0.05, 0.14))) +
  labs(x = "Ruggedness threshold (SD of elevation, m)",
       y = expression("Mantel "*italic(r)*" vs pairwise "*italic(F)[ST])) +
  theme_classic(base_size = 15) +
  theme(plot.margin = margin(8, 12, 8, 8),
        axis.title = element_text(size = 15),
        axis.text  = element_text(size = 13))

ggsave("results/fig3b.png", fig3b, width = 7, height = 4.2,
       units = "in", dpi = 300, bg = "white")

###################################
# figure 3c
###################################

hexGraph <- readRDS("data/intermediate/hgdp_asia/hexGraph.RDS")
optiGraph <- readRDS("data/intermediate/hgdp_asia/optiGraph.RDS")
asiaGD    <- readRDS("data/intermediate/hgdp_asia/asiaGD.rds")

hgdp.sub.raw <- setGraph(asiaGD, "hexGraph")
hgdp.sub.ele <- setGraph(asiaGD, "optiGraph")

# get raw geographic distances
m <- dijkstraBetween(hgdp.sub.raw)

# get geographic distances with elevation
m_elev <- dijkstraBetween(hgdp.sub.ele)

library(patchwork)

# habitat palettes — sea light blue (as in fig3a); no ocean disc, no graticule
pal0 <- c(sea = "white", land = "grey80")                       # without terrain
pal1 <- c(sea = "white", land = "grey80", rugged = "#8b6340")   # with terrain

panel_theme <- list(
  coord_sf(crs = ortho_crs),
  theme_void(),
  theme(plot.title = element_text(hjust = 0.5, face = "bold", size = 11))
)

## (a) WITHOUT terrain — plain land grid, plain least-cost paths
fig3c_a <- ggplot() +
  geom_ggraph(data = elevGraph, aes(colour = habitat), edges = FALSE, size = 0.6) +
  scale_colour_manual(values = pal0, na.value = "transparent", guide = "none") +
  geom_gpath(data = m, colour = "firebrick", linewidth = 0.5) +
  geom_gdata(data = asiaGD, shape = 21, fill = "black", colour = "white", size = 3) +
  ggtitle("Without terrain") + panel_theme

## (b) WITH terrain — ruggedness-weighted grid, terrain-aware paths
fig3c_b <- ggplot() +
  geom_ggraph(data = optiGraph, aes(colour = habitat), edges = FALSE, size = 0.6) +
  scale_colour_manual(values = pal1, na.value = "transparent", guide = "none") +
  geom_gpath(data = m_elev, colour = "firebrick", linewidth = 0.5) +
  geom_gdata(data = asiaGD, shape = 21, fill = "black", colour = "white", size = 3) +
  ggtitle("With terrain (ruggedness)") + panel_theme

fig3c <- fig3c_a + fig3c_b
ggsave("results/fig3c.png", fig3c, width = 10, height = 5, units = "in",
       dpi = 300, bg = "white")