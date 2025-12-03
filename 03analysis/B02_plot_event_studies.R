# ------------------------------------------------------------------------------
# --------------------------- ECON6590 Final Project ---------------------------
# --- Plot the results of the event studies performed in B01.                ---
# --------------- Robert Betancourt, Connor Bulgrin, Jenny Duan, ---------------
# --------------------- Nicholas Skelley, and Addie Sutton ---------------------
# ---------------------------- Created 22 Nov 2025 -----------------------------
# ---------------------------- Updated 02 Dec 2025 -----------------------------
# ------------------------------------------------------------------------------
# Packages
need <- c("here", "tidyverse")
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

# Load scale and theme standardizers
load(here("04work/standards/figure_standards.RData"))

# Load event studies
load(here("04work/analysis/event_studies_complete_03-A02.Rdata"))

# Reference row of coefficients data frame
ref_row <- data.frame(term = NA, estimate = 0, std.error = 0, statistic = NA,
                      p.value = NA, event_time = -1)

lapply(event_studies, function(x) {
  .es <- x$coefs
  
  .plot <- .es |>
    rbind(ref_row) |>
    mutate(ci_min = estimate + qnorm(0.025) * std.error,
           ci_max = estimate + qnorm(0.975) * std.error) |>
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
         y = x$ylab)
  
  ggsave(filename = here("06figures/graphs/event_study/",
                         paste0("ES_", x$esnm, ".pdf")),
         height = figure_scales$height, width = figure_scales$width,
         units = figure_scales$units)
})
