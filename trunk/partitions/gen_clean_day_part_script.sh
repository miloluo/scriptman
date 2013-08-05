#!/bin/bash
# 1. �ű�Ŀ��: �����ĳЩ��(���շ���,���ҷ�������������P20130520)��������, ���ǲ�������ĩ����!
#
# 2. �ű�״̬��Ϣ:
# ����           �汾      �޸���    �޸���Ϣ
# -----------    ------    -------   -----------------------------------------------------------------
# 2013.5.15      v0.1      Milo      ��ʼ���ű���
# 2013.5.20      v0.2      Milo      ��������ȫ�ֱ��������Ʊ�������û��������ݿ��ַ��������㣺
#                                         -1. tab_conn_str  ������ʱ���û�;
#                                         -2. ind_conn_str  �����ؽ�ʱ���û�;
#                                         -3. clr_tab_owner ������ӵ����;
#                                         -4. clr_tab_name  ����������;
#                                    ����Է�������ķ�ʽѡ��drop partition����truncate partition;
#                                    �������ֽű����ݲ��ֵ����;
#
#




################################
### ��һ����ѯ���Ƿ���б��� ###
################################


# ����
clear

##################������Ҫ�޸ĵı���#########################

### ע�⣺Ҫ����ķ�������밴�·��������ң����������������������ĸ�ʽ��P20120916�� ��������ű����ܻ�������⣡

# ���������������ַ���
tab_conn_str='sqlplus -S system/oracle '

# �����ؽ������������ַ���
ind_conn_str='sqlplus -S dmabdata/dmabdata@ora10g '

# ��������������
clr_tab_owner='DMABDATA'
clr_tab_name='BS_BA_DEP_PACCT_TD_AVG'

############################################################

# ����ýű���־
script_log=script_`date +%Y%m%d_%H%M%S`.log

echo "****************************" | tee -a $script_log;
echo "* ��һ����ȷ�ϱ����Ƿ���� *" | tee -a $script_log;
echo "****************************" | tee -a $script_log;

echo | tee -a $script_log;

while true;
do
read -p "��ȷ���ڶ�${clr_tab_owner}.${clr_tab_name}����ǰ����������Ӧ���ݣ���Y/N��"  Y_OR_N ;
Y_OR_N=`echo $Y_OR_N | tr [a-z] [A-Z]`
echo | tee -a $script_log;

if [ "$Y_OR_N" =  "Y" ] 
then

   echo "�û�ѡ��[Y]"  | tee -a $script_log;
   echo "�û�ȷ���ѱ��ݣ�����֮����..."  | tee -a $script_log;
   echo "���Ҫ�˳�����ctrl+c�˳���"| tee -a $script_log;
   break;

elif [  "$Y_OR_N" = "N"  ] 
then

   echo "�û�ѡ��[N]" | tee -a $script_log;
   echo "����ȷ�ϱ��ݺú��ٴ����нű����б�${clr_tab_owner}.${clr_tab_name}������" | tee -a $script_log;
   echo | tee -a $script_log;
   exit -1;

else 
   echo | tee -a $script_log;
   echo "����������������룡" | tee -a $script_log;
   echo | tee -a $script_log;
fi
done

echo | tee -a $script_log; echo | tee -a $script_log;echo | tee -a $script_log;








######################################
### �ڶ�����ѯ����Ҫ������·����� ###
######################################


echo "********************************" | tee -a $script_log;
echo "* �ڶ���������Ҫ�������ݵ��·� *" | tee -a $script_log;
echo "********************************" | tee -a $script_log;

echo | tee -a $script_log;
echo "ע�⣺Ҫ����ķ�������밴�·��������ң����������������������ĸ�ʽ��P20120916�� ��������ű����ܻ��������!" | tee -a $script_log;
echo | tee -a $script_log;


while true ;
do
read -p "������Ҫ������������·�(��ʽ: 2012-03): " clean_date 

if [[ "$clean_date" =~ "[1-9]{1}[0-9]{3}-[0-1]{1}[0-9]{1}" ]]
then
   echo "��������Ϊ��[$clean_date]" | tee -a $script_log 
   break;
