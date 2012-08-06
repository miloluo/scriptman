#!/bin/ksh
# File name: get_trc.sh
# Author: Milo Luo
# Date: Aug 14, 2011
# Update: Oct 19, 2011
# Purpose: This script is used to get the trc file in Alert log file and ftp to your server
# Usage: sh get_trc.sh <alert_log_location>
 
 
 
########### NEED TO MODIFY EVERY TIME ##############
CURRENT_YEAR='2011';
BEGIN_MONTH='nov';
FTP_SER='192.168.25.100';
#FTP_SER='130.89.200.16';
FTP_USER='test';
FTP_PASSWD='test';
####################################################
 
 
 
# Add more lines to fetched alert
OFFSET=10;
 
# Define the alert log location
ALERT_LOC=$1;
 
# Current month(used to generate the tar files name)
CURRENT_MONTH=`date +%Y%m`
 
## The log of runing this script:
TMP_RUNING_LOG="tmp_script_log_$(basename $ALERT_LOC .log).log"; 
echo $TMP_RUNING_LOG;
 
 
# The identifier used to split and get real trace files name
TRC_ID1=':'
TRC_ID2='\.trc'

## Dead lock hint
# This var TRC_ID3 will not use in this script, if you're not sure, pls do search in this script.
# TRC_ID3='.' 
 
 
## Time point match pattern
# style 1: Tue Dec 29 08:23:59 2009
# style 2: Mon Aug 01 05:40:38 BEIST 2011
MATCH_EXP1="[A-Z][a-z]{2} $BEGIN_MONTH {1,2}[0-9]{1,2} {1,2}[0-9]{2}:{1}[0-9]{2}:{1}[0-9]{2}.*$CURRENT_YEAR"
 
 
# Fetch specify alert log segment name
FETCH_LOG="tmp_fetch_$(basename $ALERT_LOC .log).log";
 
# Tared trace files name
TAR_FILE_NAME="trc_from_$(basename $ALERT_LOC .log)_${CURRENT_MONTH}.tar"
 
 
## Upload state: 
# 0 - (Default.All file will upload) Alert log, Fetchlog, trc files
# 1 - (No trc file) Alert log, Fetchlog
# 2 - (No specified log found) Alert log 
 
UP_STAT=0;
 
echo | tee -a $TMP_RUNING_LOG;
echo '****************************' | tee -a $TMP_RUNING_LOG;
echo `date` | tee -a $TMP_RUNING_LOG;
echo '****************************' | tee -a $TMP_RUNING_LOG;
echo | tee -a $TMP_RUNING_LOG;
echo '===>Start loging for this program...' | tee -a $TMP_RUNING_LOG;
echo | tee -a $TMP_RUNING_LOG;
 
