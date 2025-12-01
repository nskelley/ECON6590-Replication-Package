# ------------------------------------------------------------------------------
# --------------------------- ECON6590 Final Project ---------------------------
# --- Do the actual continuous-dosage event study.                           ---
# --------------- Robert Betancourt, Connor Bulgrin, Jenny Duan, ---------------
# --------------------- Nicholas Skelley, and Addie Sutton ---------------------
# ---------------------------- Created 22 Nov 2025 -----------------------------
# ---------------------------- Updated 22 Nov 2025 -----------------------------
# ------------------------------------------------------------------------------
# Packages
need <- c("here", "tidyverse", "data.table", "did", "broom", "fixest")
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
                        colClasses = list("character" = "fips")) |>
  mutate(fips = factor(fips)) |>
  group_by(fips) |>
  mutate(post_event_prod = 
           ifelse(sum(event_time == "0") > 0,
                  unique(tot_coal_prod[event_time == "0"])[1],
                  NA),
         treat_dose = -(post_event_prod - coal_prod_max) / coal_prod_max,
         cal_year = factor(cohort_year),
         min_event_time = min(event_time),
         max_event_time = max(event_time)) |>
  ungroup()

# Load scale and theme standardizers
load(here("04work/standards/figure_standards.RData"))

## Generate combinations of outcomes for the event study
out_names <- data.frame(outcome = c("fe_rate", "mi_rate"),
                        sev_comp = c("felony", "misdemeanor"))
cat_names <- data.frame(crime_cat = c(0, 1, 2, 3),
                        cat_comp = c("all", "violent", "property", 
                                     "drug-related"))
fe_names <- data.frame(fe = c("fips + cohort_year"),
                       fe_lbl = c("basicfe"))
dosed_names <- data.frame(dosed = c(TRUE, FALSE),
                          dosed_lbl = c("cts-trt", "binary-trt"))

outcome <- c("fe_rate", "mi_rate")
crime_cat <- c(0, 1, 2, 3)
dosed <- c(TRUE, FALSE)
req_periods <- c(5)
fe <- c("fips + cohort_year")
extra_cov <- c(NULL)
all_es <- crossing(outcome, crime_cat, dosed, req_periods, fe, 
                   extra_cov) |>
  left_join(out_names, by = "outcome") |>
  left_join(cat_names, by = "crime_cat") |>
  left_join(fe_names, by = "fe") |>
  left_join(dosed_names, by = "dosed") |>
  mutate(ylab = paste0("Rate of ", cat_comp, " ", sev_comp, 
                       " charges\n(per 100,000)"))


## Run event studies
ref_row <- data.frame(term = NA, estimate = 0, std.error = 0, statistic = NA,
                      p.value = NA, event_time = -1)

event_studies <- lapply(1:nrow(all_es), function(rowi) {
  .row <- all_es[rowi, ]
  .formula <- paste(
    .row$outcome, "~",
    ifelse(.row$dosed,
           "i(event_time, treat_dose, ref = -1)",
           "i(event_time, ref = -1)"),
    ifelse(!is.null(.row$fe),
           paste("|", .row$fe),
           "")
  ) |>
    str_trim() |>
    as.formula()
  
  .es <- coal_cjars |>
    group_by(fips) |>
    filter(min_event_time <= -.row$req_periods,
           max_event_time >= .row$req_periods,
           off_type == .row$crime_cat, 
           abs(event_time) <= .row$req_periods) |>
    feols(.formula,
          data = _,
          cluster = ~ fips)
  .nobs <- .es$nobs
  .es <- .es |>
    tidy() |>
    mutate(event_time = str_extract(term, "-?\\d+"))
    
  .plt <- .es |>
    rbind(ref_row) |>
    mutate(ci_min = estimate + qnorm(0.025) * std.error,
           ci_max = estimate + qnorm(0.975) * std.error) |>
    ggplot(aes(x = as.numeric(event_time), y = estimate)) +
    geom_point() +
    geom_line(linewidth = 0.6) +
    geom_ribbon(aes(ymin = ci_min, ymax = ci_max), 
                linetype = "dashed", color = "#555", linewidth = 0.5,
                fill = "transparent") +
    scale_x_continuous(breaks = -5:5) +
    ref_lines +
    theme_paper +
    labs(x = "Years since coal production peak",
         y = .row$ylab)
  
  ggsave(filename = here("06figures/graphs/event_study/",
                         paste0("ES_", 
                                paste0(select(.row, ends_with("_comp"), 
                                              ends_with("_lbl"))[1, ],
                                       collapse = "_"),
                                ".pdf")),
         height = figure_scales$height, width = figure_scales$width,
         units = figure_scales$units)
  return(list(plot = .plt,
              coefs = .es,
              obs = .nobs))
})

obs <- sapply(event_studies, "[[", "obs")
<<<<<<< HEAD
obs
=======
>>>>>>> d3654f68a549fb6080a30bd9b9f52d8622e104d3
