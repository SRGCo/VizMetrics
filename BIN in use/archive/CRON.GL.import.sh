#! /bin/bash

mysql -uroot -ps3r3n1t33 << EOF

USE SRG_dev;

TRUNCATE TABLE GL_data;

Load data local infile '/home/srg/db_files/GP.raw.1.csv' into table GL_data fields terminated by ',' lines terminated by '\n';

EOF


