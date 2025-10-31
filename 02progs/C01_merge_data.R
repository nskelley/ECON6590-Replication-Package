# ------------------------------------------------------------------------------
# --------------------------- ECON6590 Final Project ---------------------------
# --- Merge QCEW, CJARS, ACS, and real GDP data into a unified analysis data ---
# --- set ready for use in 03analysis/ code.                                 ---
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

# Load (limited) CJARS data
cjars <- fread(here("05prepdata/baseline_cjars_limited.csv.gz"))

# Merge QCEW+GDP data into CJARS
qcew_2002 <- fread(here("05prepdata/qcew_derived",
                        "coal_emp_share_2002_by_county.csv"))
qcew_national <- fread(here("05prepdata", "nat_qcew_with_rgdp.csv"))

cjars_qcew <- left_join(cjars, qcew_2002, by = c("fips" = "area_fips")) |>
  filter(!is.na(coal_emp_share_2002)) |>
  left_join(qcew_national, by = c("cohort_year" = "year"))

# Save intermediate data (pre-ACS merge)
fwrite(cjars_qcew, here("05prepdata/intermed_qcew_cjars.csv.gz"))

# Merge ACS data into CJARS
