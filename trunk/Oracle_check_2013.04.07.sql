-- ##################################################################################
-- Script Name: Oracle Check
-- ################################################################################## 
-- Purpose: This script is used to daily check Oracle database
-- Maintainers: Jet, Milo
-- Version change and reason:
---- v0.1   Script initial (Jet, Milo)
---- v0.1.1 Added the script header and modify need manually part (Milo)
----        modify nls_date_format=english to avoid spool file issue (Milo) 
----        modify the comments in wait and related sql (Milo)
----        add query sga auto resize view v$sga_resize_ops (Milo)
---- v0.1.2 Add more contents for pm report and modify the order of sql queries (Milo) 
---- v0.1.3 Add backup info part (Jet)
---- v0.1.4 Add some columns(version, modified) in dba_registry (Milo)
---- v0.1.5 Add Part 2.7 resource check (Milo)
----        Modify the v$log_history to latest 30 days history(Milo)
---- v0.1.6 Add missing crs check contents(Milo)
----        Add "tablespace cnt" alias for query(Milo)
----        Move v$sga_resize_ops to Performance session(Milo)
----        Remove datafile name check as datafile autoextend check already cover(Milo)
---- v0.1.7 Add Security Part(Part 2.8)  (Milo)
----        Log switch history change to 10 days. (Milo)
----            
---- v0.1.8 Add gather stats job run status(Part 2.5) (Milo)
----        Add more for CCB info. (Milo)
----



-- ##################################################################################


-- ################################################################################## 
----------- Part 1: Need manually ------------
-- ################################################################################## 

-----------------------------
--1. AWR or statspack
-----------------------------

----AWR report
--SQL> exec dbms_workload_repository.create_snapshot();
--SQL> @?/rdbms/admin/awrrpt.sql

----statspack report
--SQL> execute statspack.snap;
--SQL> @?/rdbms/admin/spreport.sql

-----------------------------
--2. Check datafile type
-----------------------------

--SELECT name
--FROM   v$datafile;  

--ls -lrt <datafile_dir>

-----------------------------
--3. Log check
-----------------------------

---tail alert.log
---tail listener.log



-- ##################################################################################
--------------Part 2: Sql Query -----------------
-- ##################################################################################

-----------------------------
-- output file name format
-----------------------------

set echo off 
set feedback off 
column timecol new_value timestamp 
column spool_extension new_value suffix 
select to_char(sysdate,'Mondd_hhmi') timecol, 
'.out' spool_extension from sys.dual; 
column output new_value dbname 
select value || '_' output 
from v$parameter where name = 'db_name'; 
spool Oracle_&&dbname&&timestamp&&suffix 

set linesize 79
set pagesize 180
set long 1000
set trim on 
set trims on 
alter session set nls_date_language=english;
alter session set nls_date_format = 'MM/DD HH24:MI:SS'; 
set feedback on 
select to_char(sysdate) time from dual; 
 
set echo on 


-- ########################################################
-- Part 2.1 Instance (SGA, PGA, Some parameters)
-- ########################################################

-- Check instance running status

set linesize 200;
col inst_id for 999;
col instance_name for a15;
col host_name for a10;
col version for a10;
col startup_time for a20;
col status for a8;
col archiver for a10;
col database_status for a15;
SELECT INST_ID,
       INSTANCE_NAME,
       HOST_NAME,
       VERSION,
       TO_CHAR(STARTUP_TIME, 'yyyy-mm-dd hh24:mi:ss') STARTUP_TIME,
       STATUS,
       ARCHIVER,
       DATABASE_STATUS
  FROM GV$INSTANCE;


-- Add from v0.1.8
-- SGA policy(sga_target) or memory policy(11g, memory_target)
show parameter target;


-- Add from v0.1.2
-- Check sga components' size (Avaliable for 10g and above)

col name for a35;
col MB for 999,999,999;
SELECT NAME, ROUND(BYTES / 1024 / 1024, 3) "MB" FROM V$SGAINFO;


-- Add from v0.1.2
-- Check sga basic info (Avaliable for 9i and above)

show sga;

-- Add from v0.1.2
-- Check sga and pga info (Avaliable for 9i and above)

show parameter sga;

-- pga info
show parameter pga;


-- Add from v0.1.8
-- PGA policy, if it's AUTO or MANUAL.
show parameter policy;

