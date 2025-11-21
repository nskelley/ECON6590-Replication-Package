# ------------------------------------------------------------------------------
# --------------------------- ECON6590 Final Project ---------------------------
# --- Combine raw QCEW data from the BLS into a single, unified data set for ---
# --- cleaning and analysis.                                                 ---
# ------------------------------ Nicholas Skelley ------------------------------
# ---------------------------- Created 25 Oct 2025 -----------------------------
# ---------------------------- Updated 30 Oct 2025 -----------------------------
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
years_keep <- 2000:2019
# Industries to keep
ind_to_keep <- c("10",     # All industries
                 "2121",   # Coal mining
                 "2111",   # Oil and gas extraction,
                 "213113", # Support activities for coal mining
                 "213111", # Drilling of oil and gas wells
                 "213112", # Support activities for oil and gas operations
                 "2212",   # Natural gas distribution
                 "221112"  # Fossil fuel electric power generation
                 )
# States to omit (nationwide data)
state_fips_to_exclude <- c("60", "03", "81", "07", "64", "14", "66", "84", "86",
                           "67", "89", "68", "71", "76", "69", "70", "95", "43",
                           "72", "74", "52", "78", "79")
state_fips_exclusion <- paste0("^(", 
                               paste0(state_fips_to_exclude, collapse = "|"), 
                               ")")
# Lazy data set
ds <- open_dataset(here("01data/supplemental/QCEW/combined/all_parquet"))

# Make restriction for county-level data in states of interest
county_lazy_filter <- ds |>
  filter(year %in% years_keep,
         grepl(state_pattern, area_fips),
         !grepl("000$", area_fips),
         industry_code %in% ind_to_keep) |>
  select(-any_of("qtr"))

county_qcew <- as.data.table(collect(county_lazy_filter))

# Confirm level of data is year-county-industry-public/private
nrow(county_qcew) == nrow(unique(county_qcew, by = c("year", "area_fips", 
                                                     "industry_code", 
                                                     "own_code")))
# Save county-level QCEW data
fwrite(county_qcew, here("01data/supplemental/QCEW/combined",
                         "county_qcew_relevant.csv.gz"))

# Make restriction for national data
nat_lazy_filter <- ds |>
  filter(year %in% years_keep,
         industry_code %in% ind_to_keep,
         !grepl(state_fips_exclusion, area_fips),
         grepl("000$", area_fips)) |>
  select(-any_of("qtr"))

nat_qcew <- as.data.table(collect(nat_lazy_filter))

# Save national-level QCEW data
fwrite(nat_qcew, here("01data/supplemental/QCEW/combined",
                      "national_qcew_relevant.csv.gz"))
