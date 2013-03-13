#!/usr/bin/ksh
#
# Purpose: This script is used for check AIX info
# 
# Update History:
#  2013-03-07 Inital scripts(Flynt) 
#  2013-03-12 TOP command collection update.(Milo)
#             Modify code structure. (Milo)
#             Add command check function, popup if the command available for current user. (Milo)
#
#
#

#### Some Variables ####
hostn=`hostname`
gen_date=`date +%Y%m%d_%H%M%S`
outfile=/tmp/aticheck/host/AIX_${hostn}_${gen_date}.dat


#### Command Definition ####
# This area define the command list with variable #
OSLEVEL=/usr/bin/oslevel
UNAME=/usr/bin/uname
UPTIME=/usr/bin/uptime
IFCONFIG=/usr/sbin/ifconfig
NETSTAT=/usr/bin/netstat
VMSTAT=/usr/bin/vmstat
IOSTAT=/usr/bin/iostat
DF=/usr/bin/df
LSPV=/usr/sbin/lspv
LSVG=/usr/sbin/lsvg
LSPS=/usr/sbin/lsps
LSLPP=/usr/bin/lslpp
LSATTR=/usr/sbin/lsattr
ERRPT=/usr/bin/errpt
PRTCONF=/usr/sbin/prtconf
ULIMIT=/usr/bin/ulimit
BINDPROCESSOR=/usr/sbin/bindprocessor    
INSTFIX=/usr/sbin/instfix
TEST=/user/sbin/aaaa


############################


#### Command List ####
# A step for merge those command into a variable #
CMDLIST="$OSLEVEL $UNAME $UPTIME $IFCONFIG $NETSTAT $VMSTAT $IOSTAT $DF $LSPV $LSVG $LSPS $LSLPP $LSATTR $ERRPT $PRTCONF $ULIMIT $BINDPROCESSOR $INSTFIX $TEST"

##### Validate commands #####
echo;
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo ">>>>> 1. Validating the OS command..."
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo;

##### Error command count #####  
err_cmd_cnt=0 
err_cmd=""
  
##### For Special Case Command #####
for c in $CMDLIST
do
  if  echo $c | grep lsattr  >/dev/null 2>&1
  then
    c=$c" -El sys0"
  elif  echo $c | grep lslpp >/dev/null 2>&1
  then
    c=$c" -h"
  elif  echo $c | grep lsps >/dev/null 2>&1
  then
    c=$c" -s"
  elif  echo $c | grep ifconfig >/dev/null 2>&1
  then 
    c=$c" -a"
  elif  echo $c | grep bindprocessor >/dev/null 2>&1
  then 
    c=$c" -q"
  elif  echo $c | grep instfix >/dev/null 2>&1
  then 
    c=$c" -ia"  
  fi

#### Test if the command works ####
  $c > /dev/null 2>&1
  if [ `echo $?` -gt 0 ]
  then
    err_cmd_cnt=$((err_cmd_cnt+1))
    err_cmd=$err_cmd" \n $c"
  fi
done;
 
if [ $err_cmd_cnt -gt 0 ]
then
  echo;
  echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
  echo " WARNING!!!!!!!!! "
  echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
  echo "Totally, there are $err_cmd_cnt commands error!"
  echo "Error cmd: $err_cmd" | tee cmd_err.log
  echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
  echo;
  echo "Do you want to break to check above WARNING? (You can have 10 seconds)"
  echo "If you want to BREAK, please use CTRL+C to BREAK this script!"
  sleep 10;
else
  echo;
  echo "Cool! Commands seems to work for you!"  
  echo;
fi

##### Collect OS info #####
echo;
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo ">>>>> 2. Begin to collect OS info..."
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo; 

echo "#############################################################" >> $outfile
echo "########################## uname -a #########################" >> $outfile
echo "#############################################################" >> $outfile
ksh -c "$UNAME -a" >> $outfile
ksh -c "$OSLEVEL -s" >> $outfile

echo >> $outfile;  
echo >> $outfile;
echo "#############################################################" >> $outfile
echo "######################## uptime #############################" >> $outfile
echo "#############################################################" >> $outfile
ksh -c "$UPTIME" >> $outfile

