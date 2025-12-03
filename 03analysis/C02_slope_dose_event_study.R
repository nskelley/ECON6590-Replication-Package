# ------------------------------------------------------------------------------
# --------------------------- ECON6590 Final Project ---------------------------
# --- Run continuous-dose event studies.                                     ---
# --------------- Robert Betancourt, Connor Bulgrin, Jenny Duan, ---------------
# --------------------- Nicholas Skelley, and Addie Sutton ---------------------
# ---------------------------- Created 02 Dec 2025 -----------------------------
# ---------------------------- Updated 02 Dec 2025 -----------------------------
# ------------------------------------------------------------------------------
# Packages
need <- c("here", "tidyverse", "data.table", "broom", "fixest")
have <- need %in% rownames(installed.packages())
if (any(!have)) install.packages(need[!have])
invisible(lapply(need, library, character.only = TRUE))

here::i_am("03analysis/C02_slope_dose_event_study.R")
rm(list = ls())
# ------------------------------------------------------------------------------

## Load coal + CJARS data
coal_cjars <- fread(here("05prepdata/CJARS-Coal_Analysis_Sample_03-A01.csv"),
                    colClasses = list("character" = "fips")) |>
  mutate(fips = factor(fips)) |>
  group_by(fips) |>
  mutate(cal_year = factor(cohort_year)) |>
  ungroup()

counties <- coal_cjars |>
  filter(event_time == -1, off_type == 0) |>
  pull(fips) |>
  as.character()

doses <- lapply(counties, function(x) {
  .dose <- coal_cjars |>
    filter(fips == x,
           off_type == 0) |>
    lm(log_coal_prod ~ event_time * I(event_time > -1), data = _) |>
    summary() |>
    tidy() |>
    filter(term == "I(event_time > -1)TRUE") |>
    mutate(estimate = estimate * -1) |>
    pull(estimate)
  
  .df <- tibble(fips = x, treat_dose = .dose)
}) |>
  rbindlist()


# Load scale and theme standardizers
load(here("04work/standards/figure_standards.RData"))

# Reference row of coefficients data frame
ref_row <- data.frame(term = NA, estimate = 0, std.error = 0, statistic = NA,
                      p.value = NA, event_time = -1)

for (trt in list(c(label = "felony", t = "fe_rate"),
                 c(label = "misdemeanor", t = "mi_rate"))) {
  .formula <- paste(trt[["t"]], 
                    "~ i(event_time, treat_dose, ref = -1)",
                    "| fips + cohort_year") |>
    str_trim() |>
    as.formula()
  
  .plot <- coal_cjars |>
    left_join(doses, by = "fips") |>
    # Restrict to all offenses
    filter(off_type == 0) |>
    # Event study
    feols(.formula,
          data = _,
          cluster = ~ fips) |>
    # Prep data for plotting
    tidy() |>
    mutate(event_time = str_extract(term, "-?\\d+")) |>
    rbind(ref_row) |>
    mutate(ci_min = estimate + qnorm(0.025) * std.error,
           ci_max = estimate + qnorm(0.975) * std.error) |>
    # Event study plot
    ggplot(aes(x = as.numeric(event_time), y = estimate)) +
    ref_lines +
    geom_line(linewidth = 0.6) +
    geom_ribbon(aes(ymin = ci_min, ymax = ci_max), 
                linetype = "dashed", color = "#555", linewidth = 0.5,
                fill = "transparent") +
    geom_point() +
    scale_x_continuous(breaks = -5:5) +
    theme_paper +
    labs(x = "Years since coal production peak",
         y = paste("Rate of all", trt[["label"]], "charges\n(per 100,000)"))
  
  ggsave(filename = here("06figures/graphs/event_study/",
                         paste0("ES_", trt[["label"]], "_slopedose.pdf")),
         height = figure_scales$height, width = figure_scales$width,
         units = figure_scales$units)
}
