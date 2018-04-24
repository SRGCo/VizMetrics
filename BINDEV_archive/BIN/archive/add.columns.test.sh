# Modify test
#! /bin/bash
# Next line turns echo on
set -x

sed -e 's/$/,,,,,,,,,,/g' -e '$ s/,$//' /home/srg/db_files/incoming/ItemDetail.csv  > /home/srg/db_files/incoming/new_file && mv /home/srg/db_files/incoming/new_file /home/srg/db_files/incoming/ItemDetail.csv
