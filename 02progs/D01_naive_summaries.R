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

df_naif <- left_join(df_analysis, qcew_county, by = c("fips" = "area_fips",
                                                      "cohort_year" = "year"))
ggplot(df_naif, aes(x = oty_annual_avg_emplvl_pct_chg_2121,
                    y = inc_rate)) +
  geom_point()


x <- runif(500); y <- sin(x)+rnorm(500)
## Binned scatterplot
t <- binsreg(x = df_naif$oty_annual_avg_emplvl_pct_chg_2121,
             y = df_naif$inc_rate)

t$bins_plot
