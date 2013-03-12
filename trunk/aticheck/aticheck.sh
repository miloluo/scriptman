#!/usr/bin/ksh
#
# 
#
# Version    : 0.1
# Description: This script used to check(auto) the linux/unix/hpunix operating system and Oracle database.
#
#
#
#-- ##################################################################################
#--------------Part 1: Check directory -----------------
#-- ##################################################################################
checkdir(){
        if [ ! -d "/tmp/aticheck/database/" ]; then
                mkdir -p /tmp/aticheck/database/
        fi
        if [ ! -d "/tmp/aticheck/host/" ]; then
                mkdir -p /tmp/aticheck/host/
        fi
}

#-- ##################################################################################
#--------------Part 2: three Procedures for the operating system -----------------
#-- ##################################################################################
aix(){
	checkdir
	hostn=`hostname`
	hour=`date +'%m.%d.%y.%H-%M.dat'`
	echo "`date` check...">/tmp/aticheck/host/${hostn}_$hour
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
}

hpux(){
	checkdir
	hostn=`hostname`
	hour=`date +'%m.%d.%y.%H-%M.dat'`
	echo "#############################################################">>/tmp/aticheck/host/${hostn}_$hour
	echo "####################### Hardware Info #######################">>/tmp/aticheck/host/${hostn}_$hour
	echo "#############################################################">>/tmp/aticheck/host/${hostn}_$hour
	ksh -c "machinfo">>/tmp/aticheck/host/${hostn}_$hour

	echo "`date` check...">/tmp/aticheck/host/${hostn}_$hour
	echo "#############################################################">>/tmp/aticheck/host/${hostn}_$hour
	echo "########################## uname -a #########################">>/tmp/aticheck/host/${hostn}_$hour
	echo "#############################################################">>/tmp/aticheck/host/${hostn}_$hour
	ksh -c "uname -a">>/tmp/aticheck/host/${hostn}_$hour
		
	echo "#############################################################">>/tmp/aticheck/host/${hostn}_$hour
	echo "####################### UPTIME Info #########################">>/tmp/aticheck/host/${hostn}_$hour
	echo "#############################################################">>/tmp/aticheck/host/${hostn}_$hour
	ksh -c "uptime">>/tmp/aticheck/host/${hostn}_$hour

	echo "#############################################################">>/tmp/aticheck/host/${hostn}_$hour
	echo "####################### TOP Info ############################">>/tmp/aticheck/host/${hostn}_$hour
	echo "#############################################################">>/tmp/aticheck/host/${hostn}_$hour
	ksh -c "/usr/bin/top -s 1 -d 1 -n 40">>/tmp/aticheck/host/${hostn}_$hour
		
	echo "#############################################################">>/tmp/aticheck/host/${hostn}_$hour
	echo "####################### limit Info ##########################">>/tmp/aticheck/host/${hostn}_$hour
	echo "#############################################################">>/tmp/aticheck/host/${hostn}_$hour
	ksh -c "ulimit -a">>/tmp/aticheck/host/${hostn}_$hour
	
	echo "#############################################################">>/tmp/aticheck/host/${hostn}_$hour
	echo "######################### vmstat 2 10 ########################">>/tmp/aticheck/host/${hostn}_$hour
	echo "#############################################################">>/tmp/aticheck/host/${hostn}_$hour
	ksh -c "vmstat 2 5">>/tmp/aticheck/host/${hostn}_$hour

	echo "#############################################################">>/tmp/aticheck/host/${hostn}_$hour
	echo "######################### iostat 2 10 ########################">>/tmp/aticheck/host/${hostn}_$hour
	echo "#############################################################">>/tmp/aticheck/host/${hostn}_$hour
	ksh -c "iostat 2 5">>/tmp/aticheck/host/${hostn}_$hour

	echo "#############################################################">>/tmp/aticheck/host/${hostn}_$hour
	echo "######################## Network info #######################">>/tmp/aticheck/host/${hostn}_$hour
	echo "#############################################################">>/tmp/aticheck/host/${hostn}_$hour
	ksh -c "/usr/sbin/lanscan -i | cut -d" " -f1 | xargs -n1 /usr/sbin/ifconfig">>/tmp/aticheck/host/${hostn}_$hour

	echo "#############################################################">>/tmp/aticheck/host/${hostn}_$hour
	echo "######################## netstat -in ########################">>/tmp/aticheck/host/${hostn}_$hour
	echo "#############################################################">>/tmp/aticheck/host/${hostn}_$hour
	ksh -c "netstat -in">>/tmp/aticheck/host/${hostn}_$hour
		
	echo "#############################################################">>/tmp/aticheck/host/${hostn}_$hour
	echo "######################## netstat -rn ########################">>/tmp/aticheck/host/${hostn}_$hour
	echo "#############################################################">>/tmp/aticheck/host/${hostn}_$hour
	ksh -c "netstat -rn">>/tmp/aticheck/host/${hostn}_$hour

	echo "#############################################################">>/tmp/aticheck/host/${hostn}_$hour
	echo "######################## File System ########################">>/tmp/aticheck/host/${hostn}_$hour
	echo "#############################################################">>/tmp/aticheck/host/${hostn}_$hour
	ksh -c "bdf">>/tmp/aticheck/host/${hostn}_$hour

	echo "#############################################################">>/tmp/aticheck/host/${hostn}_$hour
	echo "########################  Swap Info  ########################">>/tmp/aticheck/host/${hostn}_$hour
	echo "#############################################################">>/tmp/aticheck/host/${hostn}_$hour
	ksh -c "/usr/sbin/swapinfo -tm">>/tmp/aticheck/host/${hostn}_$hour

	echo "#############################################################">>/tmp/aticheck/host/${hostn}_$hour
	echo "########################  VG Info  ##########################">>/tmp/aticheck/host/${hostn}_$hour
	echo "#############################################################">>/tmp/aticheck/host/${hostn}_$hour
	ksh -c "/usr/sbin/vgdisplay">>/tmp/aticheck/host/${hostn}_$hour

	echo "#############################################################">>/tmp/aticheck/host/${hostn}_$hour
	echo "######################## CPU INFO ###########################">>/tmp/aticheck/host/${hostn}_$hour
	echo "#############################################################">>/tmp/aticheck/host/${hostn}_$hour
	ksh -c "/usr/sbin/ioscan -fnkC processor">>/tmp/aticheck/host/${hostn}_$hour
	
	echo "#############################################################">>/tmp/aticheck/host/${hostn}_$hour
	echo "######################## Porfile INFO ###########################">>/tmp/aticheck/host/${hostn}_$hour
	echo "#############################################################">>/tmp/aticheck/host/${hostn}_$hour
	ksh -c "cat /etc/hosts">>/tmp/aticheck/host/${hostn}_$hour
		
  echo "#############################################################">>/tmp/aticheck/host/${hostn}_$hour
	echo "####################### OS Patches INFO #####################">>/tmp/aticheck/host/${hostn}_$hour
	echo "#############################################################">>/tmp/aticheck/host/${hostn}_$hour
	ksh -c "/usr/contrib/bin/show_patches">>/tmp/aticheck/host/${hostn}_$hour
	
  echo "#############################################################">>/tmp/aticheck/host/${hostn}_$hour
	echo "####################### GET syslog ##########################">>/tmp/aticheck/host/${hostn}_$hour
	echo "#############################################################">>/tmp/aticheck/host/${hostn}_$hour
	ksh -c "tail -1000 /var/adm/syslog/syslog.log">>/tmp/aticheck/host/${hostn}_$hour	
	echo "HP-UX Checked!"
}