-- check all the components size
show parameter size;


-- Modify at v0.1.8
-- Non-default init parameters. 

column name format a30 tru 
column value format a48 wra 
SELECT NAME, VALUE, ISMODIFIED FROM V$PARAMETER WHERE ISDEFAULT = 'FALSE';


-- Add from v0.1.7
-- Total used memory(SGA+Allocated PGA)
SELECT A.SGA_MEM + B.PGA_MEM "TOTAL_MEMORY"
  FROM (SELECT SUM(CURRENT_SIZE) / 1024 / 1024 "SGA_MEM"
          FROM V$SGA_DYNAMIC_COMPONENTS,
               (SELECT SUM(PGA_ALLOC_MEM) / 1024 / 1024 "PGA_MEM"
                  FROM V$PROCESS) A
         WHERE COMPONENT IN ('shared pool',
                             'large pool',
                             'java pool',
                             'streams pool',
                             'DEFAULT buffer cache')) A,
       (SELECT SUM(PGA_ALLOC_MEM) / 1024 / 1024 "PGA_MEM" FROM V$PROCESS) B;


-- Add from v0.1.7
-- Check dynamic SGA componets size situation
set lines 200;
col component for a30;
SELECT COMPONENT,
       CURRENT_SIZE / 1024 / 1024 "CURRENT_SIZE",
       MIN_SIZE / 1024 / 1024 "MIN_SIZE",
       USER_SPECIFIED_SIZE / 1024 / 1024 "USER_SPECIFIED_SIZE",
       LAST_OPER_TYPE "TYPE"
  FROM V$SGA_DYNAMIC_COMPONENTS;


-- Add from v0.1.7
-- Check each SGA component and their granule_size
set lines 200;
col component for a30;
SELECT COMPONENT, GRANULE_SIZE / 1024 / 1024 "GRANULE_SIZE(Mb)"
  FROM V$SGA_DYNAMIC_COMPONENTS;

col component for a25
col status format a10 head "Status"
col initial_size for 999,999,999,999 head "Initial"
col parameter for a25 heading "Parameter"
col final_size for 999,999,999,999 head "Final"
col changed head "Changed At"
col low format 999,999,999,999 head "Lowest"
col high format 999,999,999,999 head "Highest"
col lowMB format 999,999 head "MBytes"
col highMB format 999,999 head "MBytes"
SELECT COMPONENT,
       PARAMETER,
       INITIAL_SIZE,
       FINAL_SIZE,
       STATUS,
       TO_CHAR(END_TIME, 'mm/dd/yyyy hh24:mi:ss') CHANGED
  FROM V$SGA_RESIZE_OPS
 ORDER BY COMPONENT;

SELECT COMPONENT,
       MIN(FINAL_SIZE) LOW,
       (MIN(FINAL_SIZE / 1024 / 1024)) LOWMB,
       MAX(FINAL_SIZE) HIGH,
       (MAX(FINAL_SIZE / 1024 / 1024)) HIGHMB
  FROM V$SGA_RESIZE_OPS
 GROUP BY COMPONENT
 ORDER BY COMPONENT;

-- Added from v0.1.1
-- Query sga auto resize action (Avaiable for 10g and above)

set linesize 200;
column component format a20;
column parameter format a20;
col oper_type for a15;
col oper_mode for a10;
col status for a10;
col initial_size for 999,999,999,999;
col target_size for 999,999,999,999;
col final_size for 999,999,999,999;
alter session set nls_date_format='yyyy-mm-dd hh24:mi:ss';
SELECT * FROM V$SGA_RESIZE_OPS;

-- Added from v0.1.7
-- display pool size
col pool for a15;
col name for a50;
col bytes for  999,999,999,999;
SELECT * FROM V$SGASTAT ORDER BY BYTES ASC;

-- Added from v0.1.7
-- display sga compoent size
col name for a20;
SELECT NAME, TRUNC(BYTES / 1024 / 1024, 2) "size(MB)"
  FROM V$SGASTAT
 WHERE POOL IS NULL
UNION
SELECT POOL, TRUNC(SUM(BYTES) / 1024 / 1024, 2) "size(MB)"
  FROM V$SGASTAT
 WHERE POOL IS NOT NULL
 GROUP BY POOL;
 

-- Added from v0.1.7
SELECT * FROM V$SGA_CURRENT_RESIZE_OPS;