echo >> $outfile;  
echo >> $outfile;
echo "#############################################################" >> $outfile
echo "######################## ifconfig ###########################" >> $outfile
echo "#############################################################" >> $outfile
ksh -c "$IFCONFIG -a" >> $outfile                                       

echo >> $outfile;  
echo >> $outfile;
echo "#############################################################" >> $outfile
echo "######################## netstat -in ########################" >> $outfile
echo "#############################################################" >> $outfile
ksh -c "$NETSTAT -in">>$outfile

echo >> $outfile;  
echo >> $outfile;
echo "#############################################################" >> $outfile
echo "######################## netstat -rn ########################" >> $outfile
echo "#############################################################" >> $outfile
ksh -c "$NETSTAT -rn" >> $outfile                                      

echo >> $outfile;  
echo >> $outfile;	
echo "#############################################################" >> $outfile
echo "######################### vmstat 2 10 #######################" >> $outfile
echo "#############################################################" >> $outfile
ksh -c "$VMSTAT 2 5" >> $outfile

echo >> $outfile;  
echo >> $outfile;
echo "#############################################################" >> $outfile
echo "######################### iostat 1 5 ########################" >> $outfile
echo "#############################################################" >> $outfile
ksh -c "$IOSTAT 1 5" >> $outfile                                          

echo >> $outfile;  
echo >> $outfile;
echo "#############################################################" >> $outfile
echo "######################## File System ########################" >> $outfile
echo "#############################################################" >> $outfile
ksh -c "$DF -g" >> $outfile

echo >> $outfile;  
echo >> $outfile;
echo "#############################################################" >> $outfile
echo "######################## LVM or ZFS #########################" >> $outfile
echo "#############################################################" >> $outfile
ksh -c "$LSPV" >> $outfile
echo >> $outfile;
ksh -c "$LSVG" >> $outfile
echo >> $outfile;
ksh -c "$LSVG -o" >> $outfile
echo >> $outfile;
ksh -c "$LSVG rootvg" >> $outfile
echo >> $outfile;
ksh -c "$LSVG -l rootvg" >> $outfile

echo >> $outfile;  
echo >> $outfile;
echo "#############################################################" >> $outfile
echo "####################### paging space ########################" >> $outfile
echo "#############################################################" >> $outfile
ksh -c "$LSPS -a" >> $outfile
echo >> $outfile;
ksh -c "$LSPS -s" >> $outfile

echo >>$outfile;  
echo >>$outfile;
echo "#############################################################" >> $outfile
echo "####################### LG CPU Info #########################" >> $outfile
echo "#############################################################" >> $outfile
ksh -c "$BINDPROCESSOR -q" >> $outfile

echo >> $outfile;  
echo >> $outfile;
echo "#############################################################" >> $outfile
echo "######################### unlimit ###########################" >> $outfile
echo "#############################################################" >> $outfile
ksh -c "$ULIMIT -a" >> $outfile

echo >> $outfile;  
echo >> $outfile;
echo "#############################################################" >> $outfile
echo "####################### Hardware Info #######################" >> $outfile
echo "#############################################################" >> $outfile
ksh -c "$PRTCONF" >> $outfile

echo >> $outfile;  
echo >> $outfile;
echo "#############################################################" >> $outfile
echo "####################### OS Package Info #####################" >> $outfile
echo "#############################################################" >> $outfile
ksh -c "$LSLPP -h" >> $outfile
echo >> $outfile;
echo >> $outfile;
ksh -c "$INSTFIX -ia" >> $outfile

echo >> $outfile;  
echo >> $outfile;  
echo "#############################################################" >> $outfile
echo "##################### System/Kernel Settings ################" >> $outfile
echo "#############################################################" >> $outfile
ksh -c "$LSATTR -El sys0">>$outfile 

echo >> $outfile;  
echo >> $outfile;	
echo "#############################################################" >> $outfile
echo "######################## errpt Info #########################" >> $outfile
echo "#############################################################" >> $outfile
ksh -c "$ERRPT -d H" >> $outfile	
echo >> $outfile;
echo >> $outfile;
ksh -c "$ERRPT -a" >> $outfile	
	
echo;
echo "Finishe AIX Collection!"
echo;