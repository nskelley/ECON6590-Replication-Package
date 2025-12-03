# Replication Package for: Criminal Mines

## Downloading

To download this replication package from GitHub, you can either run `git clone "https://github.com/nskelley/ECON6590-Replication-Package"` in the terminal on your local device, or you can select `Code > Download Zip` from the [repository's home page on GitHub](https://www.github.com/nskelley/ECON6590-Replication-Package).

## Package Organization

This replication package is divided into six subfolders that follow the process of developing results from raw data to production-ready tables and figures.

| Subfolder | Contents description |
| --- | --- |
| `01data/` | Contains *all* raw data, as well as basic helper data like crosswalks. Raw data have not been edited from their original form, except to restrict the data to specific columns. No data transformation or wrangling has been performed on these data. |
| `02progs/` | Contains all scripts used to clean and/or process data *in preparation for* analysis. These scripts are named so that they are sortable into a sequential order that respects dependencies (e.g., a script with the prefix "Z01_" may depend on code executed in the script prefixed "A01_"). |
| `03analysis/` | Contains all scripts used to analyze the data that result in tables or figures referenced in the text. |
| `04work/` | Contains raw output and intermediate R objects. |
| `05prepdata/` | Contains cleaned and prepared data sets used for further cleaning and for analysis. Data in `05prepdata/` contain suffixes indicating which script produced them. E.g., the suffix "\_02-A01" indicates that the data were produced by the script in `02progs/` with the "A01_" prefix. |
| `06figures/` | Contains the final exhibits used in the paper and reports. |

## Running the Code

You can run each individual script in `02progs/` and `03analysis/` independently, or you may simply run `00_run_all_code.R` in this main directory to progress from the raw data to production-ready exhibits.
* To run any of the code, **you must first open the R project, `6590_coal_repl.Rproj`**. You can open the project in RStudio by selecting File > Open Project..., or by double-clicking on `6590_coal_repl.Rproj` in your file explorer.
* If you choose to run the scripts individually, please note that they are organized and prefixed in a clearly sequential order, and scripts may not run properly (or at all!) if they are run out of order.
* Once you have run all the code, you will find our final graphs in `06figures/graphs/`.

*Please note that you must have R and RStudio installed on your device to properly run the code.* See below for specific versions and dependencies recommended for running the code.

## Raw Data

The raw data contained in this replication package are 
* Mine-level coal production data from the U.S. Energy Information Administration, a part of the U.S. Department of Energy. See the [EIA website](https://www.eia.gov/coal/data.php#production) for data (last accessed 2 Dec. 2025).
* Criminal Justice Administrative Records (CJARS) from the Justice Outcomes Explorer. See [cjars.org](https://joe.cjars.org/) from Finlay et al. (2024).

While you are welcome to independently download the raw CJARS data directly from JOE, we provide a compressed, column-limited subset of the county-level CJARS data in `01data/`.
* If you prefer to download the CJARS data yourself, please save the county-level CSV file in `01data/` in a new subdirectory, `county/`, and as `county_data.csv` (alternatively, edit the R code to suit your needs).
* In `02progs/B01_restrict_cjars.R`, we have left the lines used to restrict the original CJARS data from JOE commented out (lines 30-32). Remove or comment out current line 34, and un-comment lines 30-32 to run the code on the original CJARS data.

## R Packages and Dependencies

This replication package depends on R version 4.5.2 (2025-10-31) -- "[Not] Part in a Rumble." To confirm your R version, type `R --version` in a standard terminal, or `version` in the RStudio console.

### R Packages and Versions

| Package | Version |
| --- | --- |
| `here` | `1.0.1` |
| `tidyverse` | `2.0.0` |
| `ggplot2` | `4.0.1` |
| `dplyr` | `1.1.4` |
| `tidyr` | `1.3.1` |
| `data.table` | `1.17.8` |
| `readr` | `2.1.5` |
| `readxl` | `1.4.5` |
| `stringr` | `1.6.0` |
| `broom` | `1.0.10` |
| `fixest` | `0.13.2` |

#### `here`

The `here` package is used for managing platform-independent working directories and file management *in R projects*. `here::i_am` is in the header of each script and identifies where the script is in relation to the *intended* working directory. To access files within the directory, use `here(filepath)`.
