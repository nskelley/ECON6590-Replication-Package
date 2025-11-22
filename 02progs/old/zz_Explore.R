# ------------------------------------------------------------------------------
# --------------------------- ECON6590 Final Project ---------------------------
# --- Explore JOE, QCEW, gas reserves data.                                  ---
# --------------- Robert Betancourt, Connor Bulgrin, Jenny Duan, ---------------
# --------------------- Nicholas Skelley, and Addie Sutton ---------------------
# ---------------------------- Created 23 Oct 2025 -----------------------------
# ---------------------------- Updated 27 Oct 2025 -----------------------------
# ------------------------------------------------------------------------------
# Packages
need <- c("here", "tidyverse", "data.table", "arrow")
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

qcew <- fread(here("01data/supplemental/QCEW/combined",
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
rm(county_coal, county_overall)

length(unique(qcew_outer$area_fips[qcew_outer$rel_coal_emp >= 1e-5]))
length(unique(qcew_outer$area_fips[qcew_outer$rel_coal_emp >= 0.02]))
length(unique(qcew_outer$area_fips[qcew_outer$year == 2009]))

county_fips <- unique(qcew_outer$area_fips[qcew_outer$year == 2009])

oldSize <- mem.maxVSize()
mem.maxVSize(1e11)

cols_to_drop <- fread(here("01data/county/county_data.csv"), nrows = 2) |>
  select(matches(c("hud","ssi", "proc_time", "above_poverty", "medicaid", 
                   "medicare", "mortality"))) |>
  names()

save(cols_to_drop, file = here("04work/fread_cjars_county_cols_to_drop.Rdata"))

length(unique(cjars$fips))

cjars.1 <- cjars |>
  filter(if_any(everything(), ~ !is.na(.)))

cjars.2 <- cjars.1 |>
  filter(off_type == 0) |>
  select(cohort_year, fips, age_group, sex, race, repeat_contact, fe_rate,
         inc_rate, mi_rate)

cjars_counties_yay <- cjars.2 |>
  pull(fips) |>
  unique()

qcew_nonzero_coal <- unique(qcew_outer$area_fips[qcew_outer$rel_coal_emp >= 1e-5])
qcew_worthwhile_coal <- unique(qcew_outer$area_fips[qcew_outer$rel_coal_emp >= 0.02])

sum(qcew_worthwhile_coal %in% cjars_counties_yay)

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
