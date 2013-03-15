#!/usr/bin/ksh
#
# Purpose: This script is used for check AIX info
# 
# Update History:
#  Date       Modification
#  ---------- --------------------------------------------------------------------------------------
#  2013-03-07 Inital scripts(Flynt) 
#  2013-03-12 Change code structure(Milo)
#             Multiple Instance Identify Procedure(Milo)
#             
#
#
#



echo;
echo;
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo ">>>>> 3. Begin to collect DB info..."
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo;
echo;


#### Some Variables ####
hostn=`hostname`                                       
gen_date=`date +%Y%m%d_%H%M%S`    

### This varialbe is suffix of the spoolf variable                     
outfile=/tmp/aticheck/db/DB_${hostn}_${gen_date}

### The owner or starter of the instance
owner_list=`ps -ef | grep smon | grep -v grep | awk '{print $1}'`

### The owner count
owner_cnt=`ps -ef | grep smon | grep -v grep | awk '{print $1}' | sort -u |wc -l`

### The sid list 
sid_list=`ps -ef | grep smon | grep -v grep | awk '{print $8}' | awk -F "_" '{print $3}'`

### The owner count
sid_cnt=`ps -ef | grep smon | grep -v grep | wc -l`

### Define Return code
# -61 The current user is not the instance owner
# -62 Instance not reachalbe 



echo "Starting Oracle Database Collection..."
echo;


## Judge the instance owner's count
# If there is only one user
if [ $owner_cnt -eq 1 ]
then   


    ## Judge if the instance owner is the current user
    if [ "abc$owner_list" = "abc`whoami`" ]
    then
    
        # Execute the script with sid one by one
        for i in $sid_list
        do          
   
### Set spool file name and every loop will reset this variable
spoolf=$outfile   
   
### !!! DO NOT CHANGE BELOW LINES FORMAT, BECAUSE THEY MIGHT AFFECT THE EXECUTION!!!!!    
export ORACLE_SID=$i;

sqlplus / as sysdba << EOF
set heading off;
spool tmp_inst_stat.out
select instance_name, status from v\$instance;
spool off
EOF
  
            ### IF THE DB IS OPEN, THEN execute the script
            if  grep -E "^${i}\ *OPEN" tmp_inst_stat.out 
            then
  
            ### Reformat outfile's name  
            spoolf=${spoolf}"_$i".out  
            
            ### Get the info via  oracle_check script   
sqlplus / as sysdba << EOF 
spool $spoolf
@oracle_check.sql
spool off
EOF
             
            #### IF THE DB DOES NOT OPEN, THEN , ERROR POPUP!!!! 
            else
              echo -e "ERROR! INSTANCE  NOT REACHABLE!!!\nPLEASE CHECK THE INSTANCE STATUS!!!"
              exit 62;
            fi
 
            #### clean out the tmp file  
            rm tmp_inst_stat.out 
   
        done;    
       
    else
        echo "The current user is not the instance owner!!!";
        exit 61;
    fi   
############ END only one owner ##############    
    
    
    

## If there is more than one owner
elif [ $owner_cnt -gt 1 ]
then
    echo "There are at $owner_cnt owner of instances, so another instances started by other user might need to manually execute or switch user!";
    ## Judge if the instance owner is the current user
    if [ "abc$owner_list" = "abc`whoami`" ]
    then
    
        # Execute the script with sid one by one
        for i in $sid_list
        do
export ORACLE_SID=$i;
sqlplus / as sysdba @oracle_check.sql
        done; 
    
    else
       echo "The current user is not the instance owner!!!";
       exit 61;
    fi  
############ END more than one owner ##############   
   
   
## If there is no owner or instance is not running  
elif [ $owner_cnt -eq 0 ]
then
    echo "No instance running now!"
  
## If there is a exception  
else 
    echo "Exception ocurred! owner count is $owner_cnt !!!"
fi



##sqlplus / as sysdba @Automatic_Generate_AWR.sql
###mv *awr.html /tmp/aticheck/database
echo "Oracle database Collection completed! The Collected result saved in $outfile ."
echo 
