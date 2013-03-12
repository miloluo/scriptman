#!/usr/bin/ksh
. ~/.profile
#########################################
#函数，得到上个月的时间（时间格式：YYYYMM)
get_last_month() {
    DATEYEAR=`date   +%Y%m`
    year=`date   +%Y`
    month=`date   +%m`
    if [ ${month} -ge 2 -a ${month} -le 12 ]
    then
        lastmonth=`expr ${month} - 1`
        if [ ${lastmonth} -lt 10 ]
        then 
            lastmonth="0${lastmonth}"
         fi
    else
        lastmonth=12
        year=`expr ${year} - 1`
    fi
    newdate=${year}${lastmonth}
    echo ${newdate}
}
####################################
get_last_month |read LASTMONTH

#####获取上上个月的时间##########add by wanzb 20110209
ksh /jfexp/billing/shell/tools/getSpecMonth ${LASTMONTH} -1|read LASTLASTMONTH
#################################

rm -f /jfexp/crm/shell/nohup.out
mkdir -p /jfexp/crm/crm_data/month/${LASTMONTH} 
mkdir -p /jfexp/crm/log/month/${LASTMONTH} 

####上上个月的时间改成上个月的时间####
vi         /jfexp/crm/shell/month.list <<! >/dev/null
:1,$ s/${LASTLASTMONTH}/${LASTMONTH}/g
:x
!
#################################

cat /jfexp/crm/shell/month.list|while read line
do
owner=`echo $line|awk '{print $1}'`
table=`echo $line|awk '{print $2}'`
tables=${owner}.${table}
#/usr/sbin/mknod /jfexp/crm/shell/month/$tables p
#gzip  </jfexp/crm/shell/month/$tables >/jfexp/crm/crm_data/month/${LASTMONTH}/${tables}.dmp.gz &
exp monitor/monitor@CRMDB file=/jfexp/crm/crm_data/month/${LASTMONTH}/${tables}.dmp log=/jfexp/crm/log/month/${LASTMONTH}/${tables}.log tables=$tables triggers=n constraints=n direct=y 
done

#gzip
cd /jfexp/crm/crm_data/month/${LASTMONTH}
#gzip *dmp

sleep 30

#fin
touch finish.txt

