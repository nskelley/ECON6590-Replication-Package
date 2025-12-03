# ------------------------------------------------------------------------------
# --------------------------- ECON6590 Final Project ---------------------------
# --- Compile detailed coal production data from 1983-2023, add FIPS codes,  ---
# --- and aggregate at the county-year (FIPS-year) level.                    ---
# --- Data from https://www.eia.gov/coal/data.php#production                 ---
# --------------- Robert Betancourt, Connor Bulgrin, Jenny Duan, ---------------
# --------------------- Nicholas Skelley, and Addie Sutton ---------------------
# ---------------------------- Created 21 Nov 2025 -----------------------------
# ---------------------------- Updated 02 Dec 2025 -----------------------------
# ------------------------------------------------------------------------------
# Packages
need <- c("here", "tidyverse", "data.table", "readxl")
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

## Get raw coal data and combine into one data set
# Get the rows from every individual year into a single list
rows <- lapply(1983:2023, function(x) {
  .ext <- ".xls"
  .dir <- "raw"
  
  if (x %in% 2021:2022) {
    .dir <- "repaired_raw"
    .ext <- ".xlsx"
  } else if (x == 2023) {
    .ext <- ".xlsx"
  }
  
  .df <- read_excel(here("01data/eia_coal/",
                         .dir,
                         paste0("coalpublic", x, .ext)),
                    skip = 3) |>
    mutate(across(everything(), ~ as.character(.x)))
})

# Stack the rows from the previous block
coal <- bind_rows(rows) |>
  # Extract 2-character state code from PO address (for filling in anomalous
  # and inconsistent state FIPS information)
  mutate(po_state_code = str_extract(`Operating Company Address`, 
                                     "(?<=(, ))([A-Z][A-Z])")) |>
  # Select relevant columns
  select(year = "Year", mine_id = "MSHA ID", state_nm = "Mine State", 
         county_nm = "Mine County", coal_prod = "Production (short tons)",
         po_state_code) |>
  # Clean up and standardize string variables, correct anomalies
  mutate(state_nm = str_trim(sub("\\(.+", "", state_nm)),
         refuse_recovery = as.numeric(state_nm == "Refuse Recovery"),
         county_nm = str_to_upper(str_trim(county_nm)),
         state_nm = case_when(state_nm == "Maryland" & county_nm == "TUCKER" ~ 
                                "West Virginia",
                              # The following two are based on PO addresses
                              # because there is no county with the given name
                              # in the original state given (there is a county
                              # with the given name in the PO address' state)
                              state_nm == "Pennsylvania" & 
                                county_nm == "MONONGALIA" ~ "West Virginia",
                              state_nm == "West Virginia" & 
                                county_nm == "BUCHANAN" ~ "Virginia",
                              TRUE ~ state_nm),
         state_nm = str_to_upper(state_nm),
         county_nm = case_when(county_nm == "BIGHORN" ~ "BIG HORN",
                               county_nm == "CRAI" ~ "CRAIG",
                               county_nm == "CLAIRBORN" ~ "CLAIBORNE",
                               county_nm == "CLAIRBORNE" ~ "CLAIBORNE",
                               county_nm == "RAXTON" ~ "BRAXTON",
                               county_nm == "ST CLAIR" ~ "ST. CLAIR",
                               county_nm == "MUHLENBURG" ~ "MUHLENBERG",
                               county_nm == "ATHANS" ~ "ATHENS",
                               county_nm == "DE KALB" ~ "DEKALB",
                               TRUE ~ county_nm)) |>
  # Remove "Refuse Recovery" states -- see note below
  filter(state_nm != "REFUSE RECOVERY")

# Refuse recovery is a special type of production that extracts raw materials
# from discarded waste. Dropping Refuse Recovery mines for this round of
# results. Return to later TK.

.drop_regex <- "(Parish|County|Borough|Census Area)"

## Use crosswalk to create construct a FIPS field from county and state names
fips_xwalk <- read_excel(here("01data/helper/fips_xwalk.xlsx"),
                         col_types = rep("text", 3)) |>
  # Correct FIPS codes so that all codes are 5 digits and start with the 2-digit
  # state code (add leading 0 that may have been lost in Excel)
  mutate(fips = ifelse(str_length(fips) == 4, paste0("0", fips), fips),
         state_fips = str_sub(fips, 1, 2)) |>
  select(-note) |>
  rename("county_nm" = "county_name") |>
  # Remove "County," "Parish," etc., from county names
  mutate(county_nm = str_to_upper(str_trim(sub(.drop_regex, "", county_nm))))

# Extract 2-digit state FIPS codes by state name
fips_states_xwalk <- fips_xwalk |>
  filter(str_ends(fips, "000")) |>
  select(-fips) |>
  rename("state_nm" = "county_nm")

# Add 2-digit state FIPS
# fips_xwalk <- left_join(fips_xwalk, fips_states_xwalk, by = c("state_fips")) |>
#   mutate(county_nm = str_to_upper(str_trim(sub(.drop_regex, "", county_nm))))


coal_fips <- coal |>
  left_join(fips_states_xwalk, by = c("state_nm")) |>
  left_join(fips_xwalk, by = c("county_nm", "state_fips")) |>
  # Flag missing county names by using the state code (XX) followed by 999
  # e.g., for "-" county in Alabama, "01999"
  # NB "999" does not appear in any valid FIPS code, so this is an identifiable
  # flag.
  mutate(fips = ifelse(county_nm == "-", paste0(state_fips, "999"),
                       fips))

# Confirm there are no places with missing FIPS codes
if (nrow(filter(coal_fips, is.na(fips))) != 0) stop("Missing FIPS codes")


## Aggregate coal production by county and year
# Confirm coal_prod can be coerced to numeric
if (sum(grepl("^[\\d\\.]+$", coal_fips$coal_prod)) != 0) stop("Not all numeric")

# Coerce coal_prod column to numeric, then aggregate
coal_num <- coal_fips |>
  # Coerce to numeric
  mutate(coal_prod_n = as.numeric(coal_prod)) |>
  # Aggregate
  group_by(year, fips) |>
  summarise(avg_prod = mean(coal_prod_n, na.rm = TRUE),
            med_prod = median(coal_prod_n, na.rm = TRUE),
            tot_prod = sum(coal_prod_n, na.rm = TRUE)) |>
  ungroup()


## Save raw coal data
data.table::fwrite(coal_num,
                   file = here("05prepdata",
                               "Coal-Production-by-County_02-A02.csv"))