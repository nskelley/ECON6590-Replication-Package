# ------------------------------------------------------------------------------
# --------------------------- ECON6590 Final Project ---------------------------
# --- Tabulate the results of event studies performed in B01.                ---
# --------------- Robert Betancourt, Connor Bulgrin, Jenny Duan, ---------------
# --------------------- Nicholas Skelley, and Addie Sutton ---------------------
# ---------------------------- Created 02 Dec 2025 -----------------------------
# ---------------------------- Updated 02 Dec 2025 -----------------------------
# ------------------------------------------------------------------------------
# Packages
need <- c("here", "tidyverse", "data.table", "broom")
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

# Load event studies
load(here("04work/analysis/event_studies_complete_03-A02.Rdata"))

# Select relevant event studies
es <- Filter(function(x) x$esnm %in% c("felony_all_basicfe_cts-trt",
                                       "misdemeanor_all_basicfe_cts-trt"),
             event_studies)

.tb <- lapply(es, function(x) {
  # Get pre- and post-treatment means from event studies
  means <- x$coefs |>
    group_by(event_time >= 0) |>
    summarise(t = mean(estimate, na.rm = TRUE)) |>
    rename("rown" = 1, "est" = 2) |>
    mutate(rown = ifelse(rown, "Post-treatment mean", "Pre-treatment mean"))
  # Get slope of post-treatment event study coefficients
  slope <- x$coefs |>
    mutate(event_time = as.numeric(event_time)) |>
    filter(event_time >= 0) |>
    lm(estimate ~ event_time, data = _) |>
    tidy()
  # Combine summary statistics into one table
  tab <- rbind(means, 
               tibble(rown = c("Event study slope", "Obs."),
                      est = c(slope$estimate[slope$term == "event_time"],
                              x$nobs))) |>
    rename(!!str_extract(x$esnm, "^[a-z]+") := "est")
  return(tab)
})

# Combine summary statistics for each event study into one table
left_join(.tb[[1]], .tb[[2]], by = "rown") |>
  # Reformat numbers for LaTeX
  mutate(across(where(is.numeric), 
                ~ ifelse(rown == "Obs.", paste0("$", sprintf("%.f", .x), "$"),
                         paste0("$", sprintf("%.2f", .x), "$")))) |>
  # Save table as a tabular in a .tex file
  tabtex::tabtex(out = here("06figures/tables/event_study_table.tex"),
                 headings = c("rown" = "", "felony" = "Felony charges",
                              "misdemeanor" = "Misdemeanor charges"),
                 blank_headings = TRUE)
