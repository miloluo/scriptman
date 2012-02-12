-- ##################################################################################
-- Script Name: DG Physical Standby Check
-- ################################################################################## 
-- Purpose: This script is used to diagnose or check physical standby database in DG
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
spool dg_phystby__diag&&dbname&&timestamp&&suffix 
set lines 200 
set pagesize 35 
set trim on 
set trims on 
alter session set nls_date_format = 'MON-DD-YYYY HH24:MI:SS'; 
set feedback on 
select to_char(sysdate) time from dual; 
 
set echo on 
 
-- Check basic status of instance
---- column ARCHIVER: can be  (STOPPED | STARTED | FAILED) 
------ value "FAILED"  means archiver failed to archive a log last time
---- column LOG_SWITCH_WAIT: can be ARCHIVE LOG/CLEAR LOG/CHECKPOINT  
 
column host_name format a20 tru 
column version format a9 tru 
select instance_name,host_name,version,archiver,log_switch_wait from v$instance; 
 
-- Check how standby is setup.  
-- The role should be "PHYSICAL STANDBY"
 
column ROLE format a7 tru 
select name,platform_id,database_role role,log_mode,
       flashback_on flashback,protection_mode,protection_level  
from v$database;
 
-- Force logging is not mandatory but is recommended.     
-- During normal operations, column SWITCHOVER_STATUS can be "SESSIONS ACTIVE" or "NOT ALLOWED". 
 
column force_logging format a13 tru 
column remote_archive format a14 tru 
column dataguard_broker format a16 tru 
select force_logging,remote_archive,supplemental_log_data_pk,supplemental_log_data_ui, 
switchover_status,dataguard_broker from v$database;  
 
-- Check the archive_dest info
 
COLUMN destination FORMAT A35 WRAP 
column process format a7 
column archiver format a8 
column ID format 99 
 
select dest_id "ID",destination,status,target, 
archiver,schedule,process,mountid  
from v$archive_dest; 
 
-- Check each dest status and related process, if it's register on controlfile.  

select dest_id,process,transmit_mode,async_blocks, 
net_timeout,delay_mins,reopen_secs,register,binding 
from v$archive_dest; 
 
-- Check errors that occured in archive dest last time 
 
column error format a55 tru 
select dest_id,status,error from v$archive_dest; 
 
-- Check errors in dataguard view (view only available in 9.2.0 and above): 
 
column message format a80 
select message, timestamp 
from v$dataguard_status 
where severity in ('Error','Fatal') 
order by timestamp; 
 
-- Check status of the SRL's on the standby.  
-- SRL will present in standby if primary is archiving with LGWR process
---- One group# should be active
 
select group#,sequence#,bytes,used,archived,status from v$standby_log;

-- The above SRL size SHOULD = ORL size
-- The above SRL number SHOULD = (ORL in each thread# + 1) * (thread number) 
 
select group#,thread#,sequence#,bytes,archived,status from v$log; 

-- Check status of processes involved in the configuration.
 
select process,status,client_process,sequence#,block#,active_agents,known_agents
from v$managed_standby;

-- Check last sequence# received and the last sequence# applied to standby.

select al.thrd "Thread", almax "Last Seq Received", lhmax "Last Seq Applied"
from (select thread# thrd, max(sequence#) almax
      from v$archived_log
      where resetlogs_change#=(select resetlogs_change# from v$database)
      group by thread#) al,
     (select thread# thrd, max(sequence#) lhmax
      from v$log_history
      where first_time=(select max(first_time) from v$log_history)
      group by thread#) lh
where al.thrd = lh.thrd;

-- The view on a physical standby ONLY returns the next gap that is currently blocking redo apply. 
-- After resolving the gap and starting redo apply, query the view to check the next gap sequence.

select * from v$archive_gap; 

-- Non-default init parameters. 

set numwidth 5 
column name format a30 tru 
column value format a50 wra 
select name, value 
from v$parameter 
where isdefault = 'FALSE';
 
spool off