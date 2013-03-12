#!/usr/bin/ksh
#
# Purpose: This script is used for check HPUX info
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
outfile=AIX_${hostn}_${gen_date}.dat


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


############################


#### Command List ####
# A step for merge those command into a variable #
CMDLIST="$OSLEVEL $UNAME $UPTIME $IFCONFIG $NETSTAT $VMSTAT $IOSTAT $DF $LSPV $LSVG $LSPS $LSLPP $LSATTR $ERRPT $PRTCONF $ULIMIT $BINDPROCESSOR"

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
  fi

#### Test if the command works ####
  $c > /dev/null 2>&1
  if [ `echo $?` -gt 0 ]
  then
    err_cmd_cnt=$err_cmd_cnt+1
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
fi

##### Collect OS info #####
echo;
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo ">>>>> 2. Begin to collect OS info..."
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo; 

	echo "#############################################################">>/tmp/aticheck/host/${hostn}_$hour
	echo "########################## uname -a #########################">>/tmp/aticheck/host/${hostn}_$hour
	echo "#############################################################">>/tmp/aticheck/host/${hostn}_$hour
	ksh -c "uname -a">>/tmp/aticheck/host/${hostn}_$hour
	ksh -c "oslevel -s">>/tmp/aticheck/host/${hostn}_$hour

	echo "#############################################################">>/tmp/aticheck/host/${hostn}_$hour
	echo "######################## uptime ###########################">>/tmp/aticheck/host/${hostn}_$hour
	echo "#############################################################">>/tmp/aticheck/host/${hostn}_$hour
	ksh -c "uptime">>/tmp/aticheck/host/${hostn}_$hour

	echo "#############################################################">>/tmp/aticheck/host/${hostn}_$hour
	echo "######################## ifconfig ###########################">>/tmp/aticheck/host/${hostn}_$hour
	echo "#############################################################">>/tmp/aticheck/host/${hostn}_$hour
	ksh -c "ifconfig -a">>/tmp/aticheck/host/${hostn}_$hour

	echo "#############################################################">>/tmp/aticheck/host/${hostn}_$hour
	echo "######################## netstat -in ########################">>/tmp/aticheck/host/${hostn}_$hour
	echo "#############################################################">>/tmp/aticheck/host/${hostn}_$hour
	ksh -c "netstat -in">>/tmp/aticheck/host/${hostn}_$hour

	echo "#############################################################">>/tmp/aticheck/host/${hostn}_$hour
	echo "######################## netstat -rn ########################">>/tmp/aticheck/host/${hostn}_$hour
	echo "#############################################################">>/tmp/aticheck/host/${hostn}_$hour
	ksh -c "netstat -rn">>/tmp/aticheck/host/${hostn}_$hour
		
	echo "#############################################################">>/tmp/aticheck/host/${hostn}_$hour
	echo "######################### vmstat 2 10 ########################">>/tmp/aticheck/host/${hostn}_$hour
	echo "#############################################################">>/tmp/aticheck/host/${hostn}_$hour
	ksh -c "vmstat 2 5">>/tmp/aticheck/host/${hostn}_$hour

	echo "#############################################################">>/tmp/aticheck/host/${hostn}_$hour
	echo "######################### iostat 1 5 ########################">>/tmp/aticheck/host/${hostn}_$hour
	echo "#############################################################">>/tmp/aticheck/host/${hostn}_$hour
	ksh -c "iostat 1 5">>/tmp/aticheck/host/${hostn}_$hour

	echo "#############################################################">>/tmp/aticheck/host/${hostn}_$hour
	echo "######################## File System ########################">>/tmp/aticheck/host/${hostn}_$hour
	echo "#############################################################">>/tmp/aticheck/host/${hostn}_$hour
	ksh -c "df -g">>/tmp/aticheck/host/${hostn}_$hour

	echo "#############################################################">>/tmp/aticheck/host/${hostn}_$hour
	echo "######################## LVM or ZFS #########################">>/tmp/aticheck/host/${hostn}_$hour
	echo "#############################################################">>/tmp/aticheck/host/${hostn}_$hour
	ksh -c "lspv">>/tmp/aticheck/host/${hostn}_$hour
	ksh -c "lsvg">>/tmp/aticheck/host/${hostn}_$hour
	ksh -c "lsvg -o">>/tmp/aticheck/host/${hostn}_$hour
	ksh -c "lsvg rootvg">>/tmp/aticheck/host/${hostn}_$hour
	ksh -c "lsvg -l rootvg">>/tmp/aticheck/host/${hostn}_$hour
	
	echo "#############################################################">>/tmp/aticheck/host/${hostn}_$hour
	echo "####################### paging space ########################">>/tmp/aticheck/host/${hostn}_$hour
	echo "#############################################################">>/tmp/aticheck/host/${hostn}_$hour
	ksh -c "lsps -a">>/tmp/aticheck/host/${hostn}_$hour
	ksh -c "lsps -s">>/tmp/aticheck/host/${hostn}_$hour
	
	echo "#############################################################">>/tmp/aticheck/host/${hostn}_$hour
	echo "####################### LG CPU Info #######################">>/tmp/aticheck/host/${hostn}_$hour
	echo "#############################################################">>/tmp/aticheck/host/${hostn}_$hour
	ksh -c "bindprocessor -q">>/tmp/aticheck/host/${hostn}_$hour

	echo "#############################################################">>/tmp/aticheck/host/${hostn}_$hour
	echo "######################### unlimit ###########################">>/tmp/aticheck/host/${hostn}_$hour
	echo "#############################################################">>/tmp/aticheck/host/${hostn}_$hour
	ksh -c "ulimit -a">>/tmp/aticheck/host/${hostn}_$hour
	
	echo "#############################################################">>/tmp/aticheck/host/${hostn}_$hour
	echo "####################### Hardware Info #######################">>/tmp/aticheck/host/${hostn}_$hour
	echo "#############################################################">>/tmp/aticheck/host/${hostn}_$hour
	ksh -c "prtconf">>/tmp/aticheck/host/${hostn}_$hour
	
	echo "#############################################################">>/tmp/aticheck/host/${hostn}_$hour
	echo "####################### OS Package Info #####################">>/tmp/aticheck/host/${hostn}_$hour
	echo "#############################################################">>/tmp/aticheck/host/${hostn}_$hour
	ksh -c "lslpp -h">>/tmp/aticheck/host/${hostn}_$hour
  ksh -c "/usr/sbin/instfix -ia">>/tmp/aticheck/host/${hostn}_$hour
    
	echo "#############################################################">>/tmp/aticheck/host/${hostn}_$hour
	echo "##################### System/Kernel Settings ################">>/tmp/aticheck/host/${hostn}_$hour
	echo "#############################################################">>/tmp/aticheck/host/${hostn}_$hour
	ksh -c "/usr/sbin/lsattr -El sys0">>/tmp/aticheck/host/${hostn}_$hour 
  
	echo "#############################################################">>/tmp/aticheck/host/${hostn}_$hour
	echo "######################## errpt Info #########################">>/tmp/aticheck/host/${hostn}_$hour
	echo "#############################################################">>/tmp/aticheck/host/${hostn}_$hour
	ksh -c "errpt -d H">>/tmp/aticheck/host/${hostn}_$hour	
	ksh -c "errpt -a">>/tmp/aticheck/host/${hostn}_$hour	
	echo "AIX Checked!"