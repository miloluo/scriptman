-- ##################################################################################
-- Script Name: DG Logical standby Check
-- ################################################################################## 
-- Purpose: This script is used to diagnose or check logical standby database in DG
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
spool dg_lstby_diag_&&dbname&&timestamp&&suffix 

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

-- The generic information about how this standby is setup.
---- Database_role should be logical standby.

column ROLE format a7 tru 
column NAME format a8 wrap
select name,platform_id,database_role role,log_mode,
       flashback_on flashback,protection_mode,protection_level  
from v$database;


-- Check basic status of instance
---- column ARCHIVER: can be  (STOPPED | STARTED | FAILED) 
------ value "FAILED"  means archiver failed to archive a log last time
---- column LOG_SWITCH_WAIT: can be ARCHIVE LOG/CLEAR LOG/CHECKPOINT  

column host_name format a20 tru 
column version format a9 tru 
select instance_name,host_name,version,archiver,log_switch_wait 
from v$instance; 

-- Check catproc component.
-- This way we can tell if the procedure doesn't match the image.

select version, modified, status from dba_registry 
where comp_id = 'CATPROC';
 

-- Supplemental logging should be enabled in logical standby
-- During normal operations, SWITCHOVER_STATUS can be SESSIONS ACTIVE or NOT ALLOWED. 
-- Check if broker is enabled

column force_logging format a13 tru 
column remote_archive format a14 tru 
column dataguard_broker format a16 tru 

select force_logging,remote_archive,supplemental_log_data_pk,
supplemental_log_data_ui,switchover_status,dataguard_broker 
from v$database;  
 
 
-- Check archive destinations if the dest is local or remote and mount ID

column destination format a35 wrap 
column process format a7 
column archiver format a8 
column ID format 99 
column mid format 99
 
select dest_id "ID",destination,status,target,
       schedule,process,mountid  mid
from v$archive_dest order by dest_id;
 

-- Check all dest's options.
-- Column Register show if archived redo log is register in remote controlfile 

set numwidth 8
column ID format 99 

select dest_id "ID",archiver,transmit_mode,affirm,async_blocks async,
       net_timeout net_time,delay_mins delay,reopen_secs reopen,
       register,binding 
from v$archive_dest order by dest_id;
  

-- Check if there is any errors on standby

column message format a80 

select message, timestamp 
from v$dataguard_status 
where severity in ('Error','Fatal') 
order by timestamp; 

-- Check processes status involved in the SHIPPING redo.

select process,status,client_process,sequence#
from v$managed_standby;


-- Check log apply service are currently running on standby.
-- if it return no rows,then logical applying is not enabled.

column status format a50 wrap
column type format a11
set numwidth 15

SELECT TYPE, STATUS, HIGH_SCN               
FROM V$LOGSTDBY;

-- NEWEST_SCN is the max SCN that applied_scn will reach if no more log were received.
-- NEWEST_SCN > APPLIED_SCN , then APPLIED_SCN will increasing. 
-- NEWEST_SCN = APPLIED_SCN , then all changes will be applied.

set numwidth 15;
select 
  (case 
    when newest_scn = applied_scn then 'Done'
    when newest_scn <= applied_scn + 9 then 'Done?'
    when newest_scn > (select max(next_change#) from dba_logstdby_log)
    then 'Near done'
    when (select count(*) from dba_logstdby_log 
          where (next_change#, thread#) not in 
                  (select first_change#, thread# from dba_logstdby_log)) > 1
    then 'Gap'
    when newest_scn > applied_scn then 'Not Done'
    else '---' end) "Fin?",
    newest_scn, applied_scn, read_scn from dba_logstdby_progress;


select newest_time, applied_time, read_time from dba_logstdby_progress;

-- Determine if apply is lagging behind and by how much.  Missing
-- sequence#'s in a range indicate that a gap exists.

set numwidth 15
column trd format 99

select thread# trd, sequence#,
    first_change#, next_change#,
    dict_begin beg, dict_end end, 
    to_char(timestamp, 'hh:mi:ss') timestamp,
    (case when l.next_change# < p.read_scn then 'YES'
          when l.first_change# < p.applied_scn then 'CURRENT'
          else 'NO' end) applied
 from dba_logstdby_log l, dba_logstdby_progress p
 order by thread#, first_change#;

-- Get a history on logical standby apply activity.

set numwidth 15

select to_char(event_time, 'MM/DD HH24:MI:SS') time, 
       commit_scn, current_scn, event, status 
from dba_logstdby_events
order by event_time, commit_scn, current_scn;

-- Dump logical standby stats

column name format a40
column value format a20

select * from v$logstdby_stats;

-- Dump logical standby parameters

column name format a33 wrap
column value format a33 wrap
column type format 99

select name, value, type from system.logstdby$parameters 
order by type, name;

-- Gather log miner session and dictionary information.

set numwidth 15 

select * from system.logmnr_session$;
select * from system.logmnr_dictionary$;
select * from system.logmnr_dictstate$;
select * from v$logmnr_session;

-- Query the log miner dictionary for key tables necessary to process
-- changes for logical standby Label security will move AUD$ from SYS to
-- SYSTEM.  A synonym will remain in SYS but Logical Standby does not
-- support this.

set numwidth 5
column name format a9 wrap
column owner format a6 wrap

select o.logmnr_uid, o.obj#, o.objv#, u.name owner, o.name
 from system.logmnr_obj$ o, system.logmnr_user$ u 
 where 
      o.logmnr_uid = u.logmnr_uid and 
      o.owner# = u.user# and 
      o.name in ('JOB$','JOBSEQ','SEQ$','AUD$',
                 'FGA_LOG$','IND$','COL$','LOGSTDBY$PARAMETER')
 order by u.name;

-- Non-default init parameters. 

column name format a30 tru 
column value format a48 wra 
select name, value 
from v$parameter 
where isdefault = 'FALSE';
 
spool off
exit;
