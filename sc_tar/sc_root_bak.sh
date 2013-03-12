#!/usr/bin/sh

##上传备份数据按星期
TodayDate=`date +'%u'`
DIR=/tmp
su - union <<!
echo "-------------------------------tar cebip-------------------------------"
cd /home/union/
tar cvf  $DIR/rec_$TodayDate.tar  -C /home/union  * .profile
compress -f $DIR/rec_$TodayDate.tar
!

su - cebip <<!
echo "-------------------------------tar cebip-------------------------------"
/home/cebip/sbin/sc_ftp_bak.sh
!
#清理
rm -rf $DIR/rec_$TodayDate.tar.Z
