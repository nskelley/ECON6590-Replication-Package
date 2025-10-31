# ------------------------------------------------------------------------------
# --------------------------- ECON6590 Final Project ---------------------------
# --- Merge QCEW, CJARS, ACS, and real GDP data into a unified analysis data ---
# --- set.                                                                   ---
# --------------- Robert Betancourt, Connor Bulgrin, Jenny Duan, ---------------
# --------------------- Nicholas Skelley, and Addie Sutton ---------------------
# ---------------------------- Created 30 Oct 2025 -----------------------------
# ---------------------------- Updated 30 Oct 2025 -----------------------------
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

## Load CJARS data
# Minimal columns to load for CJARS
load(here("04work/cjars_min_cols_toread.Rdata"))
# Adjust R's memory allocation
oldSize <- mem.maxVSize()
mem.maxVSize(1e11)
# Load CJARS and filter to relevant years
cjars.raw <- fread(here("01data/county/county_data.csv"), 
                   select = cjars_load,
                   colClasses = c(fips = "character"))

cjars <- cjars.raw |>
  filter(if_any(ends_with("_rate"), ~ !is.na(.)),
         cohort_year %in% 2006:2019)

fwrite(cjars, here("05prepdata/baseline_cjars_limited.csv.gz"))
mem.maxVSize(oldSize)
