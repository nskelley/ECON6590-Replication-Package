# ------------------------------------------------------------------------------
# --------------------------- ECON6590 Final Project ---------------------------
# --- Identify balanced analysis sample.                                     ---
# --------------- Robert Betancourt, Connor Bulgrin, Jenny Duan, ---------------
# --------------------- Nicholas Skelley, and Addie Sutton ---------------------
# ---------------------------- Created 26 Nov 2025 -----------------------------
# ---------------------------- Updated 02 Dec 2025 -----------------------------
# ------------------------------------------------------------------------------
# Packages
need <- c("here", "tidyverse", "data.table", "readxl")
have <- need %in% rownames(installed.packages())
if ("tabtex" %in% need & !("tabtex" %in% installed.packages())) {
  devtools::install_github("nskelley/tabtex")
}
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
                    colClasses = list("character" = "fips")) |>
  group_by(fips) |>
  mutate(min_event_time = min(event_time),
         max_event_time = max(event_time))

## Load figure standardization
load(here("04work/standards/figure_standards.RData"))


# ---------------------- Identify optimal sample window ---------------------- #
# For each possible event study window from 1 to 15 years, get the number of
# unique counties for which all observations of all relevant variables are
# valid/non-missing
window_sample_obs <- lapply(1:15, function(window) {
  .a <- coal_cjars |>
    # Restrict to counties with all valid observations
    filter(if_all(c(fe_rate, mi_rate, ends_with("_prod")), ~ ! is.na(.))) |>
    # Restrict to the relevant window
    filter(min_event_time <= -window,
           max_event_time >= window,
           abs(event_time) <= window) |>
    # Remove counties who are not observed in all years in the window
    group_by(fips, off_type) |>
    filter(n() == 1 + window * 2) |>
    # Get the number of unique observations (counties)
    ungroup() |>
    select(fips) |>
    unique() |>
    nrow()
  
  return(c(window, .a))
}) |>
  # Convert to data frame
  as.data.frame() |>
  t() |>
  as.data.frame() |>
  rename("window" = 1, "nvalid" = 2)

# For each possible window size, identify the number of unique counties that
# appear in the data (as comparison to the number of unique counties that also
# have all valid outcome observations).
window_county_obs <- lapply(1:15, function(window) {
  .a <- coal_cjars |>
    filter(min_event_time <= -window,
           max_event_time >= window) |>
    select(fips) |>
    unique() |>
    nrow()
  return(c(window, .a))
}) |>
  # Convert to data frame
  as.data.frame() |>
  t() |>
  as.data.frame() |>
  rename("window" = 1, "ncounty" = 2)

# Combine the data on *total* unique counties and *valid* unique counties for
# each possible window size into the same clean data frame.
window_obs <- full_join(window_county_obs, window_sample_obs, by = "window")
rownames(window_obs) <- NULL

## Plot of numbers of observations (all counties vs. counties with all valid
## observations) by window size.
.plot <- window_obs |>
  pivot_longer(c(ncounty, nvalid), names_to = "obs_type", values_to = "nobs") |>
  mutate(obs_type = factor(obs_type, levels = c("ncounty", "nvalid"),
                           labels = c("All counties", 
                                      "Counties with CJARS data"))) |>
  ggplot(aes(x = window, y = nobs, linetype = obs_type, shape = obs_type)) +
  geom_point() +
  geom_line() +
  scale_linetype_manual(values = c("22", "solid")) +
  scale_shape_manual(values = c(19, 15)) +
  labs(x = "Event study window size",
       y = "Num. unique units",
       linetype = "Unit types",
       shape = "Unit types") +
  guides(linetype = guide_legend(position = "top",
                                 title = NULL),
         shape = guide_legend(position = "top",
                              title = NULL)) +
  theme_paper

ggsave(filename = here("06figures/graphs/n_counties_by_window.pdf"),
       width = figure_scales$width, height = figure_scales$height,
       units = figure_scales$units, plot = .plot)

## Plot numbers of observations (unique valid cohort-*years*) by window size
.plot <- ggplot(window_obs, aes(x = window, y = nvalid * 2 * window,
                                linetype = TRUE)) +
  geom_point(shape = 15) +
  geom_line() +
  labs(x = "Event study window size",
       y = "Num. unique county-years") +
  theme_paper +
  guides(linetype = guide_legend(position = "top",
                                 title = NULL,
                                 override.aes = list(alpha = 0),
                                 theme = theme(
                                   legend.text = element_text(color = NA)
                                   )))

ggsave(filename = here("06figures/graphs/n_obs_by_window.pdf"),
       width = figure_scales$width, height = figure_scales$height,
       units = figure_scales$units, plot = .plot)

# Clean up environment
rm(.plot, window_obs, window_county_obs, window_sample_obs)


# ----------------- Show summary of balanced analysis sample ----------------- #
chosen_window <- 3

analysis_coal <- coal_cjars |>
  # Restrict to counties with all valid observations
  filter(if_all(c(fe_rate, mi_rate, ends_with("_prod")), ~ ! is.na(.))) |>
  # Restrict to the relevant window
  filter(min_event_time <= -chosen_window,
         max_event_time >= chosen_window,
         abs(event_time) <= chosen_window) |>
  # Remove counties who are not observed in all years in the window
  group_by(fips, off_type) |>
  filter(n() == 1 + chosen_window * 2) |>
  # Get the number of unique observations (counties)
  ungroup()

## Tabulate states where analysis counties are located
# 2-digit FIPS code to state name crosswalk
fips_xwalk <- read_excel(here("01data/helper/fips_xwalk.xlsx"),
                         col_types = rep("text", 3)) |>
  mutate(fips = ifelse(str_length(fips) == 4, paste0("0", fips), fips),
         state_fips = str_sub(fips, 1, 2)) |>
  filter(grepl("000$", fips)) |>
  select(state_fips, state_name = county_name)

# Create table of states where the analysis counties are located
analysis_coal |>
  select(fips) |>
  unique() |>
  mutate(state_fips = str_sub(fips, 1, 2)) |>
  left_join(fips_xwalk, by = "state_fips") |>
  group_by(state_fips, state_name) |>
  summarise(nobs = n()) |>
  ungroup() |>
  select(-state_fips) |>
  tabtex::tabtex(out = here("06figures/tables/state_frequency.tex"),
                 headings = c("state_name" = "State",
                              "nobs" = "Frequency"))

## ECDF of peak coal production years --- analysis panel vs. all coal counties
analysis_coal |>
  mutate(analysis_panel = TRUE) |>
  select(fips, analysis_panel) |>
  unique() |>
  right_join(coal_cjars, by = "fips") |>
  filter(event_time == -1, off_type == 0) |>
  mutate(analysis_panel = ifelse(is.na(analysis_panel), FALSE, analysis_panel),
         analysis_panel = factor(analysis_panel, levels = c(FALSE, TRUE),
                                 labels = c("Coal-producing counties in CJARS",
                                            "Balanced anlaysis panel"))) |>
  ggplot(aes(x = cohort_year, linetype = analysis_panel)) +
  stat_ecdf() +
  scale_x_continuous(breaks = seq(2000, 2024, 2), minor_breaks = 2000:2024) +
  guides(linetype = guide_legend(position = "bottom",
                                 title = NULL,
                                 direction = "horizontal")) +
  labs(x = "Calendar year of peak coal production",
       y = "Cumulative density of counties") +
  theme_paper +
  theme(legend.position = "bottom")

