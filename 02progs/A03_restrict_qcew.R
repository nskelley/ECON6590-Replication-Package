# ------------------------------------------------------------------------------
# --------------------------- ECON6590 Final Project ---------------------------
# --- Combine raw QCEW data from the BLS into a single, unified data set for ---
# --- cleaning and analysis.                                                 ---
# ------------------------------ Nicholas Skelley ------------------------------
# ---------------------------- Created 25 Oct 2025 -----------------------------
# ---------------------------- Updated 27 Oct 2025 -----------------------------
# ------------------------------------------------------------------------------
# Packages
need <- c("here", "tidyverse", "arrow", "data.table")
have <- need %in% rownames(installed.packages())
if (any(!have)) install.packages(need[!have])
invisible(lapply(need, library, character.only = TRUE))

# WD default to detect script folder and then move as needed
path <- rstudioapi::getSourceEditorContext()$path
scriptFolder <- sub(".*/", "", dirname(path))
scriptName <- basename(path)
here::i_am(paste(scriptFolder, scriptName, sep = "/"))
rm(list = ls())
# ------------------------------------------------------------------------------

# FIPS codes for states of interest
state_fips <- c(17, 18, 21, 24, 26, 36, 39, 42, 47, 51, 54)
state_pattern <- paste0("^(", paste0(state_fips, collapse = "|"), ")")
# Years to keep
years_keep <- 2006:2019

ds <- open_dataset(here("01data/bls/combined/all_parquet"))

lazy_filter <- ds |>
  filter(year %in% years_keep,
         grepl(state_pattern, area_fips),
         !grepl("000$", area_fips),
         industry_code %in% c("10", "2121", "221112")) |>
  select(-any_of("qtr"))

dt <- as.data.table(collect(lazy_filter))

# Confirm level of data is year-county-industry-public/private
nrow(dt) == nrow(unique(dt, by = c("year", "area_fips", "industry_code", 
                                   "own_code")))

fwrite(dt, here("01data/bls/combined/combined_qcew_relevant_industry.csv.gz"))
