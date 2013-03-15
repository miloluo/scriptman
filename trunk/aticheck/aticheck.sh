#!/usr/bin/ksh
# 
# Description: This script used to check(auto) the linux/unix/hpux operating system and Oracle database.
# Version 0.2
# Update History:
#  Date       Modification
#  ---------- --------------------------------------------------------------------------------------
#  2013-03-07 Inital scripts(Flynt) with v0.1
#  2013-03-14 Change the code structure(Milo) with v0.2
#
#




#-- ##################################################################################
#--------------Part 1: Check directory -----------------
#-- ##################################################################################

checkdir(){
        if [ ! -d "/tmp/aticheck/db/" ]; then
                mkdir -p /tmp/aticheck/db/
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
	sh aix.sh
}

hpux(){
	checkdir
  sh hpux.sh
}

linux(){
	checkdir
  sh linux.sh
}                


#-- ##################################################################################
#--------------Part 3: Procedure of Oracle database(basic info,awr) -----------------
#-- ##################################################################################       
           
db(){
  checkdir
  sh db.sh
  }

#-- ##################################################################################
#----------------------Part 4: package output files ----------------------------------
#-- ##################################################################################
# package the output files and get the trc file in Alert log file and ftp to your server

end(){
hostn=`hostname`
tar -cvf /home/oracle/${hostn}_aticheck.tar /tmp/aticheck/
#rm -rf /tmp/aticheck
}


#-- ##################################################################################
#-------------Part 5: main code for choice procedure to check the OS ---------------
#-- ##################################################################################

# OS Judge Procedure
ostype=`uname`

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
                  echo "Unsupported operating systems!"
                  exit 1
                  ;;
esac

