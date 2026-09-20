# Early-season UAV canopy traits and rainfed grain yield rank in maize

This repository takes one RGB flight from the Genomes to Fields (G2F) maize UAV trial at College Station, Texas, in 2017, and carries it from the orthomosaic to a selection decision. The question is whether plot-level canopy traits recorded on 20 April 2017 rank hybrids for rainfed grain yield well enough to cull the bottom half of the trial before harvest. The project was built as a technical exercise in plot-scale UAV phenotyping and field-trial statistics. It was limited to a single date so that every step, from plot polygons to spatially corrected models, could be checked end to end before the analysis is extended to the rest of the season.

View the rendered report here [View the rendered report](https://nanaamuah.github.io/uav_maize_phenotyping/)

## Result in brief

Grain yield was highly heritable in both the irrigated and the rainfed trial. The four RGB traits (canopy cover, excess green, green leaf index and VARI) showed moderate heritability under irrigation and lower heritability under rainfed management. Their rank correlations with rainfed grain yield were weak, and coincidence of selection and retention of top yielders were close to what random culling would give. Hence, this early flight does not support a cull on its own; the report gives the numbers and the reasons, and it sets out the settings that were fixed and not tested.

## Data

The analysis uses the G2F Maize UAV Data, College Station, Texas 2017 (Murray et al., 2019, CyVerse Data Commons, <https://doi.org/10.25739/4ext-5e97>). The trial has 1,500 two-row plots made up of 250 genotypes in three management environments with two replicates. Only the irrigated (G2FE) and rainfed (DG2F) trials are used here.

The data are not stored in this repository. Four items need to be downloaded from CyVerse and placed under `data/raw/uav/` as shown below; the shapefiles need their `.dbf`, `.shx` and `.prj` companions in the same folder.

```
data/raw/uav/
├── CS17_G2F_FieldNotes.csv
├── shapefiles/
│   ├── CS17-DG2F.shp
│   └── CS17-G2FE.shp
└── 20170420_FW_RGB/
    └── CS17_G2F_20170420_FW_RGB_Mosaic.tif
```

Grain yield is taken from the YieldMoist column of the field notes. Raw images, point clouds and digital surface models are not needed for this single-date analysis and were not downloaded.

## Methods in brief

Plot polygons from both trials were combined and shrunk by a 0.20 m inward buffer to exclude plot edges. The RGB bands were normalized to chromatic coordinates, and ExG, GLI and VARI were computed from them. Cells with ExG above zero were classed as vegetation; canopy cover was taken as the vegetation share of each plot, and the index means were taken over vegetation cells only. Each trait was then modelled within each trial in SpATS with a two-dimensional P-spline surface over row and range. Genotype was fitted as random for generalized heritability and as fixed for genotype BLUEs. The BLUEs were used to compute Spearman correlation with rainfed grain yield, coincidence of selection at 10% and 20% intensity, and retention of top yielders after a half cull.

## Repository structure

```
uav_maize_phenotyping/
├── README.md
├── LICENCE
├── _quarto.yml
├── report.qmd                    # source of the published report
├── references.bib
├── renv.lock
├── r_scripts/
│   ├── 00_inventory_download.R   # checks and lists the raw files
│   ├── 01_trial_metadata.R       # field notes to trial table
│   ├── 02_plot_polygons.R        # combined and buffered plot polygons
│   ├── 03_rgb_indices.R          # ExG, GLI and VARI rasters
│   ├── 04_extract_rgb.R          # plot-level canopy cover and index means
│   ├── 05_join_traits.R          # UAV traits joined to trial design
│   ├── 06_yield_models.R         # SpATS models for grain yield
│   ├── 07_rgb_models.R           # SpATS models for the UAV traits
│   ├── 08_export_estimates.R     # BLUEs and heritability tables
│   ├── 09_rank_correlations.R    # Spearman correlation with rainfed yield
│   ├── 10_selection.R            # coincidence and retention
│   ├── 11_figures.R
│   └── 12_treatment_comparison.R # irrigated against rainfed
├── data/
│   ├── raw/                      # not tracked
│   └── processed/                # CSV tables tracked; rasters and models not tracked
├── outputs/figures/
└── index.html                    # rendered report for GitHub Pages
```

## Reproducing the analysis

The project uses R with renv. After cloning and placing the raw files, restore the package library and run the scripts in order from the project root:

```r
renv::restore()

scripts <- sort(list.files("r_scripts", pattern = "\\.R$", full.names = TRUE))
for (s in scripts) source(s, echo = FALSE)
```

Each script prints checks on its inputs and outputs, for example the number of polygons matched to field-note records, the CRS of the inputs and the heritability of each model; these are worth reading on the first run. The report is rendered with Quarto from the project root:

```bash
quarto render
```

This writes `index.html` to the project root. The report reads every number from the CSV tables in `data/processed/`, so it can be rendered from a fresh clone without downloading the raw data.

## Licence

The code is released under the MIT licence (see `LICENCE`). The G2F data are not redistributed here and remain under the terms set by their publishers on CyVerse.

## Reference

Murray, S. C., Malambo, L., Popescu, S., Cope, D., Anderson, S. L., Chang, A., Jung, J., Cruzato, N., Wilde, S., & Walls, R. L. (2019). *G2F Maize UAV Data, College Station, Texas 2017* [Data set]. CyVerse Data Commons. https://doi.org/10.25739/4ext-5e97

![README views](https://hits.sh/github.com/nanaamuah/uav_maize_phenotyping.svg?label=README%20views&color=2e7d32)
