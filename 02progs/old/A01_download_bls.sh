#!/bin/sh

cd 01data/supplemental/QCEW/raw/

for ((YEAR = 1998; YEAR <= 2023; YEAR++))
do
    toDownload="${YEAR}_annual_by_industry"

    if [ ! -f "$toDownload.zip" ]; then
        curl "https://data.bls.gov/cew/data/files/$YEAR/csv/$toDownload.zip" > "$toDownload.zip"
    fi
    if [ ! -f "$toDownload.csv" ]; then
        unzip -o "$toDownload.zip"
        rm "$toDownload.zip"
    fi
done

# If this line does not work, try running 'brew install rename' in the terminal first
rename "s/_/-/g" *