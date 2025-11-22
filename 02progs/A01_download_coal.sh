#!/bin/sh

cd 01data/eia_coal/raw/

for ((YEAR = 1983; YEAR <= 2022; YEAR++))
do
    toDownload="coalpublic${YEAR}"

    if [ ! -f "$toDownload.xls" ]; then
        curl "https://www.eia.gov/coal/data/public/xls/${toDownload}.xls" > "$toDownload.xls"
    fi
done

curl "https://www.eia.gov/coal/data/public/xls/coalpublic2023.xlsx" > "coalpublic2023.xlsx"

# If this line does not work, try running 'brew install rename' in the terminal first
# rename "s/_/-/g" *


# https://www.eia.gov/coal/data/public/xls/coalpublic2022.xls