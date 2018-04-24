#!/bin/bash
 SRCDIR="/home/srg/"
 DESTDIR="/media/srg/Seagate Backup plus Drive/Backup"
 FILENAME=ug-$(date +%-Y%-m%-d)-$(date +%-T).tgz
 tar --create --gzip --file=$DESTDIR$FILENAME $SRCDIR