-- Added from v0.1.7
SELECT * FROM V$SGA_TARGET_ADVICE;

-- Added from v0.1.7
show parameter statistics        



-- ########################################################
-- Part 2.2 DB Settings
-- ########################################################

-- Check DB version

SELECT * FROM V$VERSION;


-- Check Archive log mode 

SELECT DBID, NAME, DATABASE_ROLE, OPEN_MODE, LOG_MODE FROM V$DATABASE;

archive log list;

-- Check DB properties

set linesize 200;
col property_name for a30;
col property_value for a40;
col description for a40;
SELECT * FROM DATABASE_PROPERTIES;


-- Check DB option and feature

set linesize 200;
col parameter for a40;
col value for a8;
SELECT * FROM V$OPTION;

-- Check components are loaded in DB
---- Check if all loaded component are valid 
---- Normally, all component status should be "VALID"

col comp_name for a40;
col version for a12;
SELECT COMP_NAME, VERSION, STATUS, MODIFIED FROM DBA_REGISTRY;


-- Check which new feature has been enabled
---- This section displays the summary of Usage for Database Features.
---- The Currently Used column is TRUE if usage was detected for the feature at the last sample time.

SELECT OUTPUT FROM TABLE(DBMS_FEATURE_USAGE_REPORT.DISPLAY_TEXT);


-- ########################################################
-- Part 2.3 Datafiles Check
-- ########################################################

-- Check Total size of Datafile 

col Total(GB) for 999,999.99;
col Total(TB) for 999,999.99;
SELECT (D1 + D2) / 1073741824 "Total(GB)", --1024*1024*1024=1073741824
       (D1 + D2) / 1099511627776 "Total(TB)" --1024*1024*1024*1024=1099511627776
  FROM (SELECT SUM(BYTES) D1 FROM V$DATAFILE),
       (SELECT SUM(BYTES) D2 FROM V$TEMPFILE);

-- Check datafile count

SELECT COUNT(NAME) DATAFILE_CNT
  FROM (SELECT NAME
          FROM V$DATAFILE
        UNION
        SELECT NAME FROM V$TEMPFILE);

-- Check tablespace count

SELECT COUNT(*) TABLESPACE_CNT FROM DBA_TABLESPACES;


-- Modify at v0.1.8
-- Check datafile type along with ls -l check
-- Check if the files have autoextensiable attributes
 
col tablespace_name for a20;
col file_name for a45;
col autoextensible for a3;
col file_id for 999999;
SELECT FILE_ID,
       RELATIVE_FNO,
       FILE_NAME,
       TABLESPACE_NAME,
       STATUS,
       AUTOEXTENSIBLE
  FROM DBA_DATA_FILES
 ORDER BY AUTOEXTENSIBLE;

-- Remove from v0.1.8 as the funtion duplicated in this part
-- Check temp tablespace size
--col TOTAL(M)  for 999,999,999;
--col FREE(M) for 999,999,999;
--col USED(M) for 999,999,999;
--select tablespace_name,
--       (sum(bytes_used) + sum(bytes_free)) / 1048576 "TOTAL(M)", --1024*1024=1048576
--       sum(bytes_used) / 1048576 "USED(M)", --1024*1024=1048576
--       sum(bytes_free) / 1048576 "FREE(M)", --1024*1024=1048576
--       sum(bytes_used) / (sum(bytes_used) + sum(bytes_free)) * 100 "Used rate(%)"
--  from v$temp_space_header
-- group by tablespace_name;


-- Check availabe space of each tablespace
---- If the USE(%) > 85%, 
---- then the tablespace should be consider to extented. 

-- Normal tablespace report
set linesize 200;
col tablespace_name for a20;
col Total(M)  for 999,999,999;
col USED(M) for 999,999,999;
col FREE(M) for 999,999,999;
SELECT D.TABLESPACE_NAME,
       SPACE "Total(M)",
       SPACE - NVL(FREE_SPACE, 0) "USED(M)",
       ROUND((1 - NVL(FREE_SPACE, 0) / SPACE) * 100, 2) "USED(%)",
       FREE_SPACE "FREE(M)"
