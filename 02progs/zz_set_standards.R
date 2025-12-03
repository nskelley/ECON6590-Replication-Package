# ------------------------------------------------------------------------------
# --------------------------- ECON6590 Final Project ---------------------------
# --- Set standard settings/themes for graphs and tables.                    ---
# --------------- Robert Betancourt, Connor Bulgrin, Jenny Duan, ---------------
# --------------------- Nicholas Skelley, and Addie Sutton ---------------------
# ---------------------------- Created 22 Nov 2025 -----------------------------
# ---------------------------- Updated 22 Nov 2025 -----------------------------
# ------------------------------------------------------------------------------
# Packages
need <- c("here", "tidyverse")
have <- need %in% rownames(installed.packages())
if (any(!have)) install.packages(need[!have])
invisible(lapply(need, library, character.only = TRUE))

here::i_am("02progs/zz_set_standards.R")
rm(list = ls())
# ------------------------------------------------------------------------------

figure_scales <- list(
  "aspect_ratio" = .ar <- 3 / 2,
  "width" = .w <- 6,
  "height" = .w / .ar,
  "units" = "in"
)

theme_paper <- list(
  theme_classic(),
  theme(panel.grid.major = element_line(linewidth = 0.05, color = "#bbb"),
        panel.grid.minor.x = element_line(linewidth = 0.05, color = "#bbb"))
)

theme_paper_histogram <- list(
  theme_classic(),
  theme(panel.grid.major.y = element_line(linewidth = 0.05, color = "#bbb"),
        panel.grid.minor.y = element_line(linewidth = 0.05, color = "#bbb"),
        panel.grid.major.x = element_blank(),
        panel.grid.minor.x = element_blank())
)

ref_lines <- list(
  geom_vline(xintercept = -1, color = "red", linewidth = 0.4, 
             linetype = "dashed"),
  geom_hline(yintercept = 0, color = "black", linewidth = 0.4,
             linetype = "solid")
)

save(figure_scales,
     theme_paper_histogram,
     theme_paper,
     ref_lines,
     file = here("04work/standards/figure_standards.RData"))
