TodayDate=`date +'%u'`
#�������ݿ�
##��ɾ��ɾ�����ݿ���û�����
#ORACLE_SID=cebipdb;export ORACLE_SID;
#��������
imp pbcebdb/pbcebdb file=cebipzb_$TodayDate.dmp fromuser=pbcebdb touser=pbcebdb  ignore=y log=$HOME/log/cebip_imp_$TodayDate.log
