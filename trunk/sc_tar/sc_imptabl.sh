TodayDate=`date +'%u'`
#更新数据库
##不删除删除数据库该用户数据
#ORACLE_SID=cebipdb;export ORACLE_SID;
#导入数据
imp pbcebdb/pbcebdb file=cebipzb_$TodayDate.dmp fromuser=pbcebdb touser=pbcebdb  ignore=y log=$HOME/log/cebip_imp_$TodayDate.log
