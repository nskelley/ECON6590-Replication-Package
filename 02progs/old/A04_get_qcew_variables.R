# ------------------------------------------------------------------------------
# --------------------------- ECON6590 Final Project ---------------------------
# --- Identify variables of interest from combined, restricted QCEW data     ---                     
# --- from A03.                                                              ---
# ------------------------------ Nicholas Skelley ------------------------------
# ---------------------------- Created 30 Oct 2025 -----------------------------
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

qcew_county.raw <- fread(here("01data/supplemental/QCEW/combined",
                              "county_qcew_relevant.csv.gz"))

qcew_nat.raw <- fread(here("01data/supplemental/QCEW/combined",
                           "national_qcew_relevant.csv.gz"))

# Average annual CPI data taken from the Federal Reserve Bank of Minneapolis
annual_cpi_avg <- read_csv(here("01data/helper/cpi_annual_minnfed.csv")) |>
  # Using 2017 as index year based on real GDP data used elsewhere
  mutate(to_relUSD = cpi[year == 2017] / cpi)

# National coal share over time
# year
# man_nat_emplvl
# man_nat_oty_emplvl_pct_chg
# man_nat_totwages
# man_nat_oty_totwages_pct_chg
# auto_nat_emplvl
# auto_nat_oty_emplvl_pct_chg
# auto_nat_totwages
# auto_nat_oty_totwages_pct_chg
qcew_nat <- qcew_nat.raw |>
  filter(own_code == 5, industry_code == "2121") |>
  mutate(manual = !(area_fips == "US000")) |>
  group_by(year, manual) |>
  summarise(nat_emplvl = sum(annual_avg_emplvl, na.rm = TRUE),
            nat_totwages = sum(total_annual_wages, na.rm = TRUE),
            otyauto_emplvl_pct_chg = sum(oty_annual_avg_emplvl_pct_chg, 
                                         na.rm = TRUE),
            otyauto_totwages_pct_chg = sum(oty_total_annual_wages_pct_chg,
                                           na.rm = TRUE)) |>
  left_join(annual_cpi_avg, by = "year") |>
  ungroup() |>
  mutate(nat_tot_rwages = nat_totwages * to_relUSD) |>
  group_by(manual) |>
  mutate(nat_oty_emplvl_pct_chg = 
           (nat_emplvl - lag(nat_emplvl, order_by = year)) / 
           lag(nat_emplvl, order_by = year) * 100,
         nat_oty_totwages_pct_chg =
           (nat_totwages - lag(nat_totwages, order_by = year)) /
           lag(nat_totwages, order_by = year) * 100,
         nat_oty_tot_rwages_pct_chg = 
           (nat_tot_rwages - lag(nat_tot_rwages, order_by = year)) /
           lag(nat_tot_rwages, order_by = year) * 100,
         manual = factor(manual, 
                         levels = c(FALSE, TRUE), 
                         labels = c("auto", "man"))) |>
  select(-c("cpi", "to_relUSD")) |>
  pivot_wider(names_from = "manual", 
              values_from = c("nat_emplvl", "nat_totwages", "nat_tot_rwages",
                              "otyauto_emplvl_pct_chg",
                              "otyauto_totwages_pct_chg",
                              "nat_oty_emplvl_pct_chg",
                              "nat_oty_totwages_pct_chg",
                              "nat_oty_tot_rwages_pct_chg"),
              names_glue = "{manual}_{.value}") |>
  select(-contains("otyauto"))

fwrite(qcew_nat, here("05prepdata/qcew_derived",
                      "nationwide_coal_empl_by_year.csv"))

# Coal employment share by county, 2000
# area_fips
# coal_emplvl_2000
# tot_emplvl_2000
# coal_emp_share_2000
qcew_county <- qcew_county.raw |>
  filter(year == 2002, industry_code %in% c("10", "2121"), own_code == 5) |>
  group_by(area_fips) |>
  mutate(coal_emplvl_2002 = 
           ifelse(length(annual_avg_emplvl[industry_code == "2121"]) == 0,
                  NA, annual_avg_emplvl[industry_code == "2121"]),
         tot_emplvl_2002 = 
           ifelse(length(annual_avg_emplvl[industry_code == "10"]) == 0,
                  NA, annual_avg_emplvl[industry_code == "10"])) |>
  select(year, area_fips, coal_emplvl_2002, tot_emplvl_2002) |>
  unique() |>
  mutate(coal_emp_share_2002 = 
           ifelse(is.na(coal_emplvl_2002) | is.na(tot_emplvl_2002),
                  NA, coal_emplvl_2002 / tot_emplvl_2002))

fwrite(qcew_county, here("05prepdata/qcew_derived",
                         "coal_emp_share_2002_by_county.csv"))

# Coal and gas employment levels by state over time
# year
# state_fips
# gas_state_emplvl
# coal_state_emplvl
qcew_state <- qcew_nat.raw |>
  filter(own_code == 5, industry_code %in% c("10", "2121", "2111")) |>
  mutate(state_fips = str_sub(area_fips, 1, 2),
         industry_code = factor(industry_code, 
                                levels = c("10", "2121", "2111"),
                                labels = c("overall", "coal", "gas"))) |>
  select(state_fips, year, annual_avg_emplvl, industry_code) |>
  # At this point, year, state_fips, and industry_code should uniquely identify
  # all observations
  pivot_wider(id_cols = c("year", "state_fips"),
              names_from = "industry_code",
              values_from = "annual_avg_emplvl",
              names_glue = "{industry_code}_state_emplvl")

fwrite(qcew_state, here("05prepdata/qcew_derived",
                        "coal_gas_emp_by_state-year.csv"))

# Robustness check showing that coal jobs are not replaced 1:1 by natural gas
# jobs (actually appear to be complements overall? could look for 
# heterogeneous substitution effects?)
# summary(lm(coal_state_emplvl ~ gas_state_emplvl + state_fips + year,
#            data = qcew_state))
# Appears that adding a natural gas job to a state increases the number of coal
# jobs by about 0.07 (statistically distinguishable both from 0 and -1).
