#!/bin/bash
# 1. 脚本目的: 清除表某些表(按日分区,并且分区的名字类似P20130520)的月数据, 但是不清理月末数据!
#
# 2. 脚本状态信息:
# 日期           版本      修改人    修改信息
# -----------    ------    -------   -----------------------------------------------------------------
# 2013.5.15      v0.1      Milo      初始化脚本。
# 2013.5.20      v0.2      Milo      加入如下全局变量，控制表清理和用户连接数据库字符串更方便：
#                                         -1. tab_conn_str  表清理时的用户;
#                                         -2. ind_conn_str  索引重建时的用户;
#                                         -3. clr_tab_owner 清理表的拥有者;
#                                         -4. clr_tab_name  清理表的名字;
#                                    加入对分区处理的方式选择，drop partition还是truncate partition;
#                                    高亮部分脚本数据部分的输出;
#
#




################################
### 第一步：询问是否进行备份 ###
################################


# 清屏
clear

##################可能需要修改的变量#########################

### 注意：要清理的分区表必须按月分区，并且，分区名字是以类似这样的格式：P20120916， 否则清理脚本可能会出现问题！

# 定义清理表的连接字符串
tab_conn_str='sqlplus -S system/oracle '

# 定义重建索引的连接字符串
ind_conn_str='sqlplus -S dmabdata/dmabdata@ora10g '

# 定义清理表的名字
clr_tab_owner='DMABDATA'
clr_tab_name='BS_BA_DEP_PACCT_TD_AVG'

############################################################

# 定义该脚本日志
script_log=script_`date +%Y%m%d_%H%M%S`.log

echo "****************************" | tee -a $script_log;
echo "* 第一步：确认备份是否进行 *" | tee -a $script_log;
echo "****************************" | tee -a $script_log;

echo | tee -a $script_log;

while true;
do
read -p "请确认在对${clr_tab_owner}.${clr_tab_name}清理前，已做好相应备份！（Y/N）"  Y_OR_N ;
Y_OR_N=`echo $Y_OR_N | tr [a-z] [A-Z]`
echo | tee -a $script_log;

if [ "$Y_OR_N" =  "Y" ] 
then

   echo "用户选择[Y]"  | tee -a $script_log;
   echo "用户确认已备份，进行之后步骤..."  | tee -a $script_log;
   echo "如果要退出，请ctrl+c退出！"| tee -a $script_log;
   break;

elif [  "$Y_OR_N" = "N"  ] 
then

   echo "用户选择[N]" | tee -a $script_log;
   echo "请在确认备份好后，再次运行脚本进行表${clr_tab_owner}.${clr_tab_name}的清理！" | tee -a $script_log;
   echo | tee -a $script_log;
   exit -1;

else 
   echo | tee -a $script_log;
   echo "输入错误，请重新输入！" | tee -a $script_log;
   echo | tee -a $script_log;
fi
done

echo | tee -a $script_log; echo | tee -a $script_log;echo | tee -a $script_log;








######################################
### 第二步：询问需要清理的月份数据 ###
######################################


echo "********************************" | tee -a $script_log;
echo "* 第二步：输入要清理数据的月份 *" | tee -a $script_log;
echo "********************************" | tee -a $script_log;

echo | tee -a $script_log;
echo "注意：要清理的分区表必须按月分区，并且，分区名字是以类似这样的格式：P20120916， 否则清理脚本可能会出现问题!" | tee -a $script_log;
echo | tee -a $script_log;


while true ;
do
read -p "请输入要做数据清理的月份(格式: 2012-03): " clean_date 

if [[ "$clean_date" =~ "[1-9]{1}[0-9]{3}-[0-1]{1}[0-9]{1}" ]]
then
   echo "输入日期为：[$clean_date]" | tee -a $script_log 
   break;
else 
   echo | tee -a $script_log;
   echo "输入的日期格式有误！" | tee -a $script_log;
   echo | tee -a $script_log;
fi

done

echo | tee -a $script_log;echo | tee -a $script_log;echo | tee -a $script_log;






####################################
### 第三步：判断清理分区是否存在 ###
####################################

