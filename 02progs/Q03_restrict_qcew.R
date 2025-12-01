setwd("/Users/pubpol6090/ECON6590-Final-Project")

# ------------------------------------------------------------------------------
# --------------------------- ECON6590 Final Project ---------------------------
# --- Calculate coal wage share (coal wages / all wages) by county and year  ---
# ------------------------------------------------------------------------------
# Packages
install.packages("nanoparquet")
library(tidyverse)
library(data.table)
library(nanoparquet)

# ------------------------------------------------------------------------------

# Coal industries
coal_industries <- c("2121",   # Coal mining
                     "213113") # Support activities for coal mining

# Find all parquet files
parquet_files <- list.files(
  "/Users/pubpol6090/ECON6590-Final-Project/01data/supplemental/QCEW/combined/all_parquet",
  pattern = "\\.parquet$",
  recursive = TRUE,
  full.names = TRUE
)

# Read and combine all parquet files
county_data <- rbindlist(lapply(parquet_files, read_parquet))

# Filter to county-level data (exclude state/national aggregates ending in "000")
county_data <- county_data[!grepl("000$", area_fips)]

# Calculate wage share by county-year
wage_share <- county_data[, .(
  coal_wages = sum(total_annual_wages[industry_code %in% coal_industries], na.rm = TRUE),
  all_wages = sum(total_annual_wages[industry_code == "10"], na.rm = TRUE)
), by = .(area_fips, year)]

# Calculate coal wage share
wage_share[, coal_wage_share := coal_wages / all_wages]

# Handle cases where all_wages is 0
wage_share[all_wages == 0, coal_wage_share := NA]

# Save as CSV
fwrite(wage_share, "/Users/pubpol6090/ECON6590-Final-Project/05prepdata/county_coal_wage_share.csv")