linux(){
	checkdir
	hostn=`hostname`
	hour=`date +'%m.%d.%y.%H-%M.dat'`
	echo "`date` check...">/tmp/aticheck/host/${hostn}_$hour
	echo "#############################################################">>/tmp/aticheck/host/${hostn}_$hour
	echo "########################## uname -a #########################">>/tmp/aticheck/host/${hostn}_$hour
	echo "#############################################################">>/tmp/aticheck/host/${hostn}_$hour
	ksh -c "uname -a">>/tmp/aticheck/host/${hostn}_$hour

	echo "#############################################################">>/tmp/aticheck/host/${hostn}_$hour
	echo "######################### version ###########################">>/tmp/aticheck/host/${hostn}_$hour
	echo "#############################################################">>/tmp/aticheck/host/${hostn}_$hour
	ksh -c "cat /etc/redhat-release">>/tmp/aticheck/host/${hostn}_$hour
	
	echo "#############################################################">>/tmp/aticheck/host/${hostn}_$hour
	echo "########################## uptime ###########################">>/tmp/aticheck/host/${hostn}_$hour
	echo "#############################################################">>/tmp/aticheck/host/${hostn}_$hour
	ksh -c "uptime">>/tmp/aticheck/host/${hostn}_$hour
	
	echo "#############################################################">>/tmp/aticheck/host/${hostn}_$hour
	echo "######################### cpu info  #########################">>/tmp/aticheck/host/${hostn}_$hour
	echo "#############################################################">>/tmp/aticheck/host/${hostn}_$hour
	ksh -c "cat /proc/cpuinfo">>/tmp/aticheck/host/${hostn}_$hour
	ksh -c "mpstat 1 3">>/tmp/aticheck/host/${hostn}_$hour	
	
	echo "#############################################################">>/tmp/aticheck/host/${hostn}_$hour
	echo "######################### mem info ##########################">>/tmp/aticheck/host/${hostn}_$hour
	echo "#############################################################">>/tmp/aticheck/host/${hostn}_$hour
	ksh -c "cat /proc/meminfo">>/tmp/aticheck/host/${hostn}_$hour
  ksh -c "free -m">>/tmp/aticheck/host/${hostn}_$hour

	echo "#############################################################">>/tmp/aticheck/host/${hostn}_$hour
	echo "######################### TOP info ##########################">>/tmp/aticheck/host/${hostn}_$hour
	echo "#############################################################">>/tmp/aticheck/host/${hostn}_$hour
	ksh -c "/usr/bin/top -d 1 -n 2 b">>/tmp/aticheck/host/${hostn}_$hour
	
	echo "#############################################################">>/tmp/aticheck/host/${hostn}_$hour
	echo "######################### vmstat 2 10 ########################">>/tmp/aticheck/host/${hostn}_$hour
	echo "#############################################################">>/tmp/aticheck/host/${hostn}_$hour
	ksh -c "vmstat 2 5">>/tmp/aticheck/host/${hostn}_$hour

	echo "#############################################################">>/tmp/aticheck/host/${hostn}_$hour
	echo "######################### iostat 1 5 ########################">>/tmp/aticheck/host/${hostn}_$hour
	echo "#############################################################">>/tmp/aticheck/host/${hostn}_$hour
	ksh -c "iostat 1 5">>/tmp/aticheck/host/${hostn}_$hour

	echo "#############################################################">>/tmp/aticheck/host/${hostn}_$hour
	echo "######################## netstat -rn ########################">>/tmp/aticheck/host/${hostn}_$hour
	echo "#############################################################">>/tmp/aticheck/host/${hostn}_$hour
	ksh -c "netstat -rn">>/tmp/aticheck/host/${hostn}_$hour
	
	echo "#############################################################">>/tmp/aticheck/host/${hostn}_$hour
	echo "######################## netstat -rn ########################">>/tmp/aticheck/host/${hostn}_$hour
	echo "#############################################################">>/tmp/aticheck/host/${hostn}_$hour
	ksh -c "netstat -rn">>/tmp/aticheck/host/${hostn}_$hour

	echo "#############################################################">>/tmp/aticheck/host/${hostn}_$hour
	echo "######################## File System ########################">>/tmp/aticheck/host/${hostn}_$hour
	echo "#############################################################">>/tmp/aticheck/host/${hostn}_$hour
	ksh -c "df -Th">>/tmp/aticheck/host/${hostn}_$hour
	
	echo "#############################################################">>/tmp/aticheck/host/${hostn}_$hour
	echo "######################## dmesg ##############################">>/tmp/aticheck/host/${hostn}_$hour
	echo "#############################################################">>/tmp/aticheck/host/${hostn}_$hour
	ksh -c "dmesg |tail -1000">>/tmp/aticheck/host/${hostn}_$hour
	echo "Linux Checked!"
}                


