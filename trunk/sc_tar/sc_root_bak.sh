#!/usr/bin/sh

##�ϴ��������ݰ�����
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
#����
rm -rf $DIR/rec_$TodayDate.tar.Z
