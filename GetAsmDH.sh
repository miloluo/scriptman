#!/bin/sh

mkdir /tmp/HC 2> /dev/null
rm -f /tmp/HC/asmdisks.lst   2> /dev/null
rm -f /tmp/HC/asm_diskh.sh   2> /dev/null

echo " "
echo "############################################"
echo " 1) Collecting Information About the Disks:"
echo "############################################"

sqlplus '/nolog' <<eof
connect / as sysdba
set linesize 90
col path format a60
set heading off
set head off
set feedback off
spool /tmp/HC/asmdisks.lst
select group_number,disk_number,path from v\$asm_disk_stat where group_number > 0 order by group_number,disk_number;
spool off;
eof
echo " "
echo " "

ls -l /tmp/HC/asmdisks.lst


echo " "
echo "############################################"
echo " 2) Generating "asm_diskh.sh" script."
echo "############################################"
echo " "

grep -v SQL  /tmp/HC/asmdisks.lst > /tmp/HC/asmdisks_tmp.lst

mv /tmp/HC/asmdisks_tmp.lst /tmp/HC/asmdisks.lst 

sed 's/ORCL:/\/dev\/oracleasm\/disks\//g' </tmp/HC/asmdisks.lst>/tmp/HC/asmdisks_NEW.lst

mv /tmp/HC/asmdisks_NEW.lst  /tmp/HC/asmdisks.lst



cat /tmp/HC/asmdisks.lst|while read LINE
do
comm=`echo $LINE|awk '{print "dd if="$3 " of=/tmp/HC/dsk_"$1"_"$2".dd bs=1048576 count=1"}'`
echo $comm >> /tmp/HC/asm_diskh.sh
done 

chmod 700 /tmp/HC/asm_diskh.sh

ls -l /tmp/HC/asm_diskh.sh

echo " "
echo "############################################"
echo " 3) Executing  asm_diskh.sh script to "
echo "    generate dd  dumps."
echo "############################################"
echo " "


### For display only
/tmp/HC/asm_diskh.sh 2> /dev/null
ls -l /tmp/HC/*dd

echo " "
echo "############################################"
echo " 4) Compressing dd dumps in the next format:"
echo "    (asm_dd_header_all_<date_time>.tar)"
echo "############################################"
echo " "




NOW=$(date +"%m-%d-%Y_%T")

tar -cvf /tmp/HC/asm_dd_header_all_$NOW.tar /tmp/HC/*.dd 2> /dev/null

compress /tmp/HC/asm_dd_header_all_$NOW.tar

ls -l /tmp/HC/*.Z





