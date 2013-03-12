#!/bin/sh

banner start db

varyonvg appvg
sleep 5
mount /ora_archive

su - oracle <<!
sqlplus /nolog <<EOF
conn / as sysdba
startup
quit
EOF
exit
!
