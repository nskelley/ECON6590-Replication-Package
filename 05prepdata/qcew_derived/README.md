# QCEW-derived data

## Data source and processing
> *If preferred, [jump directly to data sets](#files-and-fields).*

Data come from the U.S. Bureau of Labor Statistics' (BLS) Quarterly Census of Employment and Wages (QCEW). More information about the QCEW can be found [here](https://www.bls.gov/cew/). We use the county-industry data ([information on fields and format](https://www.bls.gov/cew/about-data/downloadable-file-layouts/annual/naics-based-annual-layout.htm)) for each year from 1998 to 2023.

### Processing

Data are downloaded in the `02progs/A01` shell script, then combined into a single `.csv` file in the `02progs/A02` shell script.

In `02progs/A03`, we create two cohesive data sets---one for state- and national-level analysis and the other for county-level analysis---that restrict the data to essential fields and observations in order to facilitate further processing and analysis. In both pre-processed data sets, we impose the following inclusion restrictions:
1. Year in 2000-2019 range
2. `industry_code` denotes a relevant industry for our analyses:
    - We keep NAICS codes 10, 2121, 2111, 213113, 213111, 213112, 2212, and 221112 (defined below)

In the data for county-level analysis, we impose the following inclusion restrictions:
1. No state-level aggregated data (remove FIPS codes ending in "000").
2. States of Illinois, Indiana, Kentucky, Maryland, New York, Ohio, Pennsylvania, Tennessee, Virginia, or West Virginia.

The 11-state inclusion restriction described is based on the definition of "Appalachia" offered in the U.S. Energy Information Administration's (EIA) May 2024 [Drilling Productivity Report](https://www.eia.gov/petroleum/drilling/), as well as data from EIA's [Coal Data Browser](https://www.eia.gov/coal/data/browser/) and a map showing the top coal-producing states in the U.S., [also from EIA](https://www.eia.gov/energyexplained/coal/where-our-coal-comes-from.php).

For the data for state- and national-level analyses, we impose the following inclusion criteria:
1. FIPS codes ending in `"000"` (i.e., state-level aggregates)
2. FIPS codes whose first two digits denote one of the 50 U.S. states or the District of Columbia (excluding, e.g., the U.S. Virgin Islands, the Federated States of Micronesia, and Puerto Rico).

**State FIPS codes** (as R vectors)

```R
state_fips <- c(17, 18, 21, 24, 26, 36, 39, 42, 47, 51, 54)

state_fips_to_exclude <- c("60", "03", "81", "07", "64", "14", "66", "84", "86",
                           "67", "89", "68", "71", "76", "69", "70", "95", "43",
                           "72", "74", "52", "78", "79")
```

**NAICS codes**

| Code | Industry denoted |
|---|---|
| 10 | All industries |
| 2111 | Oil and gas extraction |
| 2121 | Coal mining |
| 2212 | Natural gas distribution |
| 213111 | Drilling of oil and gas wells |
| 213112 | Support activities for oil and gas operations |
| 213113 | Support activities for coal mining |
| 221112 | Fossil fuel electric power generation |

## Files and fields

There are three prepared data sets provided in this directory:

| File name | Nickname | Description |
|---|---|---|
| `coal_emp_share_2002_by_county.csv` | 2002 County Coal Share | Share of employment accounted for by coal in 2002, separated by county |
| `coal_gas_emp_by_state-year.csv` | Yearly Coal and Gas Employment | Total levels of employment in coal mining and oil and natural gas production, separated by state and year (2000-2019) |
| `nationwide_coal_empl_by_year.csv` | National Coal Labor | Total coal employment and wage data at the national level, separated by year (2000-2019) |

### Fields

#### 2002 County Coal Share

| Field | Description |
|---|---|
| `year` | Year of data (should always be 2002) |
| `area_fips` | 5-digit FIPS code for county |
| `coal_emplvl_2002` | Number of jobs/employment level in coal mining (NAICS `2121`) in the specified county and year |
| `tot_emplvl_2002` | Number of jobs/employment level in any industry (NAICS `10`) in the specified county and year |
| `coal_emp_share_2002` | `coal_emplvl_2002 / tot_emplvl_2002` |

#### National Coal Labor

| Field | Description |
|---|---|
| `year` | Year of data |

The other fields follow specific patterns and come in combinations of elements defined by those patterns.

**`auto` and `man`**
* The `auto` prefix denotes national-level data given by the raw QCEW data, possibly including territories outside the 50 states and District of Columbia.
* The `man` prefix denotes national-level data manually aggregated using the 51 FIPS codes that *exclude* extraneous territories.

**`emplvl`, `totwages`, and `tot_rwages`**
* `emplvl` denotes employment level/number of jobs in the coal mining industry (NAICS `2121`)
* `totwages` denotes total earned wages in the coal mining industry (NAICS `2121`)
* `tot_rwages` denotes total earned wages from the coal mining industry (NAICS `2121`) in 2017USD, based on average annual CPI numbers provided by the [Federal Reserve Bank of Minneapolis](https://www.minneapolisfed.org/about-us/monetary-policy/inflation-calculator/consumer-price-index-1913-)

**`nat_*` and `nat_oty_*_pct_chg`**
* Fields following the `nat_*` pattern (e.g., `auto_nat_emplvl`) report the relevant level in the specified year
* Fields following the `nat_oty_*_pct_chg` pattern (e.g., `auto_nat_oty_emplvl_pct_chg`) pattern report the percentage change in level in the specified year from the prior year.
  * For example, `auto_nat_oty_emplvl_pct_chg` when `year=2005` reports the percent change in total coal-mining jobs in the U.S. from 2004 to 2005.

Combining the above patterns, the fields in the data are
* `year`
* `auto_nat_emplvl`
* `man_nat_emplvl`
* `auto_nat_totwages`
* `man_nat_totwages`
* `auto_nat_tot_rwages`
* `man_nat_tot_rwages`
* `auto_nat_oty_emplvl_pct_chg`
* `man_nat_oty_emplvl_pct_chg`
* `auto_nat_oty_totwages_pct_chg`
* `man_nat_oty_totwages_pct_chg`
* `auto_nat_oty_tot_rwages_pct_chg`
* `man_nat_oty_tot_rwages_pct_chg`

#### Yearly Coal and Gas Employment

| Field | Description |
|---|---|
| `year` | Year of data (2000-2019) |
| `state_fips` | 2-digit FIPS code denoting the state (includes DC and a national "US" code) |
| `overall_state_emplvl` | Total state employment level/number of jobs in any industry (NAICS code `10`) |
| `gas_state_emplvl` | Total state employment level/number of jobs in oil and gas production (NAICS code `2111`) |
| `coal_state_emplvl` | Total state employment level/number of jobs in coal mining (NAICS code `2121`) |
