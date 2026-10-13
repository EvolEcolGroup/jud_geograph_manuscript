# Case studies for geoGraph

R scripts to reproduce the analyses and figures in the manuscript
*"geoGraph: Connectivity modelling across geographic space with hexagonal
discrete global grids."*

## Requirements

- R (>= 3.5.0)
- The `geoGraph` package (installation below)
- CRAN packages used by the scripts:
  `readr`, `vegan`, `dplyr`, `sf`, `terra`, `elevatr`, `sp`, `ggplot2`, `patchwork`

## Installation

### 1. Install geoGraph 

```r
  pak::pak("EvolEcolGroup/geograph@v2.0.1")
```

### 2. CRAN packages used by the scripts

```r
install.packages(c("readr", "vegan", "dplyr", "sf", "terra",
                   "elevatr", "sp", "ggplot2", "patchwork"))
```

## Reproduce the analyses

Run the scripts sequentially from the repository root:

```r
source("code/s01_hgdp_worldwide.R")  
source("code/s02_hgdp_asia.R")       
source("code/s03_figures.R")         
```

## Outputs

- Figures written to `results/`
- Intermediate objects written to `data/intermediate/`

## Repository structure

```
code/     analysis and figure scripts (see code/README.md)
data/     generated intermediate data (see data/README.md)
results/  generated figures
```

See `code/README.md` for script descriptions and `data/README.md` for data details.