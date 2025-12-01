#!/usr/bin/env bash
set -euo pipefail

LOG="01data/supplemental/QCEW/combined/combine_bls_$(date +%Y%m%d_%H%M%S).log"

echo "Starting combine job at $(date)" | tee "$LOG"

duckdb -c "
PRAGMA threads=$(sysctl -n hw.ncpu);

COPY (
  SELECT 
    area_fips,
    own_code,
    industry_code,
    year,
    annual_avg_emplvl,
    total_annual_wages,
    annual_avg_wkly_wage,
    avg_annual_pay
  FROM read_csv_auto(
         '01data/supplemental/QCEW/*annual*/*.csv',
         header = true,
         union_by_name = true
       )
  WHERE industry_code IN ('10', '2121', '2111', '213113', '213111', '213112', '2212', '221112')
    AND year BETWEEN 2000 AND 2019
) TO '01data/supplemental/QCEW/combined/all_parquet'
  (FORMAT PARQUET, PARTITION_BY (year), OVERWRITE_OR_IGNORE 1);
" >>"$LOG" 2>&1

echo "Finished at $(date)" | tee -a "$LOG"