echo "********************************" | tee -a $script_log;
echo "* 第三步：判断清理分区是否存在 *" | tee -a $script_log;
echo "********************************" | tee -a $script_log;

echo | tee -a $script_log;

# 创建存放脚本目录
script_loc=`pwd`/`echo $clean_date | sed s/-/_/g`
mkdir $script_loc 2> /dev/null
echo "创建路径: $script_loc ." | tee -a $script_log 

# 计算总共要清理的分区数(通过最后一天数字 -1）
$tab_conn_str << EOF > /dev/null
set lines 200
set echo on
alter session set nls_date_format='dd';
col CLEAN_PARTITION_COUNT new_value v_count
select last_day(to_date('$clean_date','yyyy-mm')) CLEAN_PARTITION_COUNT from dual;  
exit v_count
EOF

### 返回当月最后一天
last_day="$?";

### 估算清理的分区数量
est_clear_part_cnt=`echo $last_day-1|bc`;

### 拼接清理当月分区的表达式
match_str=P`echo $clean_date | sed s/-//g`%

### 拼接清理月末分区名(该分区不做清理，将在查询中排除)
# 此例中分区表的分区名类似为: P20130501
end_part_name=P`echo ${clean_date}"-$last_day" | sed s/-//g`


# 计算实际查询可清理的分区数(通过查询dba_tab_partitions)
$tab_conn_str << EOF > /dev/null
set lines 200;
alter session set nls_date_format='yyyy-mm-dd';
col CNT new_value v_count;
select count(1) cnt from dba_tab_partitions
where table_owner='$clr_tab_owner' and table_name='$clr_tab_name' 
and  partition_name like '$match_str' and partition_name <> '$end_part_name';
exit v_count
EOF

### 实际查询出可以清理的分区个数
act_clear_part_cnt="$?";

# 生成检查清理分区的脚本
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

# 判断估计分区数和实际可清理分区数是否一致
if [ $act_clear_part_cnt -ne $est_clear_part_cnt ]
then
   echo "预计清理分区数与实际可清理分区数不一致!" | tee -a $script_log
   echo "预计清理分区: $est_clear_part_cnt 个。" | tee -a $script_log
   echo "实际可清理分区: $act_clear_part_cnt 个。" | tee -a $script_log
   echo "----------------------------------------------------------------------------------------" | tee -a $script_log
   echo "| 请运行新生成的脚本: $script_loc/ck_clr_tab.sh" | tee -a $script_log
   echo "| 检查实际分区情况！"
   echo "----------------------------------------------------------------------------------------" | tee -a $script_log
   exit -111;
else
  echo "预计清理分区与实际可清理分区一致!" | tee -a $script_log;
  echo "可清理分区数：$act_clear_part_cnt 个。" | tee -a $script_log;
  echo "请核对对应清理分区的分区分区信息, 以便确认之后清理没有问题!";
  
fi

   echo "----------------------------------------------------------------------------------------" | tee -a $script_log
   echo "| 请运行新生成的脚本: $script_loc/ck_clr_tab.sh" | tee -a $script_log
   echo "| 清理前请首先确认分区信息的正确性!"
   echo "----------------------------------------------------------------------------------------" | tee -a $script_log





echo | tee -a $script_log;echo | tee -a $script_log;echo | tee -a $script_log;




############################
### 第四步：生成清理脚本 ###
############################


echo "************************" | tee -a $script_log;
echo "* 第四步：生成清理脚本 *" | tee -a $script_log;
echo "************************" | tee -a $script_log;

echo | tee -a $script_log;

while true ;
do
# 定义清理方式
clean_oper='TRUNCATE'

# 用户选择清理方式
echo "清理分区可以有两种操作:" | tee -a $script_log ;
echo "1 -  删除分区(drop partition)，    分区的数据 以及 分区的定义 都将 被 清理;" | tee -a $script_log ;
echo "2 -  截断分区(truncate partition), 分区的数据将 被 清理，但是 分区的定义 保留;" | tee -a $script_log ;
echo | tee -a $script_log;echo | tee -a $script_log;
read -p "请输入要对分区清理的操作对应的数字: "  clr_opr ;


