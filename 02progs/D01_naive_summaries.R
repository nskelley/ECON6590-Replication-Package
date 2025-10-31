# ------------------------------------------------------------------------------
# --------------------------- ECON6590 Final Project ---------------------------
# --- 
# --------------- Robert Betancourt, Connor Bulgrin, Jenny Duan, ---------------
# --------------------- Nicholas Skelley, and Addie Sutton ---------------------
# ---------------------------- Created 31 Oct 2025 -----------------------------
# ---------------------------- Updated 31 Oct 2025 -----------------------------
# ------------------------------------------------------------------------------
# Packages
need <- c("here", "tidyverse", "data.table", "binsreg", "stargazer")
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

## Data setup
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


## Playing with graphs
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

for (var in c("mi_rate", "fe_rate")) {
  print(var)
  # Limit data to valid rows
  plot_base_df <- df_naif |>
    mutate(out = get(var)) |>
    filter(off_type != 0,
           across(c(oty_annual_avg_emplvl_pct_chg_2121, off_type,
                    coal_emp_share_2002, out), ~ !is.na(.)))
  # Create binscatter/binsreg
  .bs <- binsreg(x = oty_annual_avg_emplvl_pct_chg_2121,
                 y = out,
                 w = ~ cohort_year + sex + race + age_group + fips,
                 data = plot_base_df,
                 by = off_type,
                 weight = coal_emp_share_2002,
                 randcut = 1,
                 binspos = "qs",
                 nbins = 15,
                 dots = TRUE)
  # Get binscatter dots data for ggplot
  .dots_df <- lapply(seq_along(.bs$data.plot), function(i) {
    dp <- .bs$data.plot[[i]]$data.dots
    if (is.null(dp)) return(NULL)
    dp$by <- .bs$opt$byvals[i]
    dp
  }) |> bind_rows()
  # Plot binscatter (manual)
  .plot <- .dots_df |>
    mutate(by = factor(by, levels = 1:3, labels = c("Violent", "Property", 
                                                    "Drug"))) |>
    ggplot(aes(x = x, y = fit, color = by)) +
    geom_point(size = 2) +
    scale_x_continuous(limits = c(-25, 25)) +
    labs(x = "% change in coal employment share",
         y = ifelse(var == "mi_rate",
                    "Misdemanor Rate (per 100,000)",
                    "Felony Rate (per 100,000)")) +
    theme_minimal() +
    guides(color = guide_legend(position = "bottom",
                                title = "Offense Type")) +
    theme(panel.grid.minor = element_blank())
  
          # panel.grid.major = element_line(linetype = "dashed", linewidth = 0.4),
  ggsave(here("04work/early_figures", paste0("binscatter_", var, ".pdf")),
         plot = .plot, width = 8, height = 6, units = "in")
}



fwrite(df_naif, here("05prepdata/naive_tables_combined_data.csv"))

## Regressions
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

ind_var_lbl <- paste0("\\begin{minipage}{30mm}\n\t\\raggedright\n\t\\% change ",
                      "in coal employment\n\\end{minipage}")
demo_ctl_lbl <- paste0("\\begin{minipage}{30mm}\n\t\\raggedright\n\t ",
                       "Demographic controls\n\\end{minipage}\\vspace{0.5em}")

felonies_tabulate <- c(18, 20, seq(2, 16, 2))
stargazer::stargazer(naive_regs[felonies_tabulate], 
                     keep = c("oty_annual_avg_emplvl_pct_chg_2121", "factor.+"),
                     add.lines = list(c(demo_ctl_lbl, rep(c("No", "Yes"), 5))),
                     covariate.labels = c(ind_var_lbl,
                                          "Violent offense",
                                          "Property offense",
                                          "Drug offense"),
                     header = FALSE, float = FALSE, df = FALSE, 
                     keep.stat = c("n", "adj.rsq"),
                     model.numbers = FALSE,
                     column.labels = c("Felony rate", "All offenses",	
                                       "Violent offenses", "Property offenses", 
                                       "Drug offenses"),
                     column.separate = rep(2, 5),
                     column.sep.width = "0pt", dep.var.labels.include = FALSE,
                     dep.var.caption = "",
                     omit.table.layout = "n",
                     out = here("04work/felony_naive_table.tex"))

misdemeanors_tabulate <- c(17, 19, seq(1, 15, 2))
stargazer::stargazer(naive_regs[misdemeanors_tabulate], 
                     keep = c("oty_annual_avg_emplvl_pct_chg_2121", "factor.+"),
                     add.lines = list(c(demo_ctl_lbl, rep(c("No", "Yes"), 5))),
                     covariate.labels = c(ind_var_lbl,
                                          "Violent offense",
                                          "Property offense",
                                          "Drug offense"),
                     header = FALSE, float = FALSE, df = FALSE, 
                     keep.stat = c("n", "adj.rsq"),
                     model.numbers = FALSE,
                     column.labels = c("Misdemeanor rate", "All offenses",	
                                       "Violent offenses", 
                                       "Property offenses", 
                                       "Drug offenses"),
                     column.separate = rep(2, 5),
                     column.sep.width = "0pt", dep.var.labels.include = FALSE,
                     dep.var.caption = "",
                     omit.table.layout = "n",
                     out = here("04work/misdemeanor_naive_table.tex"))
