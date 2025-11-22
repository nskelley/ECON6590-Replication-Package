# ------------------------------------------------------------------------------
# --------------------------- ECON6590 Final Project ---------------------------
# --- Merge CJARS (outcomes) and coal production data.                       ---
# --------------- Robert Betancourt, Connor Bulgrin, Jenny Duan, ---------------
# --------------------- Nicholas Skelley, and Addie Sutton ---------------------
# ---------------------------- Created 21 Nov 2025 -----------------------------
# ---------------------------- Updated 22 Nov 2025 -----------------------------
# ------------------------------------------------------------------------------
# Packages
need <- c("here", "tidyverse", "data.table")
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

## Load data
# Load CJARS
cjars <- fread(here("05prepdata/cjars_to_use.csv.gz"),
               colClasses = list("character" = "fips"))

# Load coal
coal <- fread(here("05prepdata/coal_production_by_county.csv"),
              colClasses = list("character" = "fips")) |>
  rename_with(~ sub("(\\_prod)$", "_coal_prod", .x))


## Merge and prep data
coal_cjars <- inner_join(cjars, coal, by = c("cohort_year" = "year", "fips")) |>
  # For each county, identify (1) first year in data, (2) last year in data,
  # and (3) year with the highest level of coal production.
  group_by(fips) |>
  mutate(first_year = min(cohort_year),
         last_year = max(cohort_year),
         coal_prod_max = max(tot_coal_prod),
         peak_coal_prod_year = 
           unique(cohort_year[tot_coal_prod == coal_prod_max])[1]) |>
  # Remove counties for which production is always increasing 
  # (peak year = last year)
  filter(last_year != peak_coal_prod_year) |>
  ungroup() |>
  # Event time and log production
  mutate(event_time = cohort_year - peak_coal_prod_year - 1,
         log_coal_prod = log(tot_coal_prod))


## Create a codebook for the remaining data with summary stats/tables

## Save data
fwrite(coal_cjars, here("05prepdata/cjars_coal_combined.csv"))
