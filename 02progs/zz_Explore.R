# ------------------------------------------------------------------------------
# --------------------------- ECON6590 Final Project ---------------------------
# --- Explore JOE data.                                                      ---
# ------------------------------ Nicholas Skelley ------------------------------
# ---------------------------- Created 23 Oct 2025 -----------------------------
# ---------------------------- Updated 24 Oct 2025 -----------------------------
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

test <- fread("https://www.bls.gov/cew/about-data/downloadable-file-layouts/quarterly/naics-based-quarterly-layout-csv.csv")
