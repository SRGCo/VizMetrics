#! /bin/bash
# Next line turns echo on
set -v


### REMOVE FIRST ROW/HEADERS BEFORE IMPORTING

for filename in / 
do
ECHO $filename
	tail -n+2 $filename > General.card.activity.full.csv 
done




