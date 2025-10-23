# ------------------------------------------------------------------------------
# --------------------------- ECON6590 Final Project ---------------------------
# --- Produce random samples of 8,000 observations per year of interest      ---
# --- (2017-2022).                                                           ---
# ------------------------------ Nicholas Skelley ------------------------------
# ---------------------------- Created 23 Oct 2025 -----------------------------
# ---------------------------- Updated 25 Oct 2025 -----------------------------
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

groups <- c("commutingzone", "county", "nationwide", "state")
set.seed(182302)

init_vsize <- mem.maxVSize()
mem.maxVSize(vsize = 1e11)

for (lvl in groups) {
  fread(paste0("01data/", lvl, "/", lvl, "_data.csv")) |>
    filter(cohort_year %in% 2017:2022) |>
    group_by(cohort_year) |>
    sample_n(min(8000, n())) |>
    fwrite(paste0("05prepdata/demo_subsamples/", lvl, "_sub_data.csv"))
}

mem.maxVSize(vsize = init_vsize)