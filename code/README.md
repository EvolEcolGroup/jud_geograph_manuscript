# Analysis Scripts

Run scripts sequentially from the repository root:

```r
source("code/s01_hgdp_worldwide.R")
source("code/s02_hgdp_asia.R")
source("code/s03_figures.R")
```

## s01_hgdp_worldwide.R

Worldwide analysis with 49 HGDP populations.

- Loads FST matrix and population coordinates
- Computes great-circle and land-restricted least-cost distances
- Mantel tests: great-circle (*r* = 0.749) vs land LCP (*r* = 0.867)
- Saves intermediate data to `data/intermediate/hgdp_worldwide/`


## s02_hgdp_asia.R

Asia case study with terrain ruggedness model (23 populations).

- Builds custom hexagonal grid and downloads elevation data
- Grid search: sweeps ruggedness thresholds to find optimal fit
- Mantel tests: plain LCP (*r* = 0.536) vs ruggedness-weighted LCP (*r* = 0.700)
- Saves intermediate data to `data/intermediate/hgdp_asia/`


## s03_figures.R

Generates publication figures 2 and 3.

- Figure 2a: orthographic map with LCP paths
- Figure 2b: FST vs distance scatter plots
- Figure 3a–c: Asia ruggedness and terrain effects
- Saves PNG files to `results/`