FROM (SELECT TABLESPACE_NAME,
               ROUND(SUM(BYTES) / 1048576, 2) SPACE,
               SUM(BLOCKS) BLOCKS
          FROM DBA_DATA_FILES
         GROUP BY TABLESPACE_NAME) D,
       (SELECT TABLESPACE_NAME,
               ROUND(SUM(BYTES) / 1048576, 2) FREE_SPACE
          FROM DBA_FREE_SPACE
         GROUP BY TABLESPACE_NAME) F
WHERE D.TABLESPACE_NAME = F.TABLESPACE_NAME(+)
ORDER BY 4;


-- Temporary tablespace space report
SELECT D.TABLESPACE_NAME,
       SPACE "Total(M)",
       USED_SPACE "USED(M)",
       ROUND(NVL(USED_SPACE, 0) / SPACE * 100, 2) "USED(%)",
       NVL(FREE_SPACE, 0) "FREE(M)"
  FROM (SELECT TABLESPACE_NAME,
               ROUND(SUM(BYTES) / 1048576, 2) SPACE,
               SUM(BLOCKS) BLOCKS
          FROM DBA_TEMP_FILES
         GROUP BY TABLESPACE_NAME) D,
       (SELECT TABLESPACE_NAME,
               ROUND(SUM(BYTES_USED) / 1048576, 2) USED_SPACE,
               ROUND(SUM(BYTES_FREE) / 1048576, 2) FREE_SPACE
          FROM V$TEMP_SPACE_HEADER
         GROUP BY TABLESPACE_NAME) F
 WHERE D.TABLESPACE_NAME = F.TABLESPACE_NAME(+)
 ORDER BY 4;



-- Add from v0.1.8
-- All tablespace attributes
SELECT TABLESPACE_NAME,
       STATUS,
       CONTENTS,
       EXTENT_MANAGEMENT,
       SEGMENT_SPACE_MANAGEMENT,
       LOGGING,
       BIGFILE
  FROM DBA_TABLESPACES
 ORDER BY CONTENTS, LOGGING; 
 
-- Add from v0.1.8
-- Each datafile used info
set linesize 200;
col tablespace_name for a20;
col file_name for a45;
SELECT T.FILE_ID,
       T.FILE_NAME,
       T.TABLESPACE_NAME,
       T.TOTAL_MB,
       ROUND((T.TOTAL_MB - F.FREE_MB), 2) USED_MB,
       ROUND((T.TOTAL_MB - F.FREE_MB) / T.TOTAL_MB * 100, 2) "USED(%)",
       T.AUTOEXTENSIBLE
  FROM (SELECT FILE_ID,
               FILE_NAME,
               TABLESPACE_NAME,
               ROUND(SUM(BYTES / 1024 / 1024)) TOTAL_MB,
               AUTOEXTENSIBLE
          FROM DBA_DATA_FILES
         GROUP BY FILE_ID, FILE_NAME, TABLESPACE_NAME, AUTOEXTENSIBLE) T,
       (SELECT FILE_ID, ROUND(SUM(BYTES / 1024 / 1024)) FREE_MB
          FROM DBA_FREE_SPACE
         GROUP BY FILE_ID) F
 WHERE T.FILE_ID = F.FILE_ID
 ORDER BY FILE_ID;




-- ########################################################
-- Part 2.4 Database Objects Check
-- ########################################################

-- Removed from v0.1.8 as duplicated in part 2.8
-- Check user account and they default tablespace status
--col username for a20;
--col account_status for a20;
--col default_tablespace for a20;
--col temporary_tablespace for a20;
--select username, account_status, default_tablespace, temporary_tablespace from dba_users;


-- Check tables and indexes in system tablespace  
-- that NOT belong to SYS OR SYSTEM, etc
---- Check if there are many other objects,
---- place in system tablespace, 
---- if so, then performance might be affected

SELECT DISTINCT OWNER
  FROM DBA_TABLES
 WHERE TABLESPACE_NAME = 'SYSTEM'
   AND OWNER NOT IN ('ANONYMOUS', 'BI', 'CTXSYS', 'DBSNMP', 'DIP', 'DMSYS', 'EXFSYS', 'HR', 'IX', 'LBACSYS', 'MDDATA',
                     'MDSYS', 'MGMT_VIEW', 'OE', 'OLAPSYS', 'ORDPLUGINS', 'ORDSYS', 'OUTLN', 'PM', 'SCOTT', 'SH', 'SI_INFORMTN_SCHEMA',
                     'SYS', 'SYSMAN', 'SYSTEM', 'WMSYS', 'WKPROXY', 'WK_TEST', 'WKSYS', 'XDB')
