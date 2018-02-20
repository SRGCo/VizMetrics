#! /bin/bash

set -x

for file in /home/srg/db_files/incoming/px/CardActivity*.csv
do
    tail -n+3 "$file"  >> /home/srg/db_files/CardActivity.csv
done
