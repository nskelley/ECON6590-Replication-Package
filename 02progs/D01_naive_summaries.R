# ------------------------------------------------------------------------------
# --------------------------- ECON6590 Final Project ---------------------------
# --- 
# --------------- Robert Betancourt, Connor Bulgrin, Jenny Duan, ---------------
# --------------------- Nicholas Skelley, and Addie Sutton ---------------------
# ---------------------------- Created 31 Oct 2025 -----------------------------
# ---------------------------- Updated 31 Oct 2025 -----------------------------
# ------------------------------------------------------------------------------
# Packages
need <- c("here", "tidyverse", "data.table", "binsreg")
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

df_analysis <- fread(here("05prepdata/intermed_qcew_cjars.csv.gz"))

qcew_county <- fread(here("01data/supplemental/QCEW/combined",
                          "county_qcew_relevant.csv.gz")) |>
  filter(own_code == 5) |>
  select(area_fips, year, industry_code, annual_avg_emplvl,
         oty_annual_avg_emplvl_pct_chg, total_annual_wages) |>
  pivot_wider(id_cols = c("area_fips", "year"),
              names_from = industry_code,
              values_from = c("annual_avg_emplvl", 
                              "oty_annual_avg_emplvl_pct_chg",
                              "total_annual_wages")) |>
  ungroup()

nrow(unique(qcew_county, by = c("year", "area_fips")))

df_naif <- left_join(df_analysis, qcew_county, 
                     by = c("fips" = "area_fips", "cohort_year" = "year")) |>
  filter(!is.na(oty_annual_avg_emplvl_pct_chg_2121))

df_naif |>
  group_by(eq_bin = round(oty_annual_avg_emplvl_pct_chg_2121 / 10) * 10,
           off_type) |>
  summarise(out = weighted.mean(fe_rate, coal_emp_share_2002, na.rm = TRUE),
            size = coal_emp_share_2002) |>
  ggplot(aes(x = eq_bin, y = out, color = factor(off_type), size = size)) +
  geom_point() +
  labs(x = "% change in county coal employment share",
       y = "felony rate") +
  theme_bw() +
  theme(legend.position = "top")

qcew_county |>
  filter(area_fips == "17055") |>
  View()

df_naif |>
  filter(oty_annual_avg_emplvl_pct_chg_2121 >= 100) |>
  select(cohort_year, fips, annual_avg_emplvl_10, ends_with("_2121")) |>
  View()

t <- binsreg(x = oty_annual_avg_emplvl_pct_chg_2121,
             y = mi_rate,
             w = select(df_naif, cohort_year, sex, race, age_group, fips),
             data = df_naif,
             by = off_type,
             randcut = 1,
             nbins = 15)

t$bins_plot +
  labs(x = "% change in average coal employment",
       y = "Misdemeanor rate",
       color = "Offense type") +
  scale_x_continuous(limits = c(-75, 75)) +
  theme(legend.position = "top")