UNION
SELECT DISTINCT OWNER
  FROM DBA_INDEXES
 WHERE TABLESPACE_NAME = 'SYSTEM'
   AND OWNER NOT IN('ANONYMOUS', 'BI', 'CTXSYS', 'DBSNMP', 'DIP', 'DMSYS', 'EXFSYS', 'HR', 'IX', 'LBACSYS', 'MDDATA',
                     'MDSYS', 'MGMT_VIEW', 'OE', 'OLAPSYS', 'ORDPLUGINS', 'ORDSYS', 'OUTLN', 'PM', 'SCOTT', 'SH', 'SI_INFORMTN_SCHEMA',
                     'SYS', 'SYSMAN', 'SYSTEM', 'WMSYS', 'WKPROXY', 'WK_TEST', 'WKSYS', 'XDB');


-- Remove from v0.1.8 as the funtion duplicated in part 2.3
-- Check tablespace status
---- Normal status should be "ONLINE"

--SELECT tablespace_name,
--       status
--FROM   dba_tablespaces; 


-- Check log file status
---- Check basic info of redo log
---- Status column may be the listed value:
---- UNUSED, CURRENT, ACTIVE, INACTIVE,
---- CLEARING, CLEARING_CURRENT,

col group# for 999999;
col member# for 999;
col "log file path" for a35;
col "MB" for 999,999,999;
SELECT l.group#,
       l.members           AS "member#",
       lf.member           AS "log file path",
       bytes / 1024 / 1024 "MB",
       sequence#,
       l.status
FROM   v$log l,
       v$logfile lf
WHERE  l.group# = lf.group#
ORDER  BY group#,
          members;   


-- Check switch time of redo log
---- Statistik the frequency,normally is close to 30mins

alter session set nls_date_format='yyyy-mm-dd hh24:mi:ss';
col thread# for 9999;
col sequence# for 999999;
SELECT thread#,
       sequence#,
       first_time
FROM   v$log_history
where first_time > sysdate - 10
ORDER  BY thread#, sequence#; 


-- Check controlfile status

set linesize 200;
col status for a10;
col name for a80;
col block_size for 999,999,999;
col file_size_blks for 999,999,999;
SELECT *
FROM   v$controlfile; 


-- Check if there is invalid objects
---- Affirm the status of the objects

col owner for a20;
col object_name for a30;
col object_type for a15;
SELECT OWNER,
       OBJECT_NAME,
       OBJECT_TYPE
FROM   DBA_OBJECTS
WHERE  STATUS = 'INVALID'; 


-- Check if there is unusable indexes
---- Affirm the use of the indexes

col owner for a20;
col index_name for a20;
col index_type for a15;
col table_name for a20;
col status for a10;
SELECT OWNER,
       INDEX_NAME,
       INDEX_TYPE,
       TABLE_NAME,
       STATUS
FROM   DBA_INDEXES
WHERE  STATUS = 'UNUSABLE'; 

----*********************************************
-- Check if the indexes need rebuild
---- rebuild the height>=4 indexes
---- Will be discarded in next release(v0.1.8)
----*********************************************

SELECT NAME,
       HEIGHT,
       DEL_LF_ROWS/LF_ROWS
FROM INDEX_STATS 
WHERE HEIGHT>=4;


-- Unindexed tables
---- Only a check for necessary index creation
set linesize 200;
col owner for a10;
col segment_name for a30;
col segment_type for a10;
col tablespace_name for a15;
col size_mb for 999,999,999;
SELECT   /*+ rule */
        owner, segment_name, segment_type, tablespace_name,
        TRUNC (BYTES / 1024 / 1024, 1) size_mb
   FROM dba_segments t
  WHERE NOT EXISTS (
              SELECT 'x'
               FROM dba_indexes i
               WHERE t.owner = i.table_owner
                     AND t.segment_name = i.table_name)
    AND t.segment_type IN ('TABLE', 'TABLE PARTITION')
    AND t.owner NOT IN('SYS', 'SYSTEM', 'SYSMAN', 'DMSYS', 'EXFSYS','MDSYS', 'OLAPSYS', 'ORDSYS', 'TSMSYS', 'WMSYS', 'OUTLN', 'WMSYS', 'SCOTT' )