else 
   echo | tee -a $script_log;
   echo "��������ڸ�ʽ����" | tee -a $script_log;
   echo | tee -a $script_log;
fi

done

echo | tee -a $script_log;echo | tee -a $script_log;echo | tee -a $script_log;






####################################
### ���������ж���������Ƿ���� ###
####################################

echo "********************************" | tee -a $script_log;
echo "* ���������ж���������Ƿ���� *" | tee -a $script_log;
echo "********************************" | tee -a $script_log;

echo | tee -a $script_log;

# ������Žű�Ŀ¼
script_loc=`pwd`/`echo $clean_date | sed s/-/_/g`
mkdir $script_loc 2> /dev/null
echo "����·��: $script_loc ." | tee -a $script_log 

# �����ܹ�Ҫ����ķ�����(ͨ�����һ������ -1��
$tab_conn_str << EOF > /dev/null
set lines 200
set echo on
alter session set nls_date_format='dd';
col CLEAN_PARTITION_COUNT new_value v_count
select last_day(to_date('$clean_date','yyyy-mm')) CLEAN_PARTITION_COUNT from dual;  
exit v_count
EOF

### ���ص������һ��
last_day="$?";

### ��������ķ�������
est_clear_part_cnt=`echo $last_day-1|bc`;

### ƴ�������·����ı��ʽ
match_str=P`echo $clean_date | sed s/-//g`%

### ƴ��������ĩ������(�÷��������������ڲ�ѯ���ų�)
# �����з�����ķ���������Ϊ: P20130501
end_part_name=P`echo ${clean_date}"-$last_day" | sed s/-//g`


# ����ʵ�ʲ�ѯ������ķ�����(ͨ����ѯdba_tab_partitions)
$tab_conn_str << EOF > /dev/null
set lines 200;
alter session set nls_date_format='yyyy-mm-dd';
col CNT new_value v_count;
select count(1) cnt from dba_tab_partitions
where table_owner='$clr_tab_owner' and table_name='$clr_tab_name' 
and  partition_name like '$match_str' and partition_name <> '$end_part_name';
exit v_count
EOF

### ʵ�ʲ�ѯ����������ķ�������
act_clear_part_cnt="$?";

# ���ɼ����������Ľű�
   echo "$tab_conn_str  << EOF
set lines 200;
alter session set nls_date_format='yyyy-mm-dd';
col table_owner for a20;
col table_name for a40;
col partition_name for a15;
col high_value for a40;
select table_owner, table_name, partition_name, high_value from dba_tab_partitions
where table_owner='$clr_tab_owner' and table_name='$clr_tab_name' 
and  partition_name like '$match_str' 
order by partition_name;
EOF" > ${script_loc}/ck_clr_tab.sh
sleep 5;

# �жϹ��Ʒ�������ʵ�ʿ�����������Ƿ�һ��
if [ $act_clear_part_cnt -ne $est_clear_part_cnt ]
then
   echo "Ԥ�������������ʵ�ʿ������������һ��!" | tee -a $script_log
   echo "Ԥ���������: $est_clear_part_cnt ����" | tee -a $script_log
   echo "ʵ�ʿ��������: $act_clear_part_cnt ����" | tee -a $script_log
   echo "----------------------------------------------------------------------------------------" | tee -a $script_log
   echo "| �����������ɵĽű�: $script_loc/ck_clr_tab.sh" | tee -a $script_log
   echo "| ���ʵ�ʷ��������"
   echo "----------------------------------------------------------------------------------------" | tee -a $script_log
   exit -111;
else
  echo "Ԥ�����������ʵ�ʿ��������һ��!" | tee -a $script_log;
  echo "�������������$act_clear_part_cnt ����" | tee -a $script_log;
  echo "��˶Զ�Ӧ��������ķ���������Ϣ, �Ա�ȷ��֮������û������!";
  
