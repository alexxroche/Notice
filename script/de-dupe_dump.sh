#!/bin/bash

# this is like fdupes but based on files name and size
#
# This is a support script for the crontab entry
# 46 7,*/2 * * * pushd /var/www/sites/Notice 2>&1 1>/dev/null; ./script/dump_notice_db.pl; popd 2>&1 1>/dev/null

FMATCH='notice_*.mysql'
THIS_DIR='config'

for FSIZE in `ls -la $THIS_DIR/$FMATCH|awk '{print $5}'|sort -u`
do
    #echo $FSIZE
    ls -l $THIS_DIR/$FMATCH|grep $FSIZE|tail -n$(( $(ls -la $THIS_DIR/$FMATCH|grep $FSIZE|wc -l) - 1))|awk '{print $NF}'|xargs rm -f
done

# if my awk was stronger I'd probably start with something like
#  ls -l notice_*mysql |awk '{ print $5 " " $NF}'
# though
#  find . -name "notice_*mysql"
# is probably the best path

