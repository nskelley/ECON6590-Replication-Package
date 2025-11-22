# ------------------------------------------------------------------------------
# --------------------------- ECON6590 Final Project ---------------------------
# --- Do the actual continuous-dosage event study.                           ---
# --------------- Robert Betancourt, Connor Bulgrin, Jenny Duan, ---------------
# --------------------- Nicholas Skelley, and Addie Sutton ---------------------
# ---------------------------- Created 22 Nov 2025 -----------------------------
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


## Load coal + CJARS data
coal_cjars <- fread(here("05prepdata/cjars_coal_combined.csv"),
                    colClasses = list("character" = "fips"))

## Create and save plots
# Load scale and theme standardizers
load(here("04work/standards/figure_standards.RData"))

# Event study

coal_cjars |>
  filter(off_type == 0) |>
  mutate(fips = factor(fips),
         event_time = factor(fips),
         cal_year = factor(cohort_year)) |>
  lm(fe_rate ~ log_coal_prod:event_time, data = _)


sum(is.infinite(coal_cjars$fe_rate))
# Plot event study