ORDER BY 5 DESC;


-- Check if there have disabled constraints
---- Enable the disabled constraints

set linesize 200;
col owner for a20;
col CONSTRAINT_NAME for a30;
col CONSTRAINT_TYPE for a15;
col TABLE_NAME for a20;
SELECT OWNER,
       CONSTRAINT_NAME,
       CONSTRAINT_TYPE,
       TABLE_NAME
FROM   DBA_CONSTRAINTS
WHERE  STATUS = 'DISABLED'; 


-- Check if there have disabled triggers
---- Recompile the disabled triggers

col owner for a20;
col TRIGGER_NAME for a30;
col TRIGGER_TYPE for a20;
SELECT OWNER,
       TRIGGER_NAME,
       TRIGGER_TYPE
FROM   DBA_TRIGGERS
WHERE  STATUS = 'DISABLED'; 


-- Check active Session Count
---- Monitor the workload

SELECT Count(*) "ACTIVE Session Count" ,INST_ID 
FROM   gv$session
where  status = 'ACTIVE'
       AND username NOT IN ( 'SYS', 'SYSTEM' )
group by INST_ID ;  


-- ########################################################
-- Part 2.5 Database Performance Check
-- ########################################################


-- Check Buffer Cache hit ratio
---- This value should greater than 95%

SELECT (1 - (SUM(DECODE(NAME, 'physical reads', VALUE, 0)) /
       (SUM(DECODE(NAME, 'db block gets', VALUE, 0)) +
       SUM(DECODE(NAME, 'consistent gets', VALUE, 0))))) * 100 "Buffer Cache Hit Ratio(%)"
FROM V$SYSSTAT;


-- Check Sorting Efficiency - Memory Sorting(%)
---- This value should greater than 95%

SELECT a.VALUE        "Disk Sorting",
       b.VALUE        "Memory Sorting",
       ROUND(( 100 * b.VALUE ) / DECODE(( a.VALUE + b.VALUE ), 0, 1,
       ( a.VALUE + b.VALUE )), 2) "Memory Sorting (%)"
FROM   v$sysstat a,
       v$sysstat b
WHERE  a.name = 'sorts (disk)'
       AND b.name = 'sorts (memory)';


-- Check Redo Log Hit Ratio
---- This value should greater than 95%

col name for a20;
col gets for 999,999,999;
col misses for 999,999,999;
SELECT name,
       gets,
       misses,
       immediate_gets,
       immediate_misses,
       100 - ROUND(DECODE(gets, 0, 0,
                          misses / ( gets + misses )), 2) * 100 ratio1,
       100 - ROUND(DECODE(immediate_gets + immediate_misses, 0, 0,
                                                       immediate_misses / (
             immediate_gets + immediate_misses )), 2) * 100     ratio2
FROM   v$latch
WHERE  name IN ( 'redo allocation', 'redo copy' ); 



-- Check Dictionary Hit Ratio
---- This value should greater than 95%

SELECT ROUND(( 1 - ( Sum(GETMISSES) / Sum(GETS) ) ), 2) * 100 "Dictionary Hit Ratio(%)"
FROM   V$ROWCACHE;



-- Check Labrary Cache Hit Ratio
---- This value should greater than 95%

SELECT ROUND(SUM(PINS) / (SUM(PINS) + SUM(RELOADS)), 2) * 100 "Labrary Cache Hit Ratio(%)"
FROM V$LIBRARYCACHE;


-- Check IO status of each datafile
---- To find out which datafile is in high write/read status

set linesize 200;
col file_name for a46
SELECT df.name                                          file_name,
       fs.phyrds                                        reads,
       fs.phywrts                                       writes,
       ( fs.readtim / Decode(fs.phyrds, 0, -1,
                                        fs.phyrds) )    readtime,
       ( fs.writetim / Decode(fs.phywrts, 0, -1,
                                          fs.phywrts) ) writetime
FROM   v$datafile df,
       v$filestat fs
WHERE  df.file# = fs.file#
ORDER  BY df.name; 


-- Check if there lock exists
---- Attention the lock rows last long time

col user_name for a15;
col owner for a15;
col object_name for a15;
col object_type for a15;
col sid for 999999;
col serial# for 999999;
SELECT /*+ rule */ Lpad(' ', DECODE(l.xidusn, 0, 3,
                                              0))
                    || l.oracle_username user_name,
                   o.owner,
                   o.object_name,
                   o.object_type,
                   s.sid,
                   s.serial#
