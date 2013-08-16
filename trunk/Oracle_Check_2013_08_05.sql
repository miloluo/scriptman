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
---- v0.1.9 Reformat SQL format(Milo)
----        Add part 2.9 other info part for special check(Milo
----        Remove some unused 
----
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

--SELECT name FROM   v$datafile;  
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

SET ECHO OFF
SET FEEDBACK OFF
-- DON'T REMOVE NLS_DATE_LANAGE SETINGG, AS THIS MIGHT CAUSE NO OUTPUT FILE SHOW!!!!!!!!
ALTER SESSION SET nls_date_language=english;

COLUMN timecol NEW_VALUE timestamp
COLUMN spool_extension NEW_VALUE SUFFIX

SELECT TO_CHAR (SYSDATE, 'Mondd_hhmi') timecol, '.out' spool_extension
  FROM sys.DUAL;

COLUMN output NEW_VALUE dbname

SELECT VALUE || '_' output
  FROM v$parameter
 WHERE name = 'db_name';

SPOOL Oracle_&&dbname&&timestamp&&suffix

SET LINESIZE 79
SET PAGESIZE 180
SET LONG 1000
SET TRIM ON
SET TRIMS ON
ALTER SESSION SET nls_date_language=english;
ALTER SESSION SET nls_date_format = 'MM/DD HH24:MI:SS';
SET FEEDBACK ON

SELECT TO_CHAR (SYSDATE) time FROM DUAL;

SET ECHO ON



-- Check which new feature has been enabled
---- This section displays the summary of Usage for Database Features.
---- The Currently Used column is TRUE if usage was detected for the feature at the last sample time.
---- v0.1.9 format the report

SET LINES 200;
SET PAGES 50000;
COL output FOR a100;

SELECT OUTPUT FROM TABLE (DBMS_FEATURE_USAGE_REPORT.DISPLAY_TEXT);
SET PAGES 180;

-- ########################################################
-- Part 2.1 Instance (SGA, PGA, Some parameters)
-- ########################################################

-- Check instance running status
SET LINESIZE 200;
COL inst_id FOR 999;
COL instance_name FOR a15;
COL host_name FOR a10;
COL version FOR a10;
COL startup_time FOR a20;
COL status FOR a8;
COL archiver FOR a10;
COL database_status FOR a15;

SELECT INST_ID,
       INSTANCE_NAME,
       HOST_NAME,
       VERSION,
       TO_CHAR (STARTUP_TIME, 'yyyy-mm-dd hh24:mi:ss') STARTUP_TIME,
       STATUS,
       ARCHIVER,
       DATABASE_STATUS
  FROM GV$INSTANCE;


-- Add from v0.1.8
-- SGA policy(sga_target) or memory policy(11g, memory_target)
show parameter target;


-- Add from v0.1.2
-- Check sga components' size (Avaliable for 10g and above)

COL name FOR a35;
COL MB FOR 999,999,999;

  SELECT NAME, ROUND (BYTES / 1024 / 1024, 3) "MB"
    FROM V$SGAINFO
ORDER BY MB;


-- Add from v0.1.2
-- Check sga basic info (Avaliable for 9i and above)

SHOW SGA;

-- Add from v0.1.2
-- Check sga and pga info (Avaliable for 9i and above)

SHOW PARAMETER SGA;

-- Add from v0.1.2
-- pga info

SHOW PARAMETER pga;


-- Add from v0.1.8
-- PGA policy, if it's AUTO or MANUAL.

SHOW PARAMETER policy;

-- check all the components size

SHOW PARAMETER SIZE;


-- Modify at v0.1.8
-- Non-default init parameters. 

COLUMN name FORMAT a30 TRU
COLUMN value FORMAT a48 WRA

SELECT NAME, VALUE, ISMODIFIED
  FROM V$PARAMETER
 WHERE ISDEFAULT = 'FALSE';


-- Add from v0.1.7
-- Total used memory(SGA+Allocated PGA)
SELECT A.SGA_MEM + B.PGA_MEM "TOTAL_MEMORY"
  FROM (SELECT SUM (CURRENT_SIZE) / 1024 / 1024 "SGA_MEM"
          FROM V$SGA_DYNAMIC_COMPONENTS,
               (SELECT SUM (PGA_ALLOC_MEM) / 1024 / 1024 "PGA_MEM"
                  FROM V$PROCESS) A
         WHERE COMPONENT IN
                  ('shared pool',
                   'large pool',
                   'java pool',
                   'streams pool',
                   'DEFAULT buffer cache')) A,
       (SELECT SUM (PGA_ALLOC_MEM) / 1024 / 1024 "PGA_MEM" FROM V$PROCESS) B;


-- Add from v0.1.7
-- Check dynamic SGA componets size situation
SET LINES 200;
COL component FOR a30;

SELECT COMPONENT,
       CURRENT_SIZE / 1024 / 1024 "CURRENT_SIZE",
       MIN_SIZE / 1024 / 1024 "MIN_SIZE",
       USER_SPECIFIED_SIZE / 1024 / 1024 "USER_SPECIFIED_SIZE",
       LAST_OPER_TYPE "TYPE"
  FROM V$SGA_DYNAMIC_COMPONENTS;


-- Add from v0.1.7
-- Check each SGA component and their granule_size
SET LINES 200;
COL component FOR a30;

SELECT COMPONENT, GRANULE_SIZE / 1024 / 1024 "GRANULE_SIZE(Mb)"
  FROM V$SGA_DYNAMIC_COMPONENTS;

COL component FOR a25
COL status FORMAT a10 HEAD "Status"
COL initial_size FOR 999,999,999,999 HEAD "Initial"
COL parameter FOR a25 HEADING "Parameter"
COL final_size FOR 999,999,999,999 HEAD "Final"
COL changed HEAD "Changed At"
COL low FORMAT 999,999,999,999 HEAD "Lowest"
COL high FORMAT 999,999,999,999 HEAD "Highest"
COL lowMB FORMAT 999,999 HEAD "MBytes"
COL highMB FORMAT 999,999 HEAD "MBytes"

  SELECT COMPONENT,
         PARAMETER,
         INITIAL_SIZE,
         FINAL_SIZE,
         STATUS,
         TO_CHAR (END_TIME, 'mm/dd/yyyy hh24:mi:ss') CHANGED
    FROM V$SGA_RESIZE_OPS
ORDER BY COMPONENT;

  SELECT COMPONENT,
         MIN (FINAL_SIZE) LOW,
         (MIN (FINAL_SIZE / 1024 / 1024)) LOWMB,
         MAX (FINAL_SIZE) HIGH,
         (MAX (FINAL_SIZE / 1024 / 1024)) HIGHMB
    FROM V$SGA_RESIZE_OPS
GROUP BY COMPONENT
ORDER BY COMPONENT;

-- Added from v0.1.1
-- Query sga auto resize action (Avaiable for 10g and above)

SET LINESIZE 200;
COLUMN component FORMAT a25;
COLUMN parameter FORMAT a25;
COL oper_type FOR a15;
COL oper_mode FOR a10;
COL status FOR a10;
COL initial_size FOR 999,999,999,999;
COL target_size FOR 999,999,999,999;
COL final_size FOR 999,999,999,999;
ALTER SESSION SET nls_date_format='yyyy-mm-dd hh24:mi:ss';

SELECT * FROM V$SGA_RESIZE_OPS;

-- Added from v0.1.7
-- display pool size
COL pool FOR a15;
COL name FOR a40;
COL bytes FOR  999,999,999,999;

  SELECT *
    FROM V$SGASTAT
ORDER BY BYTES ASC;

-- Added from v0.1.7
-- display sga compoent size
COL name FOR a20;

SELECT NAME, TRUNC (BYTES / 1024 / 1024, 2) "size(MB)"
  FROM V$SGASTAT
 WHERE POOL IS NULL
UNION
  SELECT POOL, TRUNC (SUM (BYTES) / 1024 / 1024, 2) "size(MB)"
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

-- Check PSU version

SET LINES 200;
COL action_time FOR a30;
COL action FOR a20;
COL namespace FOR a15;
COL version FOR a15;
COL comments FOR a30;

  SELECT *
    FROM sys.registry$history
ORDER BY 1;

-- Check Archive log mode 

SELECT DBID,
       NAME,
       DATABASE_ROLE,
       OPEN_MODE,
       LOG_MODE
  FROM V$DATABASE;

ARCHIVE LOG LIST;

-- Check DB properties

SET LINESIZE 200;
COL property_name FOR a30;
COL property_value FOR a40;
COL description FOR a60;

SELECT * FROM DATABASE_PROPERTIES;


-- Check DB option and feature

SET LINESIZE 200;
COL parameter FOR a40;
COL value FOR a8;

  SELECT *
    FROM V$OPTION
ORDER BY 2, 1;


-- Check components are loaded in DB
---- Check if all loaded component are valid 
---- Normally, all component status should be "VALID"

COL comp_name FOR a40;
COL version FOR a12;

  SELECT COMP_NAME,
         VERSION,
         STATUS,
         MODIFIED
    FROM DBA_REGISTRY
ORDER BY STATUS;




-- ########################################################
-- Part 2.3 Datafiles Check
-- ########################################################

-- Check Total size of Datafile 

COL Total(GB) FOR 999,999.99;
COL Total(TB) FOR 999,999.99;

SELECT (D1 + D2) / 1073741824 "Total(GB)",         --1024*1024*1024=1073741824
       (D1 + D2) / 1099511627776 "Total(TB)"       --1024*1024*1024*1024=1099511627776
  FROM (SELECT SUM (BYTES) D1 FROM V$DATAFILE),
       (SELECT SUM (BYTES) D2 FROM V$TEMPFILE);
       

-- Check datafile count

SELECT COUNT (NAME) DATAFILE_CNT
  FROM (SELECT NAME FROM V$DATAFILE
        UNION
        SELECT NAME FROM V$TEMPFILE);

-- Check tablespace count

SELECT COUNT (*) TABLESPACE_CNT FROM DBA_TABLESPACES;


-- Modify at v0.1.8
---- Check datafile type along with ls -l check
---- Check if the files have autoextensiable attributes
---- v0.1.9 Add tablespace_name in order to quickly identify which tablespaces has file to be extented or not.
 
COL tablespace_name FOR a40;
COL file_name FOR a45;
COL autoextensible FOR a3;
COL file_id FOR 999999;

  SELECT FILE_ID,
         RELATIVE_FNO,
         FILE_NAME,
         TABLESPACE_NAME,
         STATUS,
         AUTOEXTENSIBLE
    FROM DBA_DATA_FILES
ORDER BY AUTOEXTENSIBLE, TABLESPACE_NAME;


-- Add from v0.1.9
---- tablespaces' attributes
SELECT status,
       tablespace_name name,
       contents TYPE,
       SEGMENT_SPACE_MANAGEMENT,
       EXTENT_MANAGEMENT,
       block_size,
       allocation_type
  FROM dba_tablespaces;


-- Check availabe space of each tablespace
---- If the USE(%) > 85%, 
---- then the tablespace should be consider to extented. 

-- Normal tablespace report
SET LINESIZE 200;
COL tablespace_name FOR a40;
COL Total(M)  FOR 999,999,999;
COL USED(M) FOR 999,999,999;
COL FREE(M) FOR 999,999,999;

  SELECT D.TABLESPACE_NAME,
         SPACE "Total(M)",
         SPACE - NVL (FREE_SPACE, 0) "USED(M)",
         ROUND ( (1 - NVL (FREE_SPACE, 0) / SPACE) * 100, 0) "USED(%)",
         FREE_SPACE "FREE(M)"
    FROM (  SELECT TABLESPACE_NAME,
                   ROUND (SUM (BYTES) / 1048576, 0) SPACE,
                   SUM (BLOCKS) BLOCKS
              FROM DBA_DATA_FILES
          GROUP BY TABLESPACE_NAME) D,
         (  SELECT TABLESPACE_NAME, ROUND (SUM (BYTES) / 1048576, 0) FREE_SPACE
              FROM DBA_FREE_SPACE
          GROUP BY TABLESPACE_NAME) F
   WHERE D.TABLESPACE_NAME = F.TABLESPACE_NAME(+)
ORDER BY 4;


-- Temporary tablespace space report
  SELECT D.TABLESPACE_NAME,
         SPACE "Total(M)",
         USED_SPACE "USED(M)",
         ROUND (NVL (USED_SPACE, 0) / SPACE * 100, 0) "USED(%)",
         NVL (FREE_SPACE, 0) "FREE(M)"
    FROM (  SELECT TABLESPACE_NAME,
                   ROUND (SUM (BYTES) / 1048576, 0) SPACE,
                   SUM (BLOCKS) BLOCKS
              FROM DBA_TEMP_FILES
          GROUP BY TABLESPACE_NAME) D,
         (  SELECT TABLESPACE_NAME,
                   ROUND (SUM (BYTES_USED) / 1048576, 0) USED_SPACE,
                   ROUND (SUM (BYTES_FREE) / 1048576, 0) FREE_SPACE
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
SET LINESIZE 200;
COL tablespace_name FOR a20;
COL file_name FOR a45;

  SELECT T.FILE_ID,
         T.FILE_NAME,
         T.TABLESPACE_NAME,
         T.TOTAL_MB,
         ROUND ( (T.TOTAL_MB - F.FREE_MB), 2) USED_MB,
         ROUND ( (T.TOTAL_MB - F.FREE_MB) / T.TOTAL_MB * 100, 0) "USED(%)",
         T.AUTOEXTENSIBLE
    FROM (  SELECT FILE_ID,
                   FILE_NAME,
                   TABLESPACE_NAME,
                   ROUND (SUM (BYTES / 1024 / 1024),0) TOTAL_MB,
                   AUTOEXTENSIBLE
              FROM DBA_DATA_FILES
          GROUP BY FILE_ID,
                   FILE_NAME,
                   TABLESPACE_NAME,
                   AUTOEXTENSIBLE) T,
         (  SELECT FILE_ID, ROUND (SUM (BYTES / 1024 / 1024),0) FREE_MB
              FROM DBA_FREE_SPACE
          GROUP BY FILE_ID) F
   WHERE T.FILE_ID = F.FILE_ID
ORDER BY FILE_ID;




-- ########################################################
-- Part 2.4 Database Objects Check
-- ########################################################

-- Check tables and indexes in system tablespace  
-- that NOT belong to SYS OR SYSTEM, etc
---- Check if there are many other objects,
---- place in system tablespace, 
---- if so, then performance might be affected
---- v0.1.9 Add 11g new users(component users) in the list

SELECT DISTINCT OWNER
  FROM DBA_TABLES
 WHERE TABLESPACE_NAME = 'SYSTEM'
   AND OWNER NOT IN ('ANONYMOUS', 'BI', 'CTXSYS', 'DBSNMP', 'DIP', 'DMSYS', 'EXFSYS', 'HR', 'IX', 'LBACSYS', 'MDDATA',
                     'MDSYS', 'MGMT_VIEW', 'OE', 'OLAPSYS', 'ORDPLUGINS', 'ORDSYS', 'OUTLN', 'PM', 'SCOTT', 'SH', 'SI_INFORMTN_SCHEMA',
                     'SYS', 'SYSMAN', 'SYSTEM', 'WMSYS', 'WKPROXY', 'WK_TEST', 'WKSYS', 'XDB', 'APEX_030200', 'APEX_PUBLIC_USER', 'APPQOSSYS', 'DVSYS',
                     'FLOWS_FILES', 'IX', 'LBACSYS', 'ORACLE_OCM', 'OWBSYS', 'OWBSYS_AUDIT', 'SPATIAL_CSW_ADMIN_USR', 'SPATIAL_WFS_ADMIN_USR')
UNION
SELECT DISTINCT OWNER
  FROM DBA_INDEXES
 WHERE TABLESPACE_NAME = 'SYSTEM'
   AND OWNER NOT IN('ANONYMOUS', 'BI', 'CTXSYS', 'DBSNMP', 'DIP', 'DMSYS', 'EXFSYS', 'HR', 'IX', 'LBACSYS', 'MDDATA',
                     'MDSYS', 'MGMT_VIEW', 'OE', 'OLAPSYS', 'ORDPLUGINS', 'ORDSYS', 'OUTLN', 'PM', 'SCOTT', 'SH', 'SI_INFORMTN_SCHEMA',
                     'SYS', 'SYSMAN', 'SYSTEM', 'WMSYS', 'WKPROXY', 'WK_TEST', 'WKSYS', 'XDB', 'APEX_030200', 'APEX_PUBLIC_USER', 'APPQOSSYS', 'DVSYS',
                     'FLOWS_FILES', 'IX', 'LBACSYS', 'ORACLE_OCM', 'OWBSYS', 'OWBSYS_AUDIT', 'SPATIAL_CSW_ADMIN_USR', 'SPATIAL_WFS_ADMIN_USR');


-- Check log file status
---- Check basic info of redo log
---- Status column may be the listed value:
---- UNUSED, CURRENT, ACTIVE, INACTIVE,
---- CLEARING, CLEARING_CURRENT,

COL group# FOR 999999;
COL member# FOR 999;
COL "log file path" FOR a50;
COL "MB" FOR 999,999,999;

  SELECT l.group#,
         l.members AS "member#",
         lf.MEMBER AS "log file path",
         bytes / 1024 / 1024 "MB",
         sequence#,
         l.status
    FROM v$log l, v$logfile lf
   WHERE l.group# = lf.group#
ORDER BY group#, members;


-- Check switch time of redo log
---- Statistik the frequency,normally is close to 20mins ~ 30mins, only fetch recently 500 items for most
---- v0.1.9 limit recently 500 lines switch log 

ALTER SESSION SET nls_date_format='yyyy-mm-dd hh24:mi:ss';
COL thread# FOR 9999;
COL sequence# FOR 999999;

SELECT *
  FROM (  SELECT thread#,
                 sequence#,
                 first_time,
                 resetlogs_time
            FROM v$log_history
           WHERE first_time > SYSDATE - 8
        ORDER BY resetlogs_time DESC, thread# DESC, sequence# DESC)
 WHERE ROWNUM <= 500;


-- Check controlfile status

SET LINESIZE 200;
COL status FOR a10;
COL name FOR a80;
COL block_size FOR 999,999,999;
COL file_size_blks FOR 999,999,999;

SELECT * FROM v$controlfile;


-- Check if there is invalid objects
---- Affirm the status of the objects

COL owner FOR a20;
COL object_name FOR a30;
COL object_type FOR a15;

SELECT OWNER, OBJECT_NAME, OBJECT_TYPE
  FROM DBA_OBJECTS
 WHERE STATUS = 'INVALID';


-- Check if there is unusable indexes
---- Affirm the use of the indexes

SET LINES 200;
COL owner FOR a20;
COL index_name FOR a20;
COL index_type FOR a15;
COL table_name FOR a20;
COL status FOR a10;
COL degree FOR a10;

SELECT OWNER,
       INDEX_NAME,
       INDEX_TYPE,
       COMPRESSION,
       DEGREE,
       TABLE_NAME,
       STATUS
  FROM DBA_INDEXES
 WHERE STATUS = 'UNUSABLE';
 
 

-- Unindexed tables
---- Only a check for necessary index creation
---- v0.1.9 update the user list

SET LINESIZE 200;
COL owner FOR a10;
COL segment_name FOR a30;
COL segment_type FOR a10;
COL tablespace_name FOR a15;
COL size_mb FOR 999,999,999;

  SELECT    /*+ rule */
        owner,
         segment_name,
         segment_type,
         tablespace_name,
         TRUNC (BYTES / 1024 / 1024, 1) size_mb
    FROM dba_segments t
   WHERE NOT EXISTS
            (SELECT 'x'
               FROM dba_indexes i
              WHERE t.owner = i.table_owner AND t.segment_name = i.table_name)
         AND t.segment_type IN ('TABLE', 'TABLE PARTITION')
         AND t.owner NOT IN ('ANONYMOUS', 'BI', 'CTXSYS', 'DBSNMP', 'DIP', 'DMSYS', 'EXFSYS', 'HR', 'IX', 'LBACSYS', 'MDDATA',
                     'MDSYS', 'MGMT_VIEW', 'OE', 'OLAPSYS', 'ORDPLUGINS', 'ORDSYS', 'OUTLN', 'PM', 'SCOTT', 'SH', 'SI_INFORMTN_SCHEMA',
                     'SYS', 'SYSMAN', 'SYSTEM', 'WMSYS', 'WKPROXY', 'WK_TEST', 'WKSYS', 'XDB', 'APEX_030200', 'APEX_PUBLIC_USER', 'APPQOSSYS', 'DVSYS',
                     'FLOWS_FILES', 'IX', 'LBACSYS', 'ORACLE_OCM', 'OWBSYS', 'OWBSYS_AUDIT', 'SPATIAL_CSW_ADMIN_USR', 'SPATIAL_WFS_ADMIN_USR')
ORDER BY 5 DESC;


-- Check if there have disabled constraints
---- Enable the disabled constraints

SET LINESIZE 200;
COL owner FOR a20;
COL CONSTRAINT_NAME FOR a30;
COL CONSTRAINT_TYPE FOR a15;
COL TABLE_NAME FOR a20;

SELECT OWNER,
       CONSTRAINT_NAME,
       CONSTRAINT_TYPE,
       TABLE_NAME
  FROM DBA_CONSTRAINTS
 WHERE STATUS = 'DISABLED';


-- Check if there have disabled triggers
---- Recompile the disabled triggers

COL owner FOR a20;
COL TRIGGER_NAME FOR a30;
COL TRIGGER_TYPE FOR a20;

SELECT OWNER, TRIGGER_NAME, TRIGGER_TYPE
  FROM DBA_TRIGGERS
 WHERE STATUS = 'DISABLED';


-- Check active Session Count
---- Monitor the workload

  SELECT COUNT (*) "ACTIVE Session Count", INST_ID
    FROM gv$session
   WHERE status = 'ACTIVE' AND username NOT IN ('SYS', 'SYSTEM')
GROUP BY INST_ID;


-- ########################################################
-- Part 2.5 Database Performance Check
-- ########################################################


-- Check Buffer Cache hit ratio
---- This value should greater than 95%
SELECT ROUND (
          1
          - (SUM (DECODE (NAME, 'physical reads', VALUE, 0))
             / (SUM (DECODE (NAME, 'db block gets', VALUE, 0))
                + SUM (DECODE (NAME, 'consistent gets', VALUE, 0)))),
          0)
       * 100
          "Buffer Cache Hit Ratio(%)"
  FROM V$SYSSTAT;


-- Check Sorting Efficiency - Memory Sorting(%)
---- This value should greater than 95%

SELECT a.VALUE "Disk Sorting",
       b.VALUE "Memory Sorting",
       ROUND (
          (100 * b.VALUE)
          / DECODE ( (a.VALUE + b.VALUE), 0, 1, (a.VALUE + b.VALUE)),
          0)
          "Memory Sorting (%)"
  FROM v$sysstat a, v$sysstat b
 WHERE a.name = 'sorts (disk)' AND b.name = 'sorts (memory)';


-- Check Redo Log Hit Ratio
---- This value should greater than 95%

COL name FOR a20;
COL gets FOR 999,999,999;
COL misses FOR 999,999,999;

SELECT name,
       gets,
       misses,
       immediate_gets,
       immediate_misses,
       100 - ROUND (DECODE (gets, 0, 0, misses / (gets + misses)), 2) * 100
          "RATIO1(%)",
       100
       - ROUND (
            DECODE (immediate_gets + immediate_misses,
                    0, 0,
                    immediate_misses / (immediate_gets + immediate_misses)),
            0)
         * 100
          "RATIO2(%)"
  FROM v$latch
 WHERE name IN ('redo allocation', 'redo copy');



-- Check Dictionary Hit Ratio
---- This value should greater than 95%

SELECT ROUND ( (1 - (SUM (GETMISSES) / SUM (GETS))), 0) * 100
          "Dictionary Hit Ratio(%)"
  FROM V$ROWCACHE;



-- Check Labrary Cache Hit Ratio
---- This value should greater than 95%

SELECT ROUND (SUM (PINS) / (SUM (PINS) + SUM (RELOADS)), 0) * 100
          "Labrary Cache Hit Ratio(%)"
  FROM V$LIBRARYCACHE;


-- Check IO status of each datafile
---- To find out which datafile is in high write/read status

SET LINESIZE 200;
COL file_name FOR a46

  SELECT df.name file_name,
         fs.phyrds reads,
         fs.phywrts writes,
         ROUND (fs.readtim / DECODE (fs.phyrds, 0, -1, fs.phyrds), 3) readtime,
         ROUND (fs.writetim / DECODE (fs.phywrts, 0, -1, fs.phywrts), 3)
            writetime
    FROM v$datafile df, v$filestat fs
   WHERE df.file# = fs.file#
ORDER BY df.name;


-- Check if there lock exists
---- Attention the lock rows last long time

COL user_name FOR a15;
COL owner FOR a15;
COL object_name FOR a15;
COL object_type FOR a15;
COL sid FOR 999999;
COL serial# FOR 999999;

  SELECT    /*+ rule */
        LPAD (' ', DECODE (l.xidusn, 0, 3, 0)) || l.oracle_username user_name,
         o.owner,
         o.object_name,
         o.object_type,
         s.sid,
         s.serial#
    FROM gv$locked_object l, dba_objects o, gv$session s
   WHERE l.object_id = o.object_id AND l.session_id = s.sid
ORDER BY o.object_id, xidusn DESC;


-- Check the wait events
---- Attention the top wait events

COL event FOR a40;
COL time_waited FOR 999,999,999,999,999,999,999;

SELECT *
  FROM (  SELECT event, time_waited
            FROM v$system_event
        ORDER BY time_waited DESC)
 WHERE ROWNUM < 11;
 


-- Query which sql experience the wait
---- Attention the always appeared SQL

SET LINESIZE 200;
COL sql_text FOR a60;
COL event FOR a30;

  SELECT s.sql_text, sw.event
    FROM v$session b, v$session_wait sw, v$sqltext s
   WHERE     b.sid = sw.sid
         AND sw.event NOT LIKE '%SQL*Net%'
         AND sw.EVENT NOT LIKE 'rdbms%'
         AND s.hash_value = b.sql_hash_value
         AND s.sql_id = b.sql_id
ORDER BY s.address, s.piece;




-- Add from v0.1.8
-- Check Auto collect statistics
---- Check if the gather stats job is enabled
---- for 10g
SET LINESIZE 200;
COL JOB_ACTION FOR A20;

SELECT owner,
       job_name,
       job_action,
       enabled,
       state
  FROM dba_scheduler_jobs
 WHERE job_name = 'GATHER_STATS_JOB' OR job_name='BSLN_MAINTAIN_STATS_JOB';
 
---- for 11g
SELECT client_name, status FROM dba_autotask_client;

SET LINES 200;
COL window_name FOR a20;
COL client_name FOR a40;

SELECT client_name,
       window_name,
       jobs_created,
       jobs_started,
       jobs_completed
  FROM dba_autotask_client_history
 WHERE client_name LIKE '%stats%';
 
  

-- Add from v0.1.8
---- Check the latest gather stats job running status
---- for 10g
SET LINESIZE 200;
COL job_name FOR a20;
COL status FOR a15;
COL start_date FOR a25;
COL log_date FOR a25;

  SELECT log_id,
         job_name,
         status,
         TO_CHAR (actual_start_date, 'yyyy-mm-dd hh24:mi:ss') start_date,
         TO_CHAR (log_date, 'yyyy-mm-dd hh24:mi:ss') log_date
    FROM dba_scheduler_job_run_details
   WHERE job_name = 'GATHER_STATS_JOB'
ORDER BY 4;

----- for 11g




-- Add from v0.1.9
-- Check recyclebin 
show parameter recyclebin;

select count(*) from dba_recyclebin;


-- ########################################################
-- Part 2.6 Database RMAN Backup Information
-- ########################################################

-- Check Rman Backup info
SET LINESIZE 200;
COL device_type FOR a10;
COL handle FOR a20;
COL tag FOR a25;
COL comments FOR a15;
COL status FOR a6;
ALTER SESSION SET nls_date_format='yyyy-mm-dd hh24:mi:ss';

  SELECT bs_key,
         bp_key,
         device_type,
         handle,
         tag,
         deleted,
         status,
         start_time,
         completion_time,
         comments
    FROM v$backup_piece_details
ORDER BY start_time;

-- Add from v0.1.8
-- Recover file status
SELECT * FROM GV$RECOVERY_FILE_STATUS;


-- Add from v0.1.9
-- Check datafile scn and datafile status
SET LINES 200;
COL name FOR a45;
ALTER SESSION SET nls_date_format='yyyy-mm-dd hh24:mi:ss';

SELECT file#,
       name,
       block_size,
       creation_time,
       checkpoint_change#,
       checkpoint_time
  FROM v$datafile;
  

  
SET LINES 200;
COL file# FOR 9999;
COL fuzzy FOR a3;
COL name FOR a45;
ALTER SESSION SET nls_date_format='yyyy-mm-dd hh24:mi:ss';

SELECT file#,
       name,
       tablespace_name,
       status,
       error fuzzy,
       checkpoint_change#,
       checkpoint_time,
       resetlogs_change#,
       resetlogs_time
  FROM v$datafile_header;  
  
  
 


-- ########################################################
-- Part 2.7 Some Resource Info
-- ########################################################

-- Check the resource limits
SET LINESIZE 200;
COL resource_name FOR a25;

SELECT * FROM v$resource_limit;


-- Check history resource limit
  SELECT *
    FROM DBA_HIST_RESOURCE_LIMIT
ORDER BY snap_id;



-- ########################################################
-- Part 2.8 Security Info
-- ########################################################

-- Add from v0.1.7
-- Showing that which user has DBA role
COL grantee FOR a25;
COL granted_role FOR a25;

SELECT *
  FROM dba_role_privs
 WHERE granted_role = 'DBA';
 

-- Add from v0.1.7
-- The password file users, showing that the user has sysdba or sysoper role
COL username FOR a25;

SELECT * FROM v$pwfile_users;


-- Add from v0.1.7
-- DB audit or NOT
show parameter audit;


-- Add from v0.1.8
---- User and their profile and granted role
COL username FOR a15;
COL account_status FOR a20;
COL default_tablespace FOR a20;
COL temporary_tablespace FOR a22;
COL profile FOR a20;
COL granted_role FOR a25;
BREAK ON username SKIP 1 ON account_status ON default_tablespace ON temporary_tablespace ON profile;

  SELECT username,
         account_status,
         default_tablespace,
         temporary_tablespace,
         PROFILE,
         granted_role,
         admin_option,
         default_role
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
COLUMN profile          FORMAT A20      HEADING Profile
COLUMN resource_name                    HEADING 'Resource:'
COLUMN limit            FORMAT A15      HEADING Limit

  SELECT PROFILE, resource_name, LIMIT
    FROM sys.dba_profiles
ORDER BY PROFILE;



-- ########################################################
-- Part 2.9 Other Info
-- ########################################################

-- Add from v0.1.9
---- SCN header room check(indicator: day)

SELECT version,
       date_time,
       DBMS_FLASHBACK.get_system_change_number current_scn,
       INDICATOR
  FROM (SELECT version,
               TO_CHAR (SYSDATE, 'YYYY/MM/DD HH24:MI:SS') DATE_TIME,
               ROUND (
                  ( ( ( ( (  (TO_NUMBER (TO_CHAR (SYSDATE, 'YYYY')) - 1988)
                           * 12
                           * 31
                           * 24
                           * 60
                           * 60)
                         + (  (TO_NUMBER (TO_CHAR (SYSDATE, 'MM')) - 1)
                            * 31
                            * 24
                            * 60
                            * 60)
                         + (  ( (TO_NUMBER (TO_CHAR (SYSDATE, 'DD')) - 1))
                            * 24
                            * 60
                            * 60)
                         + (TO_NUMBER (TO_CHAR (SYSDATE, 'HH24')) * 60 * 60)
                         + (TO_NUMBER (TO_CHAR (SYSDATE, 'MI')) * 60)
                         + (TO_NUMBER (TO_CHAR (SYSDATE, 'SS'))))
                       * (16 * 1024))
                     - DBMS_FLASHBACK.get_system_change_number)
                   / (16 * 1024 * 60 * 60 * 24)),
                  2)
               || ' days'
                  INDICATOR
          FROM v$instance);
          
  
-- Add from v0.1.9
---- Check if the scn header room patch has apply and the hidden parameter(_external_scn_rejection_threshold_hours) values 24 hours.

SET LINESIZE 200;
COL name FOR a40;
COL value FOR a10;
COL description FOR a50;

SELECT a.ksppinm name, b.ksppstvl VALUE, a.ksppdesc description
  FROM x$ksppi a, x$ksppcv b
 WHERE a.indx = b.indx
       AND a.ksppinm = '_external_scn_rejection_threshold_hours';

  


-- #######################################################
-- Last Part: check CRS_STAT
-- #######################################################

-- Check if there is crs in RAC ( double check )
! crs_stat -t 
! crsctl stat res -t

#-- ##################################################################################

exit;
