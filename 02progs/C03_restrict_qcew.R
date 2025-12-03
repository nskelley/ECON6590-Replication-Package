# ------------------------------------------------------------------------------
# --------------------------- ECON6590 Final Project ---------------------------
# --- Merge CJARS (outcomes) and coal production data.                       ---
# --------------- Robert Betancourt, Connor Bulgrin, Jenny Duan, ---------------
# --------------------- Nicholas Skelley, and Addie Sutton ---------------------
# ---------------------------- Created 01 Dec 2025 -----------------------------
# ---------------------------- Updated 02 Dec 2025 -----------------------------
# ------------------------------------------------------------------------------
# Packages
need <- c("here", "tidyverse", "data.table", "nanoparquet")
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

# Coal industries
coal_industries <- c("2121",   # Coal mining
                     "213113") # Support activities for coal mining

# Find all parquet files
parquet_files <- list.files(
  here("01data/supplemental/QCEW/combined/all_parquet"),
  pattern = "\\.parquet$",
  recursive = TRUE,
  full.names = TRUE
)

# Read and combine all parquet files
old_mem <- mem.maxVSize()
mem.maxVSize(1e11)
county_data <- rbindlist(lapply(parquet_files, read_parquet))

# Filter to county-level data (exclude state/national aggregates ending in 
# "000")
county_data <- county_data[!grepl("000$", area_fips)]
mem.maxVSize(old_mem)

# Calculate wage share by county-year
wage_share <- county_data[, .(
  coal_wages = sum(total_annual_wages[industry_code %in% coal_industries], 
                   na.rm = TRUE),
  all_wages = sum(total_annual_wages[industry_code == "10"], 
                  na.rm = TRUE)
), by = .(area_fips, year)]

# Calculate coal wage share
wage_share[, coal_wage_share := coal_wages / all_wages]

# Handle cases where all_wages is 0
wage_share[all_wages == 0, coal_wage_share := NA]

# Save as CSV
fwrite(wage_share, here("05prepdata/County-Coal-Wage-Share_02-C03.csv"))