fi

   echo "----------------------------------------------------------------------------------------" | tee -a $script_log
   echo "| �����������ɵĽű�: $script_loc/ck_clr_tab.sh" | tee -a $script_log
   echo "| ����ǰ������ȷ�Ϸ�����Ϣ����ȷ��!"
   echo "----------------------------------------------------------------------------------------" | tee -a $script_log





echo | tee -a $script_log;echo | tee -a $script_log;echo | tee -a $script_log;




############################
### ���Ĳ�����������ű� ###
############################


echo "************************" | tee -a $script_log;
echo "* ���Ĳ�����������ű� *" | tee -a $script_log;
echo "************************" | tee -a $script_log;

echo | tee -a $script_log;

while true ;
do
# ��������ʽ
clean_oper='TRUNCATE'

# �û�ѡ������ʽ
echo "����������������ֲ���:" | tee -a $script_log ;
echo "1 -  ɾ������(drop partition)��    ���������� �Լ� �����Ķ��� ���� �� ����;" | tee -a $script_log ;
echo "2 -  �ضϷ���(truncate partition), ���������ݽ� �� �������� �����Ķ��� ����;" | tee -a $script_log ;
echo | tee -a $script_log;echo | tee -a $script_log;
read -p "������Ҫ�Է�������Ĳ�����Ӧ������: "  clr_opr ;


if [[ "$clr_opr" -eq 1 ]]
then
   echo "�û�ѡ������ʽΪ[1] -> DROP PARTITION." | tee -a $script_log 
   clr_opr=' DROP ';
   break;
elif [[ "$clr_opr" -eq 2 ]] 
then 
   echo "�û�ѡ������ʽΪ[2] -> TRUNCATE PARTITION." | tee -a $script_log 
   clr_opr=' TRUNCATE ';
   break;
else 
   echo | tee -a $script_log;
   echo "������������������" | tee -a $script_log;
   echo | tee -a $script_log;
fi
done


# ���ɵ�����ű�����
script_name="clean_tab_`date +%Y%m%d_%H%M%S`.sh"

# ��������ű���ͷ��
echo "# Script Name: $script_name" > ${script_loc}/$script_name
echo "# Purpose: clear ${clr_tab_owner}.${clr_tab_name} via script" >> ${script_loc}/$script_name
echo "$tab_conn_str << EOF >> ${script_loc}/tab_clr_`date +%Y%m%d_%H%M%S`.log" >> ${script_loc}/$script_name
echo "set lines 200" >> ${script_loc}/$script_name
echo "set timing on" >> ${script_loc}/$script_name
echo "set time on" >>   ${script_loc}/$script_name
echo >>   ${script_loc}/$script_name
echo >>   ${script_loc}/$script_name

# ����һ����ʱ��sql�ű�(����spool��ʽ�Ŀ���)
echo "alter session set nls_date_format='yyyy-mm-dd';" > ${script_loc}/tmp_gen.sql
echo "set heading off term off echo off pages 0 feedback off" >> ${script_loc}/tmp_gen.sql
echo "col table_owner for a20" >> ${script_loc}/tmp_gen.sql
echo "col table_name for a40"  >> ${script_loc}/tmp_gen.sql
echo "col partition_name for a15"  >> ${script_loc}/tmp_gen.sql
echo "col high_value for a40"  >> ${script_loc}/tmp_gen.sql
echo "spool ${script_loc}/$script_name append"  >> ${script_loc}/tmp_gen.sql
echo "select 'alter table ' || table_owner || '.'  || table_name || ' $clr_opr ' || ' partition ' || partition_name || ' ;' from dba_tab_partitions" >> ${script_loc}/tmp_gen.sql
echo "where table_owner='$clr_tab_owner' and table_name='$clr_tab_name'" >> ${script_loc}/tmp_gen.sql
echo "and  partition_name like '$match_str' and partition_name <> '$end_part_name'" >> ${script_loc}/tmp_gen.sql
echo "order by partition_name;" >> ${script_loc}/tmp_gen.sql
echo "spool off; " >> ${script_loc}/tmp_gen.sql

