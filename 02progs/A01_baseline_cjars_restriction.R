# ------------------------------------------------------------------------------
# --------------------------- ECON6590 Final Project ---------------------------
# --- Load and restrict CJARS data.                                          ---
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
cjars_load <- c("fips", "cohort_year", "sex", "race", "age_group", "off_type",
                "repeat_contact", "fe_rate", "N_fe_rate", "mi_rate",
                "N_mi_rate", "inc_rate", "N_inc_rate", "par_rate",
                "N_par_rate", "pro_rate", "N_pro_rate")

# Adjust R's memory allocation
oldSize <- mem.maxVSize()
mem.maxVSize(1e11)
# Load CJARS and filter to relevant years
cjars.raw <- fread(here("01data/county/county_data.csv"), 
                   select = cjars_load,
                   colClasses = c(fips = "character"))

cjars <- cjars.raw |>
  filter(if_any(ends_with("_rate"), ~ !is.na(.)),
         if_all(c("sex", "race", "age_group", "repeat_contact"), ~ .x == 0))

# table(cjars$cohort_year)

fwrite(cjars, here("05prepdata/cjars_to_use.csv.gz"))
mem.maxVSize(oldSize)
