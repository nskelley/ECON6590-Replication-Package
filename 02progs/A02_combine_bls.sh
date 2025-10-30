#!/usr/bin/env bash
set -euo pipefail  # safer shell defaults

LOG="01data/supplemental/QCEW/combined/combine_bls_$(date +%Y%m%d_%H%M%S).log"

echo "Starting combine job at $(date)" | tee "$LOG"

duckdb -c "
PRAGMA threads=$(sysctl -n hw.ncpu);

COPY (
  SELECT *
  FROM read_csv_auto(
         '01data/supplemental/QCEW/raw/**/*.csv*',
         header = true,
         union_by_name = true
       )
) TO '01data/supplemental/QCEW/combined/all_parquet'
  (FORMAT PARQUET, PARTITION_BY (year), OVERWRITE_OR_IGNORE 1);
" >>"$LOG" 2>&1

echo "Finished at $(date)" | tee -a "$LOG"