#!/usr/bin/ksh
#
# Purpose: This script is used for check AIX info
# 
# Update History:
#  Date       Modification
#  ---------- --------------------------------------------------------------------------------------
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
outfile=/tmp/aticheck/host/LINUX_${hostn}_${gen_date}.dat   
errfile=/tmp/aticheck/host/LINUX_ERR_${hostn}_${gen_date}.dat 

#### Command Definition ####
# This area define the command list with variable #
DMIDECODE=/usr/sbin/dmidecode
UNAME=/bin/uname
RUNLEVEL=/sbin/runlevel
DMESG=/bin/dmesg

LSPCI=/sbin/lspci
DF=/bin/df
UPTIME=/usr/bin/uptime

ULIMIT=ulimit
VMSTAT=/usr/bin/vmstat
IOSTAT=/usr/bin/iostat

TOP=/usr/bin/top
IFCONFIG=/sbin/ifconfig
NETSTAT=/bin/netstat

CRONTAB=/usr/bin/crontab
MPSTAT=/usr/bin/mpstat
FREE=/usr/bin/free
TAIL=/usr/bin/tail

TEST=/user/sbin/aaaa  


############################


#### Command List ####
# A step for merge those command into a variable #
# NOTE: ignore crontab as when there is no job for user, then the return code will also be 1.
CMDLIST="$DMIDECODE $UNAME $RUNLEVEL $DMESG $LSPCI $DF $UPTIME $ULIMIT $VMSTAT $IOSTAT $TOP $IFCONFIG $NETSTAT $MPSTAT $TAIL $TEST"

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
  if  echo $c | grep top  >/dev/null 2>&1
  then
    c=$c" -d 1 -n 1"
  elif  echo $c | grep crontab >/dev/null 2>&1
  then
    c=$c" -l"
  elif  echo $c | grep tail >/dev/null 2>&1
  then
    c="echo abc"$c
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
  echo "WARNING!!!!!!!!! "
  echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
  echo "Totally, there are $err_cmd_cnt commands error!"
  echo -e "Error cmd: $err_cmd" | tee cmd_err.log
  echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
  echo;
  echo "Do you want to break to check above WARNING? (You can have 10 seconds)"
  echo "If you want to BREAK, please use CTRL+C to BREAK this script!"
  sleep 10;
else
  echo;
  echo "Cool! Commands seems to work for you!" 
  echo "But crontab command has been ignore to check, as no job the return coe will be 1!" 
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

echo >> $outfile;
echo >> $outfile;
echo "#############################################################" >> $outfile
echo "######################### version ###########################" >> $outfile
echo "#############################################################" >> $outfile
echo "!!! Please also check the kernel version, as this file can be modified by other !!!" >> $outfile
ksh -c "cat /etc/redhat-release" >> $outfile


echo >> $outfile;
echo >> $outfile;
echo "#############################################################" >> $outfile
echo "################### Configuration files #####################" >> $outfile
echo "#############################################################" >> $outfile

echo "------inittab file ---------------" >> $outfile
ksh -c "cat /etc/inittab" >> $outfile   
echo  >> $outfile
echo  >> $outfile

echo "------hosts file ---------------" >> $outfile
ksh -c "cat /etc/hosts" >> $outfile             
echo  >> $outfile
echo  >> $outfile

echo "------oratab file ---------------" >> $outfile
ksh -c "cat /etc/oratab" >> $outfile  
echo  >> $outfile
echo  >> $outfile

echo "------sysctl file ---------------" >> $outfile
ksh -c "cat /etc/sysctl.conf" >> $outfile
echo  >> $outfile
echo  >> $outfile

echo "------limits.conf file ---------------" >> $outfile
ksh -c "cat /etc/security/limits.conf" >> $outfile
echo  >> $outfile
echo  >> $outfile


echo >> $outfile;
echo >> $outfile;
echo "#############################################################" >> $outfile
echo "########################## uptime ###########################" >> $outfile
echo "#############################################################" >> $outfile
ksh -c "$UPTIME" >> $outfile

echo >> $outfile;
echo >> $outfile;
echo "#############################################################" >> $outfile
echo "######################### cpu info  #########################" >> $outfile
echo "#############################################################" >> $outfile
ksh -c "cat /proc/cpuinfo" >> $outfile
ksh -c "$MPSTAT 1 3" >> $outfile	

echo >> $outfile;
echo >> $outfile;
echo "#############################################################" >> $outfile
echo "######################### mem info ##########################" >> $outfile
echo "#############################################################" >> $outfile
ksh -c "cat /proc/meminfo" >> $outfile
ksh -c "$FREE -m" >> $outfile

echo >> $outfile;
echo >> $outfile;
echo "#############################################################" >> $outfile
echo "######################### TOP info ##########################" >> $outfile
echo "#############################################################" >> $outfile
ksh -c "$TOP -d 1 -n 2 b" >> $outfile

echo >> $outfile;
echo >> $outfile;
echo "#############################################################" >> $outfile
echo "######################### vmstat 2 10 #######################" >> $outfile
echo "#############################################################" >> $outfile
ksh -c "$VMSTAT 2 10" >> $outfile

echo >> $outfile;
echo >> $outfile;
echo "#############################################################" >> $outfile
echo "######################### iostat 1 5 ########################" >> $outfile
echo "#############################################################" >> $outfile
ksh -c "$IOSTAT 1 5" >> $outfile                                           

echo >> $outfile;
echo >> $outfile;
echo "#############################################################" >> $outfile
echo "######################## netstat -in ########################" >> $outfile
echo "#############################################################" >> $outfile
ksh -c "$NETSTAT -in" >> $outfile

echo >> $outfile;
echo >> $outfile;
echo "#############################################################" >> $outfile
echo "######################## netstat -rn ########################" >> $outfile
echo "#############################################################" >> $outfile
ksh -c "$NETSTAT -rn" >> $outfile

echo >> $outfile;
echo >> $outfile;
echo "#############################################################" >> $outfile
echo "######################## File System ########################" >> $outfile
echo "#############################################################" >> $outfile
ksh -c "$DF -Th" >> $outfile

echo >> $outfile;
echo >> $outfile;
echo "#############################################################" >> $outfile
echo "######################## dmesg ##############################" >> $outfile
echo "#############################################################" >> $outfile
ksh -c "$DMESG | $TAIL -1000" >> $outfile

echo >> $outfile;
echo >> $outfile;
echo "#############################################################" >> $outfile
echo "######################## message log ########################" >> $outfile
echo "#############################################################" >> $outfile
echo "------messages file ---------------" >> $outfile
ksh -c "$TAIL -10000 /var/log/messages" >> $outfile 

echo;
echo "Finished LINUX Collection!"
echo;