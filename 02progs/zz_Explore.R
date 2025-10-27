# ------------------------------------------------------------------------------
# --------------------------- ECON6590 Final Project ---------------------------
# --- Explore JOE, QCEW, gas reserves data.                                  ---
# --------------- Robert Betancourt, Connor Bulgrin, Jenny Duan, ---------------
# --------------------- Nicholas Skelley, and Addie Sutton ---------------------
# ---------------------------- Created 23 Oct 2025 -----------------------------
# ---------------------------- Updated 27 Oct 2025 -----------------------------
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

# test <- fread("https://www.bls.gov/cew/about-data/downloadable-file-layouts/quarterly/naics-based-quarterly-layout-csv.csv")

qcew <- fread(here("01data/bls/combined",
                       "combined_qcew_relevant_industry.csv.gz"))

county_coal <- qcew |>
  filter(industry_code == "2121") |>
  select(area_fips, own_code, year,
         coal_annual_emp = annual_avg_emplvl, 
         coal_annual_estabs = annual_avg_estabs_count)
  
county_overall <- qcew |>
  filter(industry_code == "10", own_code == 5) |>
  select(area_fips, own_code, year,
         tot_annual_emp = annual_avg_emplvl,
         tot_annual_estabs = annual_avg_estabs_count)

qcew_outer <- full_join(county_coal, county_overall, 
                        by = c("area_fips", "own_code", "year")) |>
  mutate(rel_coal_emp = coal_annual_emp / tot_annual_emp,
         rel_coal_estabs = coal_annual_estabs / tot_annual_estabs) |>
  mutate(across(where(is.numeric), ~ ifelse(is.nan(.x) | is.infinite(.x), NA, 
                                            .x)))
qcew_outer |>
  filter(!is.na(rel_coal_emp),
         rel_coal_emp > 0,
         rel_coal_emp > quantile(rel_coal_emp, 0.9, na.rm = TRUE)) |>
  ggplot(aes(x = year, y = rel_coal_emp)) +
  geom_point() +
  geom_smooth(method = "lm")


qcew_means_overall <- qcew_outer |>
  group_by(year) |>
  summarise(mean_rel_coal_emp = weighted.mean(rel_coal_emp, tot_annual_emp,
                                              na.rm = TRUE),
            mean_rel_coal_estabs = weighted.mean(rel_coal_estabs, 
                                                 tot_annual_estabs,
                                                 na.rm = TRUE))

qcew_means_top10 <- qcew_outer |>
  group_by(year) |>
  filter(coal_annual_emp > 0 & coal_annual_estabs > 0) |>
  arrange(-rel_coal_emp) |>
  slice_head(prop = 0.5) |>
  summarise(mean_rel_coal_emp = weighted.mean(rel_coal_emp, tot_annual_emp,
                                              na.rm = TRUE),
            mean_rel_coal_estabs = weighted.mean(rel_coal_estabs, 
                                                 tot_annual_estabs,
                                                 na.rm = TRUE))

ggplot(qcew_means_overall, aes(x = year, y = mean_rel_coal_estabs)) +
  geom_line() +
  theme_bw() +
  scale_x_continuous(breaks = 2006:2019) +
  theme(panel.grid.minor.x = element_blank()) +
  labs(x = "Year", y = "Coal employment share")
