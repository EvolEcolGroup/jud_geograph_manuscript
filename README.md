# Geographic and Genetic Distance: Case Studies using geoGraph

Reproducible R analysis demonstrating how geographic constraints (land connectivity and terrain ruggedness) improve prediction of genetic differentiation (FST) in human populations.

## Quick Start

1. Ensure `data/raw/hgdp/Fst_pairwise.csv` is present
2. Run scripts sequentially from the repository root:
   ```r
   source("code/s01_hgdp_worldwide.R")
   source("code/s02_hgdp_asia.R")
   source("code/s03_figures.R")
   ```
3. Results: figures in `results/`, intermediate data in `data/intermediate/`

See `code/README.md` for script descriptions and `data/README.md` for data details.
