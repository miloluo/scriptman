-- ##################################################################################
-- Script Name: DG - Primary databse Check
-- ################################################################################## 
-- Purpose: This script is used to diagnose or check Priamry Database in DG
-- Maintainers: Jet, Milo
-- Version change and reason:
---- v0.1   Script initial (Jet, Milo)
---- v0.1.1 Added the script header and modify need manually part (Milo)
----        modify nls_date_format=english to avoid spool file issue (Milo) 

-- ##################################################################################



-- ################################################################################## 
----------- Part 1: Need manually ------------
-- ################################################################################## 

--#1. awr or statspack
--#--statspack report
--#SQL> execute statspack.snap;
--#SQL> @ ?/rdbms/admin/spreport.sql

--#SQL> exec dbms_workload_repository.create_snapshot();
--#SQL> @ ?/rdbms/admin/awrrpt.sql


--#2. Check datafile type
--#SELECT name
--#FROM   v$datafile;  

--#ls -lrt <datafile_dir>

--#3. Log check:
--#tail alert.log
--#tail listener.log


-- ##################################################################################
--------------Part 2: Sql Query -----------------
-- ##################################################################################

-- Generate a spool file name

set echo off 
set feedback off 
alter session set nls_date_language=english;
column timecol new_value timestamp 
column spool_extension new_value suffix 
select to_char(sysdate,'Mondd_hhmi') timecol, 
'.out' spool_extension from sys.dual; 
column output new_value dbname 
select value || '_' output 
from v$parameter where name = 'db_name'; 
spool DG_Prim_&&dbname&&timestamp&&suffix 

set linesize 79
set pagesize 180
set long 1000
set trim on 
set trims on 
alter session set nls_date_format = 'MM/DD HH24:MI:SS'; 
set feedback on 
select to_char(sysdate) time from dual; 
 
set echo on 

-------------------------------

-- If protection_level is different than protection_mode
-- then for some reason the mode listed in
-- protection_mode experienced a need to downgrade.

column role format a7 tru 
column name format a10 wrap

select name,platform_id,database_role role,log_mode,
       flashback_on flashback,protection_mode,protection_level  
from v$database;


-- ARCHIVER can be (STOPPED | STARTED | FAILED). 
---- FAILED: the archiver failed to archive a log last time, but will try again within 5 mins.
-- LOG_SWITCH_WAIT The ARCHIVE LOG/CLEAR LOG/CHECKPOINT event log switching is waiting for.
-- Note that if ALTER SYSTEM SWITCH LOGFILE is hung,
-- but there is room in the current online redo log, then value is NULL

column host_name format a20 tru 
column version format a9 tru 

select instance_name,host_name,version,archiver,log_switch_wait 
from v$instance; 


-- Catpatch information
---- Check if the procedure doesn't match the image.

select version, modified, status from dba_registry 
where comp_id = 'CATPROC';


-- Force logging is not mandatory but is recommended.  
-- Supplemental logging must be enabled in logical DG. 
-- SWITCHOVER_STATUS to be SESSIONS ACTIVE or TO STANDBY.

column force_logging format a13 tru 
column remote_archive format a14 tru 
column dataguard_broker format a16 tru 

select force_logging,remote_archive,
       supplemental_log_data_pk,supplemental_log_data_ui, 
       switchover_status,dataguard_broker 
from v$database;  
 

-- Check all archive destinations. 
---- Shows enabled dest
---- Show what process is servicing that destination
---- Show the destination is local or remote
---- If remote, show that current mount ID.

column destination format a35 wrap 
column process format a7 
column archiver format a8 
column ID format 99 
column mid format 99
 
select dest_id "ID",destination,status,target,
       schedule,process,mountid  mid
from v$archive_dest order by dest_id;


-- Check further detail on the destinations
---- Register indicates whether or not the archived
---- redo log is registered in the remote destination control file.

set numwidth 8
column ID format 99 

select dest_id "ID",archiver,transmit_mode,affirm,async_blocks async,
       net_timeout net_time,delay_mins delay,reopen_secs reopen,
       register,binding 
from v$archive_dest order by dest_id;
 

-- Show errors occured the last time when an attempt to archive to the destination.
---- error column is blank means good.
 
column error format a55 wrap

select dest_id,status,error from v$archive_dest; 
 

-- Determine if any error conditions have been reached
---- view only available in 9.2.0 and above

column message format a80 

select message, timestamp 
from v$dataguard_status 
where severity in ('Error','Fatal') 
order by timestamp; 


-- Show the current sequence number and the last sequence archived. 
---- remotely archiving using LGWR: archived sequence > current sequence. 
---- remotely archiving using ARCH: archived sequence = current sequence.


select ads.dest_id,max(sequence#) "Current Sequence",
           max(log_sequence) "Last Archived"
   from v$archived_log al, v$archive_dest ad, v$archive_dest_status ads
   where ad.dest_id=al.dest_id
   and al.dest_id=ads.dest_id
   and al.resetlogs_change#=(select max(resetlogs_change#) from v$archived_log )
   group by ads.dest_id;
 

-- Gather as much information as possible from the standby.
---- SRLs are not supported with Logical Standby until Version 10.1.

set numwidth 8
column ID format 99 
column "SRLs" format 99 
column Active format 99 

select dest_id id,database_mode db_mode,recovery_mode, 
       protection_mode,standby_logfile_count "SRLs",
       standby_logfile_active ACTIVE, 
       archived_seq# 
from v$archive_dest_status; 


-- Show status of processes involved while shipping redo
---- Does not include processes needed to apply redo.

select process,status,client_process,sequence#
from v$managed_standby;


-- Check standby redo log

select group#,sequence#,bytes from v$standby_log; 


-- Check redo log size
-- makesure: redo log size = standby redo log size

select group#,thread#,sequence#,bytes,archived,status from v$log; 


-- Non-default init parameters. 

set numwidth 5 
column name format a30 tru 
column value format a48 wra 
select name, value 
from v$parameter 
where isdefault = 'FALSE';


spool off
exit;