FROM   gv$locked_object l,
       dba_objects o,
       gv$session s
WHERE  l.object_id = o.object_id
       AND l.session_id = s.sid
ORDER  BY o.object_id,
          xidusn DESC; 


-- Check the wait events
---- Attention the top wait events

col event for a40;
col time_waited for 999,999,999,999,999,999,999;
SELECT *
FROM   (SELECT event,
               time_waited
        FROM   v$system_event
        ORDER  BY time_waited DESC)
WHERE  rownum < 11;  


-- Query which sql experience the wait
---- Attention the always appeared SQL

set linesize 200;
col sql_text for a60;
col event for a30;
select s.sql_text, sw.event 
from v$session b,v$session_wait sw,v$sqltext s 
where b.sid=sw.sid 
	and sw.event not like '%SQL*Net%' 
	and sw.EVENT NOT LIKE 'rdbms%' 
	and s.hash_value=b.sql_hash_value 
	and s.sql_id=b.sql_id 
order by s.address,s.piece;



-- Add from v0.1.8
-- Check Auto collect statistics
---- Check if the gather stats job is enabled
SET LINESIZE 200;
COL JOB_ACTION FOR A20;
select owner, job_name, job_action, enabled, state
from dba_scheduler_jobs
where job_name='GATHER_STATS_JOB';

-- Add from v0.1.8
---- Check the latest gather stats job running status
set linesize 200;
col job_name for a20;
col status for a15;
col start_date for a25;
col log_date for a25;
select log_id, job_name, status, to_char(actual_start_date, 'yyyy-mm-dd hh24:mi:ss') start_date,
       to_char(log_date, 'yyyy-mm-dd hh24:mi:ss') log_date
from   dba_scheduler_job_run_details
where job_name='GATHER_STATS_JOB'
order by 4;   




-- ########################################################
-- Part 2.6 Database RMAN Backup Information
-- ########################################################

-- Check Rman Backup info
set linesize 200;
col device_type for a10;
col handle for a20;
col tag for a25;
col comments for a15;
alter session set nls_date_format='yyyy-mm-dd hh24:mi:ss';
select bs_key, bp_key, device_type, handle, tag,  deleted, status, start_time, completion_time, comments 
from v$backup_piece_details;

-- Add from v0.1.8
-- Recover file status
SELECT * FROM GV$RECOVERY_FILE_STATUS;

 


-- ########################################################
-- Part 2.7 Some Resource Info
-- ########################################################

-- Check the resource limits
set linesize 200;
col resource_name for a25;
select * from v$resource_limit;


-- ########################################################
-- Part 2.8 Security Info
-- ########################################################

-- Add from v0.1.7
-- Showing that which user has DBA role
col grantee for a25;
col granted_role for a25;
select * from dba_role_privs where granted_role='DBA';

-- Add from v0.1.7
-- The password file users, showing that the user has sysdba or sysoper role
col username for a25;
select * from v$pwfile_users;

-- Add from v0.1.7
-- DB audit or NOT
show parameter audit;


-- Add from v0.1.8
---- User and their profile and granted role
col username for a15;
col account_status for a20;
col default_tablespace for a20;
col temporary_tablespace for a22;
col profile for a20;
col granted_role for a25;
BREAK on username skip 1 on account_status on default_tablespace on temporary_tablespace on profile;
SELECT   username, account_status, default_tablespace, temporary_tablespace, PROFILE,
         granted_role, admin_option, default_role
    FROM sys.dba_users a, sys.dba_role_privs b
   WHERE a.username = b.grantee
ORDER BY account_status, 
         username,
         default_tablespace,
         temporary_tablespace,
         PROFILE,
         granted_role;


-- Add from v0.1.8
-- User profile
COLUMN profile          format A20      heading Profile
COLUMN resource_name                    heading 'Resource:'
COLUMN limit            format A15      heading Limit
SELECT   PROFILE, resource_name, LIMIT
    FROM sys.dba_profiles
ORDER BY PROFILE;


-- #######################################################
-- Last Part: check CRS_STAT
-- #######################################################

-- Check if there is crs in RAC ( double check )
! crs_stat -t 
! crsctl stat res -t

#-- ##################################################################################

exit;
