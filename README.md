# Case studies for geoGraph

R scripts to reproduce the analyses and figures in the manuscript
*"geoGraph: Connectivity modelling across geographic space with hexagonal
discrete global grids."*

## Requirements

- R (≥ 4.1)
- The `geoGraph` package (installation below)
- CRAN packages used by the scripts:
  `readr`, `vegan`, `dplyr`, `sf`, `terra`, `elevatr`, `sp`, `ggplot2`, `patchwork`

## Installation

### 1. Bioconductor dependencies
`geoGraph` depends on `graph` and `RBGL`, which are on Bioconductor (not CRAN):

```r
if (!requireNamespace("BiocManager", quietly = TRUE)) install.packages("BiocManager")
BiocManager::install(c("graph", "RBGL"))
```

### 2. Install geoGraph (anonymised review copy)
Open the anonymised package repository at
<https://anonymous.4open.science/r/geograph-01B6>, click **"Download Repository"**
(top right), and unzip it. Then install from the unzipped source folder:

```r
install.packages("path/to/geograph-01B6", repos = NULL, type = "source")
# or, to resolve remaining dependencies automatically:
# pak::local_install("path/to/geograph-01B6")
```

### 3. CRAN packages used by the scripts

```r
install.packages(c("readr", "vegan", "dplyr", "sf", "terra",
                   "elevatr", "sp", "ggplot2", "patchwork"))
```

## Reproduce the analyses

Ensure `data/raw/hgdp/Fst_pairwise.csv` is present, then run the scripts
sequentially from the repository root:

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
data/     input and intermediate data  (see data/README.md)
results/  generated figures
```

See `code/README.md` for script descriptions and `data/README.md` for data details.