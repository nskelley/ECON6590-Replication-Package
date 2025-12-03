# `here` package setup for local directory management
if (!("here" %in% utils::installed.packages())) install.packages("here")
here::i_am("00_run_all_code.R")


## Run R scripts preparing data for analysis
# [A##] - Preparation of coal data from EIA
source(here::here("02progs/A02_prep_raw_coal.R"))
# [B##] - Preparation of CJARS data from JOE
source(here::here("02progs/B01_restrict_cjars.R"))
# [C##] - Preparation of QCEW data from the BLS
source(here::here("02progs/C03_restrict_qcew.R"))
# [Z##] - Merge prepared data
source(here::here("02progs/Z01_merge_cjars_coal.R"))

# Standardization objects for graphs
source(here::here("02progs/zz_set_standards.R"))


## Run R scripts for analysis
# [A##] - Identify sample
source(here::here("03analysis/A01_identify_analysis_sample.R"))

# [B##] - Run event studies and produce exhibits
source(here::here("03analysis/B01_get_event_studies.R"))
source(here::here("03analysis/B02_plot_event_studies.R"))
source(here::here("03analysis/B03_tabulate_did.R"))

# [C##] - Robustness analyses
source(here::here("03analysis/C01_population_event_study.R"))
source(here::here("03analysis/C02_slope_dose_event_study.R"))