if [[ "$clr_opr" -eq 1 ]]
then
   echo "用户选择清理方式为[1] -> DROP PARTITION." | tee -a $script_log 
   clr_opr=' DROP ';
   break;
elif [[ "$clr_opr" -eq 2 ]] 
then 
   echo "用户选择清理方式为[2] -> TRUNCATE PARTITION." | tee -a $script_log 
   clr_opr=' TRUNCATE ';
   break;
else 
   echo | tee -a $script_log;
   echo "输入有误！请重新输入" | tee -a $script_log;
   echo | tee -a $script_log;
fi
done


# 生成的清理脚本名字
script_name="clean_tab_`date +%Y%m%d_%H%M%S`.sh"

# 生成清理脚本的头部
echo "# Script Name: $script_name" > ${script_loc}/$script_name
echo "# Purpose: clear ${clr_tab_owner}.${clr_tab_name} via script" >> ${script_loc}/$script_name
echo "$tab_conn_str << EOF >> ${script_loc}/tab_clr_`date +%Y%m%d_%H%M%S`.log" >> ${script_loc}/$script_name
echo "set lines 200" >> ${script_loc}/$script_name
echo "set timing on" >> ${script_loc}/$script_name
echo "set time on" >>   ${script_loc}/$script_name
echo >>   ${script_loc}/$script_name
echo >>   ${script_loc}/$script_name

# 生成一个临时的sql脚本(处于spool格式的考虑)
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

# 生成脚本的结尾
echo >> ${script_loc}/$script_name
echo "EOF" >> ${script_loc}/$script_name
echo | tee -a $script_log;echo | tee -a $script_log;

echo "----------------------------------------------------------------------------------------------------------------" | tee -a $script_log
echo "| 生成脚本: ${script_loc}/$script_name " | tee -a $script_log
echo "| 脚本生成完毕，请检查脚本中内容是否正确!" | tee -a $script_log
echo "----------------------------------------------------------------------------------------------------------------" | tee -a $script_log

sleep 2;

echo | tee -a $script_log;echo | tee -a $script_log;echo | tee -a $script_log;





################################
### 第五步：生成重建索引脚本 ###
################################


echo "****************************" | tee -a $script_log;
echo "* 第五步：生成重建索引脚本 *" | tee -a $script_log;
echo "****************************" | tee -a $script_log;

# 重建全局索引的脚本名字
ind_rebuild_script="rebuild_ind_`date +%Y%m%d_%H%M%S`.sh"

# 生成重建脚本的头部
echo "# Script Name: $ind_rebuild_script " > ${script_loc}/$ind_rebuild_script
echo "# Purpose: rebuild ${clr_tab_owner}.${clr_tab_name} indexes via script" >> ${script_loc}/$ind_rebuild_script
echo >> ${script_loc}/$ind_rebuild_script
echo "$ind_conn_str << EOF > ${script_loc}/ind_rebuild_`date +%Y%m%d_%H%M%S`.log" >> ${script_loc}/$ind_rebuild_script
echo "set lines 200" >> ${script_loc}/$ind_rebuild_script
echo "set timing on" >> ${script_loc}/$ind_rebuild_script
echo "set time on" >> ${script_loc}/$ind_rebuild_script

# 生成重建global(全局) indexes的脚本
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

# 生成重建全局索引脚本结尾
echo  >> ${script_loc}/$ind_rebuild_script
echo "EOF" >> ${script_loc}/$ind_rebuild_script

echo | tee -a $script_log;
echo "-----------------------------------------------------------------------------------------" | tee -a $script_log
echo "| 重建索引的脚本为: $script_loc/$ind_rebuild_script " | tee -a $script_log
echo "| 脚本生成完毕，请检查脚本中并行度(parallel)是否合适如果不合适请做相应调整!" | tee -a $script_log
echo "| 如果需要连续清理表中分区，请把所有清理工作完毕后，再重建索引!!"  | tee -a $script_log
echo "-----------------------------------------------------------------------------------------" | tee -a $script_log
echo | tee -a $script_log;