#-- ##################################################################################
#--------------Part 3: Procedure of Oracle database(basic info,awr) -----------------
#-- ##################################################################################                  
db(){
  checkdir
        echo "Starting Oracle Database Collection..."
        echo ""
        hostn=`hostname`
        hour=`date +'%m.%d.%y.%H-%M.dat'`
        echo "`date` check...">/tmp/aticheck/database/${hostn}_$hour
        sqlplus / as sysdba @oracle_check.sql >/tmp/aticheck/database/${hostn}_$hour
        sqlplus / as sysdba @Automatic_Generate_AWR.sql
        mv *awr.html /tmp/aticheck/database
  echo "Oracle database Collection completed.The Collected result saved in /tmp/aticheck/database/${hostn}_$hour."
  echo ""
  }

#-- ##################################################################################
#----------------------Part 4: package output files ----------------------------------
#-- ##################################################################################
# package the output files and get the trc file in Alert log file and ftp to your server
end(){
hostn=`hostname`
tar -cvf /home/oracle/${hostn}_aticheck.tar /tmp/aticheck/
rm -rf /tmp/aticheck
}


#-- ##################################################################################
#-------------Part 5: main code for choice procedure to check the OS ---------------
#-- ##################################################################################
#selection condition		            
ostype=`uname`
# choice procedure
case $ostype in
             Linux)
                  linux
                  db
                  end
                  exit 0
                  ;;
             AIX)
                  aix
                  db
                  end
                  exit 0
                  ;;
             HP-UX)
                  hp
                  db
                  exit 0
                  ;;
             *)
                  echo "Unsupported operating systems"
                  exit 1
                  ;;
esac

