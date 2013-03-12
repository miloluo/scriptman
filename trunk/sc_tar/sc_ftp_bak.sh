#!/usr/bin/sh

##上传备份数据按星期
#TodayDate=`date +'%Y%m%d'`
TodayDate=`date +'%u'`
BAKDIR=/tmp
##备份机器地址,用户,密码需要分行自己设置
remoteip=10.1.18.57
username=logview
passwd=logview
remopath=/zbbak/cebip/back
#remopath=/home/logview
##备份数据库表结构
cd $BAKDIR
exp $PBUSERNAME/$PBPASSWD file=$BAKDIR/cebipdesc_$TodayDate.dmp log=$BAKDIR/cebipdesc_exp_$TodayDate.log rows=n
##备份基础数据
exp $PBUSERNAME/$PBPASSWD file=$BAKDIR/cebip_$TodayDate.dmp log=$BAKDIR/cebip_exp_$TodayDate.log tables='T_EB_AGENTERR_INFO', 'T_EB_BATCHCTL', 'T_EB_BATCHSLD', 'T_EB_BEPAY_ERRLOG', 'T_EB_BEPAY_OUTPUT', 'T_EB_BEPAY_TIMEOUT', 'T_EB_CARDINF', 'T_EB_CITY_INFO', 'T_EB_CREDIT_INFO', 'T_EB_CUPMSGLOG','T_EB_CUPSFILESEND', 'T_EB_CUPSSETTJOUR', 'T_EB_CUPS_CARDBIN', 'T_EB_CUPS_NONBIN', 'T_EB_CUSTOM_INFO', 'T_EB_CUST_INFO', 'T_EB_CUST_PRCOL', 'T_EB_DEV_AUTH_TRAN_REC', 'T_EB_DEV_AUTH_TRAN_REC_HIS', 'T_EB_DEV_INFO_COLLECT', 'T_EB_DEV_RUN_PARAM', 'T_EB_FEECOD', 'T_EB_FEEFRG',  'T_EB_HSTSTLMDTL', 'T_EB_HSTSTLSUM', 'T_EB_INSTSTLDTL', 'T_EB_INSTSTLSUM', 'T_EB_INST_INFO', 'T_EB_INTSTLDTL', 'T_EB_MBFE_OUTPUT', 'T_EB_MBFE_SNDPKGINFO', 'T_EB_MER_FEE_RATIO', 'T_EB_MER_INFO', 'T_EB_MER_JOUR', 'T_EB_POS_INFO', 'T_EB_PUBPAY_AUTHMODE', 'T_EB_PUBPAY_CIENTAGE', 'T_EB_PUBPAY_SP_INFO', 'T_EB_RPT_TIMES', 'T_EB_SWIFT_OUTPUT', 'T_EB_UPTRCODE', 'T_EB_UPTRCODE_CONV', 'T_EB_ZFY_AREANO', 'T_EB_ZFY_MANU', 'T_EB_ZFY_MERINFO', 'T_EB_ZFY_TERMINFO', 'T_PB_ADM_TLR', 'T_PB_ADM_TRAN', 'T_PB_ADM_TRAN_JRNL', 'T_PB_ANS_CODE','T_PB_APPLYNO', 'T_PB_AREA', 'T_PB_ATOM_FUNC', 'T_PB_ATOM_PARAM', 'T_PB_ATOM_TRAN', 'T_PB_BUSI_DICT', 'T_PB_BUSI_DICT_FLD', 'T_PB_BUSI_GROUP', 'T_PB_BUSI_TYPE', 'T_PB_CHNL', 'T_PB_CODE_EXPLAIN', 'T_PB_COMM_DIR', 'T_PB_COMM_STRUCT', 'T_PB_COMM_STRUCT_FLD', 'T_PB_CTRL_SBL', 'T_PB_CTRL_STREAM', 'T_PB_CURR', 'T_PB_DELAY', 'T_PB_DET_DEF', 'T_PB_FLOW', 'T_PB_FLOW_PARA', 'T_PB_GATE', 'T_PB_HOST_PKG', 'T_PB_HOST_PKG_FLD', 'T_PB_JOUR_MSG', 'T_PB_JOUR_POOL', 'T_PB_JOUR_POOL_BAKE',   'T_PB_MBFE_FLAG', 'T_PB_MBFE_OUTPUT', 'T_PB_PARA_TRANSFER', 'T_PB_PGER_INFO', 'T_PB_PKG', 'T_PB_PKG_CONV', 'T_PB_PKG_DIR','T_PB_PKG_FLD', 'T_PB_PROC_FUNC', 'T_PB_RET_CODE', 'T_PB_RET_CONV', 'T_PB_RET_PARA', 'T_PB_REVERSE', 'T_PB_REVERSE_HIS', 'T_PB_SYSSTAT', 'T_PB_SYS_CFG', 'T_PB_SYS_DATA_TYPE', 'T_PB_SYS_TYPE', 'T_PB_TRAN_CODE', 'T_PB_TRAN_CODE_CONV', 'T_PB_TRAN_PKG', 'T_PB_TRIG_CTRL', 'T_PB_TRIG_DETAIL', 'T_PB_VAR_POOL_NEW'
##备份主机sequence
sqlplus -s $PBUSERNAME/$PBPASSWD <<!
set head off
set feed off
spool $BAKDIR/seq_$TodayDate.sql
select 'create sequence '||sequence_name||  ' minvalue '||min_value||  ' maxvalue '||max_value||  '
start with '||last_number||  ' increment by '||increment_by||  (case when cache_size=0 then ' nocach
e' else ' cache '||cache_size end) ||' cycle' ||';' from user_sequences where sequence_name='PBJOURNO';
spool off
exit
!

if [ -f $HOME/etc/dir.list ]
then
rm $HOME/etc/dir.list
fi
cd $HOME
find download -type d >$HOME/etc/dir.list
find log -type d >>$HOME/etc/dir.list
tar cvf $BAKDIR/cebip_$TodayDate.tar -C $HOME `cd $HOME;ls |grep -v download|grep -v log`
tar uvf $BAKDIR/cebip_$TodayDate.tar  -C $HOME .profile
tar uvf $BAKDIR/cebip_$TodayDate.tar  -C $HOME/etc dir.list

compress -f $BAKDIR/cebip_$TodayDate.dmp
compress -f $BAKDIR/cebip_$TodayDate.tar
compress -f $BAKDIR/cebipdesc_$TodayDate.dmp
##传输到备份机
ftp -n -i $remoteip << ! >$BAKDIR/ftp_bak.log 2>&1
user $username $passwd
bin
lcd $BAKDIR
cd  $remopath
put seq_$TodayDate.sql
put cebip_$TodayDate.dmp.Z
put cebip_$TodayDate.tar.Z
put cebipdesc_$TodayDate.dmp.Z
put rec_$TodayDate.tar.Z
by
!


##清除掉本地数据
rm -rf $BAKDIR/cebip_$TodayDate.dmp.Z
rm -rf $BAKDIR/cebipdesc_$TodayDate.dmp.Z
rm -rf $BAKDIR/cebip_$TodayDate.tar.Z
#rm -rf $BAKDIR/rec_$TodayDate.tar.Z

