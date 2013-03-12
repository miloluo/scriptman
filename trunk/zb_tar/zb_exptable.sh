TodayDate=`date +'%u'`
ORACLE_HOME=/oracle/product/10.2.0;export ORACLE_HOME;
PATH=$PATH:$ORACLE_HOME/bin;export PATH;
ORACLE_SID=cebipzb;export ORACLE_SID;
#导出数据
exp pbcebdb/pbcebdb file=cebipzb_$TodayDate.dmp log=cebipzb_exp_$TodayDate.log tables='T_PB_LOG','T_EB_HISJOURNAL','T_EB_JOURNAL'
