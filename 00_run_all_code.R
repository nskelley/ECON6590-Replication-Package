# `here` package setup for local directory management
if (!("here" %in% utils::installed.packages())) install.packages("here")
here::i_am("00_run_all_code.R")
setwd(here::here())

## Run R scripts preparing data for analysis
# [A##] - Preparation of coal data from EIA
source("02progs/A01_prep_raw_coal.R")
# [B##] - Preparation of CJARS data from JOE
source("02progs/B01_restrict_cjars.R")
# [Z##] - Merge prepared data
source("02progs/Z01_merge_cjars_coal.R")

# Standardization objects for graphs
source("02progs/zz_set_standards.R")


## Run R scripts for analysis
# [A##] - Identify sample
source("03analysis/A01_identify_analysis_sample.R")

# [B##] - Run event studies and produce exhibits
source("03analysis/B01_get_event_studies.R")
source("03analysis/B02_plot_event_studies.R")

# [C##] - Robustness analyses
source("03analysis/C01_population_event_study.R")
source("03analysis/C02_slope_dose_event_study.R")
