#! /bin/bash

date=`date +%Y-%m-%d`
dayofweek=`date +%u`

if [ $dayofweek -ne 1 ] && [ $dayofweek -ne 2 ]
then
    perl /home/kibini/kibini_prod/tools/ADM_resa_appels.pl
fi