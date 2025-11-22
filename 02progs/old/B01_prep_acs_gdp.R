# ------------------------------------------------------------------------------
# --------------------------- ECON6590 Final Project ---------------------------
# --- Clean and prep ACS, real GDP, and real gross output data for merging   ---
# --- into analysis data with CJARS and QCEW.                                ---
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

# ------------------------------------------------------------------------------
# ------------------------- Real GDP, Real Gross Output ------------------------
# ------------------------------------------------------------------------------
# Load and clean up GDP data
gdp <- read_csv(here("01data/supplemental/GDP/real_gdp.csv"), skip = 3) |>
  mutate(across(everything(), ~ ifelse(.x == "---", NA, .x))) |>
  select(-1) |>
  rename("source" = 1) |>
  filter(source == "Gross domestic product",
         if_any(everything(), ~ !is.na(.))) |>
  mutate(across(matches("(\\d\\d\\d\\d)"), ~ as.numeric(.))) |>
  select(-source) |>
  pivot_longer(cols = everything(), names_to = "year", values_to = "rgdp")

# Load and clean up gross output data
gross_out <- read_csv(here("01data/supplemental/GDP",
                           "real_gross_output_by_industry.csv"),
                      skip = 3) |>
  select(-c(1)) |>
  rename("industry" = 1) |>
  filter(if_any(everything(), ~ !is.na(.))) |>
  pivot_longer(cols = where(is.numeric), 
               names_to = "year", 
               values_to = "real_gdp") |>
  pivot_wider(names_from = "industry",
              values_from = "real_gdp") |>
  select("routput_gas" = starts_with("Oil and gas"),
         "routput_mine" = starts_with("Mining"),
         "routput_tot" = "All industries",
         year)

gdp_out <- full_join(gdp, gross_out, by = "year") |>
  mutate(year = as.integer(year),
         mine_routput_by_rgdp = routput_mine / rgdp,
         mine_routput_by_tot = routput_mine / routput_tot)

fwrite(gdp_out, here("05prepdata/relevant_real_gdp.csv"))

# Add GDP/gross output data to nationwide QCEW data
qcew_national <- fread(here("05prepdata/qcew_derived",
                            "nationwide_coal_empl_by_year.csv")) |>
  left_join(gdp_out, by = "year") |>
  mutate(man_nat_tot_rwages_by_rgdp = man_nat_tot_rwages / rgdp,
         auto_nat_tot_rwages_by_rgdp = auto_nat_tot_rwages / rgdp,
         man_nat_tot_rwages_by_totout = man_nat_tot_rwages / routput_tot,
         # % change: Real wages / Real GDP
         man_nat_oty_rwages_by_rgdp_pct_chg = 
           (man_nat_tot_rwages_by_rgdp - lag(man_nat_tot_rwages_by_rgdp, 
                                              order_by = year)) /
           lag(man_nat_tot_rwages_by_rgdp, order_by = year) * 100,
         auto_nat_oty_rwages_by_rgdp_pct_chg = 
           (auto_nat_tot_rwages_by_rgdp - lag(auto_nat_tot_rwages_by_rgdp, 
                                               order_by = year)) /
           lag(auto_nat_tot_rwages_by_rgdp, order_by = year) * 100,
         # % change: Real wages / Real gross output
         man_nat_oty_tot_rwages_by_totout_pct_chg = 
           (man_nat_tot_rwages_by_totout - 
              lag(man_nat_tot_rwages_by_totout, order_by = year)) /
              lag(man_nat_tot_rwages_by_totout, order_by = year) * 100)

# Scale down to manual definition of nationwide, simplify and clarify names
qcew_national_clean <- qcew_national |>
  select(year, starts_with("man_")) |>
  rename_with(function(x) {
    x <- gsub("totwages", "wages", sub("emplvl", "jobs", x))
    x <- gsub("((man_)|(oty_)|(tot_))", "", x)
    x <- gsub("nat_", "nat_coal_", x)
    return(x)
  })

fwrite(qcew_national_clean, here("05prepdata/nat_qcew_with_rgdp.csv"))


# ------------------------------------------------------------------------------
# -------------------------- American Community Survey -------------------------
# ------------------------------------------------------------------------------



