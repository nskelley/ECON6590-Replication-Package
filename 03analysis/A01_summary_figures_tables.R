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

## Figure 1: Coal production trend relative to event time


coal_cjars |>
  mutate(diff_log = log_coal_prod - log(coal_prod_max)) |>
  group_by(fips) |>
  mutate(coal_prod_z = (tot_coal_prod - mean(tot_coal_prod, na.rm = TRUE)) / sd(tot_coal_prod, na.rm = TRUE)) |>
  filter(abs(event_time) <= 20) |>
  group_by(event_time) |>
  summarise(avg_z = mean(coal_prod_z, na.rm = TRUE),
            avg_diff = mean(diff_log, na.rm = TRUE)) |>
  ggplot(aes(x = event_time, y = avg_z)) +
  geom_line() +
  geom_vline(xintercept = -1, linetype = "dashed", color = "red") +
  theme_bw()

coal_cjars |>
  filter(fips == "05131") |>
  ggplot(aes(x = event_time, y = tot_coal_prod)) +
  geom_point() +
  geom_line() +
  geom_vline(xintercept = -1, linetype = "dashed", color = "red") +
  theme_bw()

table(coal_cjars$event_time)

hist(coal_cjars$cohort_year[coal_cjars$event_time == 0])


## Create and save plots
# Load scale and theme standardizers
figure_scales <- readRDS(here("04work/standards/figure_scales.RDS"))

# Histogram
# Calendar year of peak coal production, all in analysis sample
.plot <- coal_cjars |>
  filter(event_time == -1) |>
  select(fips, event_time, cohort_year) |>
  unique() |>
  ggplot(aes(x = cohort_year)) +
  geom_histogram(bins = 12, color = "black") +
  theme_bw() +
  scale_y_continuous(expand = c(0, 0, 0, 1)) +
  scale_x_continuous(expand = c(0, 0.5)) +
  labs(x = "Calendar year of peak coal production",
       y = "Frequency")
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
  theme_bw() +
  labs(x = "Calendar year of peak coal production",
       y = "Frequency")
ggsave(filename = here("06figures/graphs/summary/hist_peak_calyr_interior.pdf"),
       width = figure_scales$width, height = figure_scales$height, 
       units = figure_scales$units, plot = .plot)