$tab_conn_str << EOF > /dev/null
@${script_loc}/tmp_gen.sql
EOF

# ���ɽű��Ľ�β
echo >> ${script_loc}/$script_name
echo "EOF" >> ${script_loc}/$script_name
echo | tee -a $script_log;echo | tee -a $script_log;

echo "----------------------------------------------------------------------------------------------------------------" | tee -a $script_log
echo "| ���ɽű�: ${script_loc}/$script_name " | tee -a $script_log
echo "| �ű�������ϣ�����ű��������Ƿ���ȷ!" | tee -a $script_log
echo "----------------------------------------------------------------------------------------------------------------" | tee -a $script_log

sleep 2;

echo | tee -a $script_log;echo | tee -a $script_log;echo | tee -a $script_log;





################################
### ���岽�������ؽ������ű� ###
################################


echo "****************************" | tee -a $script_log;
echo "* ���岽�������ؽ������ű� *" | tee -a $script_log;
echo "****************************" | tee -a $script_log;

# �ؽ�ȫ�������Ľű�����
ind_rebuild_script="rebuild_ind_`date +%Y%m%d_%H%M%S`.sh"

# �����ؽ��ű���ͷ��
echo "# Script Name: $ind_rebuild_script " > ${script_loc}/$ind_rebuild_script
echo "# Purpose: rebuild ${clr_tab_owner}.${clr_tab_name} indexes via script" >> ${script_loc}/$ind_rebuild_script
echo >> ${script_loc}/$ind_rebuild_script
echo "$ind_conn_str << EOF > ${script_loc}/ind_rebuild_`date +%Y%m%d_%H%M%S`.log" >> ${script_loc}/$ind_rebuild_script
echo "set lines 200" >> ${script_loc}/$ind_rebuild_script
echo "set timing on" >> ${script_loc}/$ind_rebuild_script
echo "set time on" >> ${script_loc}/$ind_rebuild_script

# �����ؽ�global(ȫ��) indexes�Ľű�
echo "alter session set nls_date_format='yyyy-mm-dd';" > ${script_loc}/tmp_gen_ind1.sql
echo "set heading off term off echo off pages 0 feedback off" >> ${script_loc}/tmp_gen_ind1.sql
echo "col table_owner for a20" >> ${script_loc}/tmp_gen_ind1.sql
echo "col table_name for a40"  >> ${script_loc}/tmp_gen_ind1.sql
echo "col partition_name for a15"  >> ${script_loc}/tmp_gen_ind1.sql
echo "col high_value for a40"  >> ${script_loc}/tmp_gen_ind1.sql
echo "spool ${script_loc}/$ind_rebuild_script append"  >> ${script_loc}/tmp_gen_ind1.sql
echo "select 'alter index ' || owner || '.' ||  index_name || ' rebuild nologging parallel 16 ;' from dba_indexes" >> ${script_loc}/tmp_gen_ind1.sql
echo "where table_owner='$clr_tab_owner' and table_name='$clr_tab_name' and partitioned='NO' ; " >> ${script_loc}/tmp_gen_ind1.sql
echo "spool off; " >> ${script_loc}/tmp_gen_ind1.sql

$tab_conn_str << EOF > /dev/null
@${script_loc}/tmp_gen_ind1.sql
EOF

# �����ؽ�ȫ�������ű���β
echo  >> ${script_loc}/$ind_rebuild_script
echo "EOF" >> ${script_loc}/$ind_rebuild_script

echo | tee -a $script_log;
echo "-----------------------------------------------------------------------------------------" | tee -a $script_log
echo "| �ؽ������Ľű�Ϊ: $script_loc/$ind_rebuild_script " | tee -a $script_log
echo "| �ű�������ϣ�����ű��в��ж�(parallel)�Ƿ�������������������Ӧ����!" | tee -a $script_log
echo "| �����Ҫ����������з��������������������Ϻ����ؽ�����!!"  | tee -a $script_log
echo "-----------------------------------------------------------------------------------------" | tee -a $script_log
echo | tee -a $script_log;