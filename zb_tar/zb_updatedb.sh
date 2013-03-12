TodayDate=`date +'%u'`
ORACLE_HOME=/oracle/product/10.2.0;export ORACLE_HOME;
PATH=$PATH:$ORACLE_HOME/bin;export PATH;
#TodayDate=`date +'%u'`
ORACLE_SID=cebipzb;export ORACLE_SID;
PBUSERNAME=pbcebdb;export PBUSERNAME;
PBPASSWD=pbcebdb;export PBPASSWD;

#更新数据库

#导入表结构
imp $PBUSERNAME/$PBPASSWD file=cebipdesc_$TodayDate.dmp  fromuser=pbcebdb touser=$PBUSERNAME  INDEXE S=n CONSTRAINTS=n log=/zbbak/cebip/log/cebipdesc_imp1_$TodayDate.log
#导入数据
imp $PBUSERNAME/$PBPASSWD file=cebip_$TodayDate.dmp  fromuser=pbcebdb touser=$PBUSERNAME  ignore=y  log=/zbbak/cebip/log/cebip_imp_$TodayDate.log
#导入表结构带约束
imp $PBUSERNAME/$PBPASSWD file=cebipdesc_$TodayDate.dmp  fromuser=pbcebdb touser=$PBUSERNAME ignore=
y log=/zbbak/cebip/log/cebipdesc_imp1_$TodayDate.log
#更新sequence
sqlplus pbcebdb/pbcebdb <<!
drop sequence PBJOURNO;
@seq_$TodayDate.sql;
exit
!
