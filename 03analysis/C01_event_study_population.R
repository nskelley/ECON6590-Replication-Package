# ------------------------------------------------------------------------------
# --------------------------- ECON6590 Final Project ---------------------------
# --- Event study using (log) county population as the outcome to identify   ---
# --- possible out- or in-migration after the peak in coal production.       ---
# --------------- Robert Betancourt, Connor Bulgrin, Jenny Duan, ---------------
# --------------------- Nicholas Skelley, and Addie Sutton ---------------------
# ---------------------------- Created 01 Dec 2025 -----------------------------
# ---------------------------- Updated 02 Dec 2025 -----------------------------
# ------------------------------------------------------------------------------
# Packages
need <- c("here", "tidyverse", "data.table", "broom", "fixest")
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

## Load coal + CJARS data
coal_cjars <- fread(here("05prepdata/CJARS-Coal_Analysis_Sample_03-A01.csv"),
                    colClasses = list("character" = "fips")) |>
  mutate(fips = factor(fips)) |>
  group_by(fips) |>
  mutate(post_event_prod = 
           ifelse(sum(event_time == "0") > 0,
                  unique(tot_coal_prod[event_time == "0"])[1],
                  NA),
         treat_dose = -(post_event_prod - coal_prod_max) / coal_prod_max,
         cal_year = factor(cohort_year),
         log_pop = log(county_pop)) |>
  ungroup()

# Load scale and theme standardizers
load(here("04work/standards/figure_standards.RData"))

# Reference row of coefficients data frame
ref_row <- data.frame(term = NA, estimate = 0, std.error = 0, statistic = NA,
                      p.value = NA, event_time = -1)

## Run event study and plot the results
.plot <- coal_cjars |>
  # Restricts to just one observation per county
  filter(off_type == 0) |>
  # Event study
  feols(log_pop ~ i(event_time, treat_dose, ref = -1) | fips + cohort_year,
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
       y = "Logged county population")

# Save event study plot
ggsave(filename = here("06figures/graphs/event_study/ES_population_change.pdf"),
       height = figure_scales$height, width = figure_scales$width,
       units = figure_scales$units)