# If the argument is not correct, then exit the script.
if [ $# -lt 1 ]
then
    echo '===> Argument failure!' | tee -a $TMP_RUNING_LOG;   
    echo "Missing the alert location!" | tee -a $TMP_RUNING_LOG;
    echo "Usage: sh get_trc.sh <alert_log_location>" | tee -a $TMP_RUNING_LOG ;
    exit -1;
 
fi;
 
 
######### Getting the fetched log and found trace files and tared if there is any  ###############

##### Writting the log
echo "===> Now fetching will start from ${CURRENT_YEAR}-${BEGIN_MONTH} !!!!" | tee -a $TMP_RUNING_LOG;

 
#### Writing the log
echo '===> Fetching begin line number' | tee -a $TMP_RUNING_LOG;
 
# Fetch the begin line number in alert
BEGIN_LINE_NUM=`grep -niE "$MATCH_EXP1" $ALERT_LOC 2> /dev/null  |awk -F: NR==1'{print $1}' 2> /dev/null`;
 
 
#### Writing the log
echo "begin line number: $BEGIN_LINE_NUM" | tee -a $TMP_RUNING_LOG;
echo | tee -a $TMP_RUNING_LOG;
 
 
# Judge if the BEGIN_LINE_NUM is null, if it's null, then not match result.
if [ ${BEGIN_LINE_NUM}abc = "abc" ]
then
    echo '===> No records in alert' | tee -a $TMP_RUNING_LOG;
    echo "No match result found in Alert file!" | tee -a $TMP_RUNING_LOG;
    echo "Only Alert file will upload!" | tee -a $TMP_RUNING_LOG;
    UP_STAT=2;
fi;
 
 
 
#### Writing the log
echo | tee -a $TMP_RUNING_LOG;
 
# Fetch the last line number of the alert log
END_LINE_NUM=`cat -n $ALERT_LOC | tail -n 1 | awk '{print $1}'`;
 

# Tar and zip the original log
#tar cvf ${ALERT_LOC}.tar $ALERT_LOC | tee -a $TMP_RUNING_LOG;
gzip -c ${ALERT_LOC} > ${ALERT_LOC}.gz | tee -a $TMP_RUNING_LOG;
 
#### Writing the log
echo '===> Fetching end line number' | tee -a $TMP_RUNING_LOG;
echo "end line number: $END_LINE_NUM" | tee -a $TMP_RUNING_LOG;
 
# Write the specified log to fetch log file and add 10 more lines before specified time:
tail -n $((${END_LINE_NUM} - ${BEGIN_LINE_NUM} + $OFFSET + 1)) $ALERT_LOC > $FETCH_LOG;
 
# If the current UP_STAT is 0, then filter the trace files in fetched log
if [ $UP_STAT -eq 0 ]
then
    # Writting the log
    echo | tee -a $TMP_RUNING_LOG;
    echo '===> Trace file number ' | tee -a $TMP_RUNING_LOG;
 
 
    # Calulate if there is any trace file in fetched log
    TRC_NUM=`cat $FETCH_LOG | grep $TRC_ID2 | awk '{print $NF}' | awk -F $TRC_ID1 '{print $1}' | sed -e 's/.trc./.trc/g' | sort -u | wc -l `
 
 
    # Writting the log
    echo "trace file number: $TRC_NUM" | tee -a $TMP_RUNING_LOG ; 
 
    # Check if there is trace files in fetched log
 
    if [ $TRC_NUM -eq 0 ]
    then
        # No trace file found in fetched log
		# Writting the log
        echo | tee -a $TMP_RUNING_LOG;
        echo '===> No trace file found in fetched log, please check !' | tee -a $TMP_RUNING_LOG;
 
        # Set upload flag to 1, only upload alert and fetched log
        UP_STAT=1;
  
    elif [ $TRC_NUM -gt 0 ]
    then
        # Found trace file in fetched log
		# Writting the log
        echo | tee -a $TMP_RUNING_LOG;
        echo '===> Found trace!' | tee -a $TMP_RUNING_LOG;   
 
        echo "Taring the trace file..." | tee -a $TMP_RUNING_LOG;
        # Tar the trace files  
        cat $FETCH_LOG | grep $TRC_ID2 | awk '{print $NF}' | awk -F $TRC_ID1 '{print $1}' | sed -e 's/.trc./.trc/g' | sort -u | xargs tar cvf $TAR_FILE_NAME | tee -a $TMP_RUNING_LOG;
        # Zip the tar files
        gzip -c $TAR_FILE_NAME > ${TAR_FILE_NAME}.gz | tee -a $TMP_RUNING_LOG;
    fi; 
 
fi;
 
 
######### Upload the files according to the flag UP_STAT ###############
# Writting the log
echo | tee -a $TMP_RUNING_LOG;
echo '===> FTP section ' | tee -a $TMP_RUNING_LOG;
echo " Uploading the files..." | tee -a $TMP_RUNING_LOG;
 
# Check what kind of files should be uploaded
 
# Upload all files
if [ $UP_STAT -eq 0 ]
then
 
ftp -i -n << EOF | tee -a $TMP_RUNING_LOG
open $FTP_SER
user $FTP_USER $FTP_PASSWD
bin
mput $FETCH_LOG
mput ${ALERT_LOC}.gz
mput ${TAR_FILE_NAME}.gz
bye
EOF
 
# Upload alert and fetched log
elif [ $UP_STAT -eq 1 ]
then
 
ftp -i -n << EOF | tee -a $TMP_RUNING_LOG
open $FTP_SER
user $FTP_USER $FTP_PASSWD
bin
mput $FETCH_LOG
mput ${ALERT_LOC}.gz
bye
EOF
 
# Upload alert
else
 
ftp -i -n << EOF | tee -a $TMP_RUNING_LOG
open $FTP_SER
user $FTP_USER $FTP_PASSWD
bin
mput ${ALERT_LOC}.gz
bye
 
EOF
 
fi;
 
# Writting the script log
echo | tee -a $TMP_RUNING_LOG;
echo "Done! " | tee -a $TMP_RUNING_LOG;
echo | tee -a $TMP_RUNING_LOG;
 
# Print the notice
echo ">>>>> Please do these:" | tee -a $TMP_RUNING_LOG;
echo ">> 1. Check if there is any error in the screen" | tee -a $TMP_RUNING_LOG; 
echo ">> 2. Check if there is 'permission denied', if so, please check if the original file is in the old dir." | tee -a $TMP_RUNING_LOG;
echo ">> 3. Check if there is 'no such file', if so, please if MANULLY UPLOAD these files and report to script owner." | tee -a $TMP_RUNING_LOG;
echo | tee -a $TMP_RUNING_LOG;
echo | tee -a $TMP_RUNING_LOG;
 
# Upload the script log
echo "Uploading the script log..." | tee -a $TMP_RUNING_LOG;
ftp -i -n << EOF 
open $FTP_SER
user $FTP_USER $FTP_PASSWD
bin
mput $TMP_RUNING_LOG
bye
 
EOF
 
 
# Remove the generate log
echo "Removing the generated logs..."
rm -f $TMP_RUNING_LOG ${TAR_FILE_NAME}.gz ${TAR_FILE_NAME} $FETCH_LOG ${ALERT_LOC}.gz