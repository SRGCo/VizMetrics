#! /bin/bash

# Clear out old CardActivity file & archive yesterdays CardActivity file to make space for new

#### Clear out old CardActivity file
rm /home/srg/db_files/CardActivity.old.csv

#### Archive yesterdays CardActivity file to make space for new
mv /home/srg/db_files/CardActivity.csv /home/srg/db_files/CardActivity.old.csv

