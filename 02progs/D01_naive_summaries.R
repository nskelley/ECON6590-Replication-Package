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
  filter(!is.na(oty_annual_avg_emplvl_pct_chg_2121)) |>
  mutate(fips = as.character(fips))

df_naif |>
  group_by(eq_bin = round(oty_annual_avg_emplvl_pct_chg_2121 / 10) * 10,
           off_type) |>
  summarise(out = weighted.mean(fe_rate, coal_emp_share_2002, na.rm = TRUE),
            size = mean(coal_emp_share_2002, na.rm = TRUE) * n()) |>
  ggplot(aes(x = eq_bin, y = out, color = factor(off_type), size = size)) +
  geom_point(alpha = 0.8) +
  geom_smooth(method = "lm", se = FALSE, linewidth = 0.5) +
  scale_size_continuous(range = c(0.5, 3)) +
  labs(x = "% change in county coal employment share",
       y = "felony rate") +
  theme_bw() +
  theme(legend.position = "top")


df_naif |>
  filter(oty_annual_avg_emplvl_pct_chg_2121 >= 100) |>
  select(cohort_year, fips, annual_avg_emplvl_10, ends_with("_2121")) |>
  View()

t <- df_naif |>
  filter(off_type != 0) %>%
  binsreg(x = oty_annual_avg_emplvl_pct_chg_2121,
          y = mi_rate,
          # w = select(., cohort_year, sex, race, age_group, fips),
          data = .,
          by = off_type,
          # weight = coal_emp_share_2002,
          randcut = 1,
          nbins = 15,
          line = c(1, 1))

df_naif |>
  filter(off_type != 0) |>
  ggplot(aes(x = oty_annual_avg_emplvl_pct_chg_2121,
             y = mi_rate,
             color = factor(off_type))) +
  geom_smooth(method = "lm", se = FALSE) +
  geom_point(data = t$data.plot, aes(x = x, y = ))

t$data.plot |> View()
t$bins_plot +
  labs(x = "% change in average coal employment",
       y = "Misdemeanor rate",
       color = "Offense type") +
  scale_x_continuous(limits = c(-50, 50)) +
  theme(legend.position = "top")



offense_type <- c(0, 1, 2, 3, NA)
controls <- c("fips + cohort_year",
              "sex + race + age_group + fips + cohort_year")
outcome <- c("mi_rate", "fe_rate")

regs_to_run <- expand_grid(offense_type, controls, outcome)

naive_regs <- sapply(1:nrow(regs_to_run), function(x) {
  .row <- regs_to_run[x, ]
  .df <- df_naif
  .off_type_ctl <- "factor(off_type)"
  
  if (!is.na(.row$offense_type)) {
    .df <- filter(df_naif, off_type == .row$offense_type)
    .off_type_ctl <- ""
  }
  
  .eq <- paste0(.row$outcome, " ~ oty_annual_avg_emplvl_pct_chg_2121 + ",
                .off_type_ctl, " + ", .row$controls)
  
  return(lm(.eq, data = .df))
})

felonies_tabulate <- c(18, 20, seq(2, 16, 2))
stargazer::stargazer(naive_regs[[20]], type = "text")
stargazer::stargazer(naive_regs[felonies_tabulate], 
                     keep = c("oty_annual_avg_emplvl_pct_chg_2121", "factor.+"),
                     add.lines = list(c("Demographic controls", rep(c("No", "Yes"), 5))),
                     covariate.labels = c("\\% change in coal employment",
                                          "Violent offense",
                                          "Property offense",
                                          "Drug offense"),
                     header = FALSE, float = FALSE, df = FALSE, 
                     keep.stat = c("n", "adj.rsq"),
                     model.numbers = FALSE,
                     column.labels = c("Felony rate", "All felonies",	
                                       "Violent felonies", "Property felonies", 
                                       "Drug felonies"),
                     column.separate = rep(2, 5),
                     out = here("04work/felony_naive_table.tex"))
