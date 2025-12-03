# ------------------------------------------------------------------------------
# --------------------------- ECON6590 Final Project ---------------------------
# --- Run continuous-dose event studies.                                     ---
# --------------- Robert Betancourt, Connor Bulgrin, Jenny Duan, ---------------
# --------------------- Nicholas Skelley, and Addie Sutton ---------------------
# ---------------------------- Created 22 Nov 2025 -----------------------------
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
         cal_year = factor(cohort_year)) |>
  ungroup()


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
fe <- c("fips + cohort_year")
extra_cov <- c(NULL)

# All possible combinations
all_es <- crossing(outcome, crime_cat, dosed, fe, 
                   extra_cov) |>
  left_join(out_names, by = "outcome") |>
  left_join(cat_names, by = "crime_cat") |>
  left_join(fe_names, by = "fe") |>
  left_join(dosed_names, by = "dosed") |>
  mutate(ylab = paste0("Rate of ", cat_comp, " ", sev_comp, 
                       " charges\n(per 100,000)"))
rm(list = c("out_names", "cat_names", "fe_names", "dosed_names", "outcome",
            "crime_cat", "dosed", "fe", "extra_cov"))


## Run event studies
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
    filter(off_type == .row$crime_cat) |>
    feols(.formula,
          data = _,
          cluster = ~ fips)
  
  .nobs <- .es$nobs
  .es <- .es |>
    tidy() |>
    mutate(event_time = str_extract(term, "-?\\d+"))
  
  return(list(coefs = .es,
              esnm = paste0(select(.row, ends_with("_comp"), 
                                   ends_with("_lbl"))[1, ],
                            collapse = "_"),
              ylab = .row$ylab,
              nobs = .nobs))
})

save(event_studies, file = here("04work/analysis",
                                "event_studies_complete_03-A02.Rdata"))
