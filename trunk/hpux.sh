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
outfile=HPUX_${hostn}_${gen_date}.dat


#### Command Definition ####
# This area define the command list with variable #
MACHINFO=/usr/contrib/bin/machinfo
UNAME=/usr/bin/uname
UPTIME=/usr/bin/uptime
TOP=/usr/bin/top
ULIMIT=/usr/bin/ulimit
VMSTAT=/usr/bin/vmstat
IOSTAT=/usr/bin/iostat

LANSCAN=/usr/sbin/lanscan
NETSTAT=/usr/bin/netstat
BDF=/usr/bin/bdf
SWAPINFO=/usr/sbin/swapinfo
VGDISPLAY=/usr/sbin/vgdisplay
IOSCAN=/usr/sbin/ioscan
SHOW_PATCHES=/usr/contrib/bin/show_patches
IFCONFIG=/usr/sbin/ifconfig
############################

#### Command List ####
# A step for merge those command into a variable #
CMDLIST="$MACHINFO $UNAME $UPTIME $TOP $ULIMIT $VMSTAT $IOSTAT $LANSCAN $BDF $SWAPINFO $VGDISPLAY $IOSCAN $SHOW_PATCHES $IFCONFIG"

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
    c=$c" -d 1"
  elif  echo $c | grep iostat >/dev/null 2>&1
  then
    c=$c" 1 1"
  elif  echo $c | grep ioscan >/dev/null 2>&1
  then
    c=$c" -fnk"
  elif  echo $c | grep ifconfig >/dev/null 2>&1
  then 
    c=$c" lo0"
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
echo "#############################################################">>/tmp/aticheck/host/$outfile
echo "####################### Hardware Info #######################">>/tmp/aticheck/host/$outfile
echo "#############################################################">>/tmp/aticheck/host/$outfile
ksh -c "$MACHINFO" >> /tmp/aticheck/host/$outfile

######echo "`date` check...">/tmp/aticheck/host/${hostn}_$file_id
echo "#############################################################">>/tmp/aticheck/host/$outfile
echo "########################## uname -a #########################">>/tmp/aticheck/host/$outfile
echo "#############################################################">>/tmp/aticheck/host/$outfile
ksh -c "$UNAME -a" >> /tmp/aticheck/host/$outfile
	
echo "#############################################################">>/tmp/aticheck/host/$outfile
echo "####################### UPTIME Info #########################">>/tmp/aticheck/host/$outfile
echo "#############################################################">>/tmp/aticheck/host/$outfile
ksh -c "$UPTIME" >> /tmp/aticheck/host/$outfile

echo "#############################################################">>/tmp/aticheck/host/$outfile
echo "####################### TOP Info ############################">>/tmp/aticheck/host/$outfile
echo "#############################################################">>/tmp/aticheck/host/$outfile
ksh -c "$TOP -s 1 -d 1 -n 40 -f /tmp/aticheck/host/$outfile"
	
echo "#############################################################">>/tmp/aticheck/host/$outfile
echo "####################### limit Info ##########################">>/tmp/aticheck/host/$outfile
echo "#############################################################">>/tmp/aticheck/host/$outfile
ksh -c "$ULIMIT -a" >> /tmp/aticheck/host/$outfile

echo "#############################################################">>/tmp/aticheck/host/$outfile
echo "######################### vmstat 2 10 #######################">>/tmp/aticheck/host/$outfile
echo "#############################################################">>/tmp/aticheck/host/$outfile
ksh -c "$VMSTAT 2 5" >> /tmp/aticheck/host/$outfile

echo "#############################################################">>/tmp/aticheck/host/$outfile
echo "######################### iostat 2 10 #######################">>/tmp/aticheck/host/$outfile
echo "#############################################################">>/tmp/aticheck/host/$outfile
ksh -c "$IOSTAT 2 5" >> /tmp/aticheck/host/$outfile

echo "#############################################################">>/tmp/aticheck/host/$outfile
echo "######################## Network info #######################">>/tmp/aticheck/host/$outfile
echo "#############################################################">>/tmp/aticheck/host/$outfile
ksh -c "$LANSCAN -i | cut -d\" \" -f1 | xargs -n1 $IFCONFIG" >> /tmp/aticheck/host/$outfile

echo "#############################################################">>/tmp/aticheck/host/$outfile
echo "######################## netstat -in ########################">>/tmp/aticheck/host/$outfile
echo "#############################################################">>/tmp/aticheck/host/$outfile
ksh -c "$NETSTAT -in" >> /tmp/aticheck/host/$outfile
	
echo "#############################################################">>/tmp/aticheck/host/$outfile
echo "######################## netstat -rn ########################">>/tmp/aticheck/host/$outfile
echo "#############################################################">>/tmp/aticheck/host/$outfile
ksh -c "$NETSTAT -rn" >> /tmp/aticheck/host/$outfile

echo "#############################################################">>/tmp/aticheck/host/$outfile
echo "######################## File System ########################">>/tmp/aticheck/host/$outfile
echo "#############################################################">>/tmp/aticheck/host/$outfile
ksh -c "$BDF" >> /tmp/aticheck/host/$outfile

echo "#############################################################">>/tmp/aticheck/host/$outfile
echo "########################  Swap Info  ########################">>/tmp/aticheck/host/$outfile
echo "#############################################################">>/tmp/aticheck/host/$outfile
ksh -c "$SWAPINFO -tm" >> /tmp/aticheck/host/$outfile

echo "#############################################################">>/tmp/aticheck/host/$outfile
echo "########################  VG Info  ##########################">>/tmp/aticheck/host/$outfile
echo "#############################################################">>/tmp/aticheck/host/$outfile
ksh -c "$VGDISPLAY" >> /tmp/aticheck/host/$outfile

echo "#############################################################">>/tmp/aticheck/host/$outfile
echo "######################## CPU INFO ###########################">>/tmp/aticheck/host/$outfile
echo "#############################################################">>/tmp/aticheck/host/$outfile
ksh -c "$IOSCAN -fnkC processor" >> /tmp/aticheck/host/$outfile

echo "#############################################################">>/tmp/aticheck/host/$outfile
echo "####################### OS Patches INFO #####################">>/tmp/aticheck/host/$outfile
echo "#############################################################">>/tmp/aticheck/host/$outfile
ksh -c "$SHOW_PATCHES" >> /tmp/aticheck/host/$outfile

echo "#############################################################">>/tmp/aticheck/host/$outfile
echo "######################## Porfile INFO #######################">>/tmp/aticheck/host/$outfile
echo "#############################################################">>/tmp/aticheck/host/$outfile
ksh -c "cat /etc/hosts" >> /tmp/aticheck/host/$outfile
	
echo "#############################################################">>/tmp/aticheck/host/$outfile
echo "####################### GET syslog ##########################">>/tmp/aticheck/host/$outfile
echo "#############################################################">>/tmp/aticheck/host/$outfile
ksh -c "tail -1000 /var/adm/syslog/syslog.log" >> /tmp/aticheck/host/$outfile
echo "Finished HPUX Collection!"

