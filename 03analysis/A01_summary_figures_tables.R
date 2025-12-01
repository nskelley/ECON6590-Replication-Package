# ------------------------------------------------------------------------------
# --------------------------- ECON6590 Final Project ---------------------------
# --- Produce summary tables and figures.                                    ---
# --------------- Robert Betancourt, Connor Bulgrin, Jenny Duan, ---------------
# --------------------- Nicholas Skelley, and Addie Sutton ---------------------
# ---------------------------- Created 22 Nov 2025 -----------------------------
# ---------------------------- Updated 22 Nov 2025 -----------------------------
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

## Load coal + CJARS data
coal_cjars <- fread(here("05prepdata/cjars_coal_combined.csv"),
                    colClasses = list("character" = "fips"))

## Create and save plots
# Load scale and theme standardizers
load(here("04work/standards/figure_standards.RData"))


## Figure 1
# Line chart
# Coal production trend (in county-level SDs from mean) relative to event time
# No weights
.plot <- coal_cjars |>
  mutate(diff_log = log_coal_prod - log(coal_prod_max)) |>
  group_by(fips) |>
  mutate(coal_prod_z = (tot_coal_prod - mean(tot_coal_prod, na.rm = TRUE)) / 
           sd(tot_coal_prod, na.rm = TRUE)) |>
  filter(abs(event_time) <= 20) |>
  group_by(event_time) |>
  summarise(avg_z = mean(coal_prod_z, na.rm = TRUE),
            z_se = 1 / sqrt(n()),
            z_ci_min = qnorm(0.025) * z_se + avg_z,
            z_ci_max = qnorm(0.975) * z_se + avg_z) |>
  ggplot(aes(x = event_time, y = avg_z)) +
  geom_vline(xintercept = -1, linetype = "dashed", color = "red") +
  geom_ribbon(aes(ymin = z_ci_min, ymax = z_ci_max),
              fill = "transparent", color = "#888", linewidth = 0.5,
              linetype = "dashed") +
  geom_line(linewidth = 0.6) +
  geom_point(size = 1) +
  scale_x_continuous(minor_breaks = seq(-20, 20, 5)) +
  theme_paper +
  labs(x = "Event time (years since coal production peak)",
       y = "Average standardized production level")
ggsave(filename = here("06figures/graphs/summary/coal_peak_unweighted.pdf"),
       width = figure_scales$width, height = figure_scales$height,
       units = figure_scales$units, plot = .plot)


## Figure 2
# Line chart
# Coal production trend (in county-level SDs from mean) relative to event time
# Weighted by level of production at event time
.plot <- coal_cjars |>
  mutate(diff_log = log_coal_prod - log(coal_prod_max)) |>
  group_by(fips) |>
  mutate(coal_prod_z = (tot_coal_prod - mean(tot_coal_prod, na.rm = TRUE)) / 
           sd(tot_coal_prod, na.rm = TRUE)) |>
  filter(abs(event_time) <= 20) |>
  group_by(event_time) |>
  summarise(avg_z = weighted.mean(coal_prod_z, coal_prod_max, na.rm = TRUE),
            z_se = 1 / sqrt(n()),
            z_ci_min = qnorm(0.025) * z_se + avg_z,
            z_ci_max = qnorm(0.975) * z_se + avg_z) |>
  ggplot(aes(x = event_time, y = avg_z)) +
  geom_vline(xintercept = -1, linetype = "dashed", color = "red") +
  geom_ribbon(aes(ymin = z_ci_min, ymax = z_ci_max),
              fill = "transparent", color = "#888", linewidth = 0.5,
              linetype = "dashed") +
  geom_line(linewidth = 0.6) +
  geom_point(size = 1) +
  scale_x_continuous(minor_breaks = seq(-20, 20, 5)) +
  theme_paper +
  labs(x = "Years since coal production peak",
       y = "Average standardized production level")
ggsave(filename = here("06figures/graphs/summary/coal_peak_prod-wt.pdf"),
       width = figure_scales$width, height = figure_scales$height,
       units = figure_scales$units, plot = .plot)


# Histogram
# Calendar year of peak coal production, all in analysis sample
.plot <- coal_cjars |>
  filter(event_time == -1) |>
  select(fips, event_time, cohort_year) |>
  unique() |>
  ggplot(aes(x = cohort_year)) +
  geom_histogram(bins = 12, color = "black") +
  scale_y_continuous(expand = c(0, 0, 0, 1)) +
  scale_x_continuous(expand = c(0, 0.5)) +
  labs(x = "Calendar year of peak coal production",
       y = "Frequency") +
  theme_paper_histogram

ggsave(filename = here("06figures/graphs/summary/hist_peak_calyr_all.pdf"),
       width = figure_scales$width, height = figure_scales$height, 
       units = figure_scales$units, plot = .plot)

# Histogram
# Calendar year of peak coal production, restricted to those with interior
# peaks
.plot <- coal_cjars |>
  filter(peak_coal_prod_year != first_year,
         event_time == -1) |>
  select(fips, event_time, cohort_year) |>
  unique() |>
  ggplot(aes(x = cohort_year)) +
  geom_histogram(bins = 12, color = "black") +
  scale_y_continuous(expand = c(0, 0, 0, 1)) +
  scale_x_continuous(expand = c(0, 0.5)) +
  labs(x = "Calendar year of peak coal production",
       y = "Frequency") +
  guides(linetype = guide_legend(position = "bottom",
                                 title = NULL)) +
  theme_paper_histogram

ggsave(filename = here("06figures/graphs/summary/hist_peak_calyr_interior.pdf"),
       width = figure_scales$width, height = figure_scales$height, 
       units = figure_scales$units, plot = .plot)
