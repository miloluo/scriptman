#!/bin/sh

banner stop db

su - oracle<<!
sqlplus /nolog
conn / as sysdba
shutdown immediate
quit
!

umount /ora_archive

varyoffvg appvg
sleep 5
