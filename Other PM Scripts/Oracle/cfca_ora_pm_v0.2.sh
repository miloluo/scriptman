
#############Need manually##############

#1. snapshot of report
#--statspack report
#SQL> execute statspack.snap;

#SQL> @ ?/rdbms/admin/spreport.sql


#2. Check datafile type
#SELECT name
#FROM   v$datafile;  

#ls -lrt <datafile_dir>

#3. Log check:
#tail alert.log
#tail listener.log


#######################################
echo "***********************************" > ora_result.txt
echo "* Check GSD status" >> ora_result.txt
echo "***********************************" >> ora_result.txt
gsdctl stat >> ora_result.txt

echo >> ora_result.txt
echo "***********************************" >> ora_result.txt
echo "* Check GSD status" >> ora_result.txt
echo "***********************************" >> ora_result.txt
srvctl status instance -d cfcacadb -i cfcacadb1, cfcacadb2 >> ora_result.txt

echo >> ora_result.txt
echo "***********************************" >> ora_result.txt
echo "* Now query will execute in sqlplus" >> ora_result.txt
echo "***********************************" >> ora_result.txt
echo >> ora_result.txt
sqlplus / as sysdba << EOF
spool ora_result.txt append;
PROMPT ************************************************
PROMPT * Check instance running status
PROMPT ************************************************
set linesize 120;
col inst_id for 999;
col instance_name for a15;
col host_name for a10;
col version for a10;
col startup_time for a20;
col status for a8;
col archiver for a10;
col database_status for a15;
SELECT inst_id,
       instance_name,
       host_name,
       VERSION,
       TO_CHAR(startup_time, 'yyyy-mm-dd hh24:mi:ss') startup_time,
       status,
       archiver,
       database_status
  FROM gv\$instance;


PROMPT ************************************************
PROMPT * Check DB version
PROMPT ************************************************
SELECT *
FROM   v\$version;  

PROMPT ************************************************
PROMPT * Check DB properties
PROMPT ************************************************
set linesize 120;
col property_name for a30;
col property_value for a40;
col description for a40;
SELECT *
FROM   database_properties; 


PROMPT ************************************************
PROMPT * Check DB option and feature
PROMPT ************************************************
set linesize 100;
col parameter for a40;
col value for a8;
SELECT *
FROM   v\$option; 

PROMPT ****************************************************
PROMPT * Check components are loaded in DB
PROMPT ** Check if all loaded component are valid 
PROMPT ** Normally, all component status should be "VALID"
PROMPT ****************************************************
col comp_name for a40;
SELECT comp_name,
       status 
FROM   dba_registry; 


PROMPT ************************************************
PROMPT * Check Total size of Datafile 
PROMPT ************************************************
col Total(GB) for 999999.999;
col Total(TB) for 999999.999;
SELECT ( d1 + d2 ) / 1024 / 1024 / 1024        "Total(GB)",
       ( d1 + d2 ) / 1024 / 1024 / 1024 / 1024 "Total(TB)"
FROM   (SELECT Sum(bytes) d1
        FROM   v\$datafile),
       (SELECT Sum(bytes) d2
        FROM   v\$tempfile); 


PROMPT ********************************************************
PROMPT * Check availabe space of each tablespace
PROMPT ** If the USE(%) > 85%, 
PROMPT ** then the tablespace should be consider to extented. 
PROMPT ********************************************************
set linesize 120;
col tablespace_name for a20;
SELECT D.TABLESPACE_NAME,
       SPACE "Total(M)",
       SPACE - NVL(FREE_SPACE, 0) "USED(M)",
       ROUND((1 - NVL(FREE_SPACE, 0) / SPACE) * 100, 2) "USED(%)",
       FREE_SPACE "FREE(M)"
  FROM (SELECT TABLESPACE_NAME,
               ROUND(SUM(BYTES) / (1024 * 1024), 2) SPACE,
               SUM(BLOCKS) BLOCKS
          FROM DBA_DATA_FILES
         GROUP BY TABLESPACE_NAME) D,
       (SELECT TABLESPACE_NAME,
               ROUND(SUM(BYTES) / (1024 * 1024), 2) FREE_SPACE
          FROM DBA_FREE_SPACE
         GROUP BY TABLESPACE_NAME) F
 WHERE D.TABLESPACE_NAME = F.TABLESPACE_NAME(+)
UNION ALL --if have tempfile
SELECT D.TABLESPACE_NAME,
       SPACE "Total(M)",
       USED_SPACE "USED(M)",
       ROUND(NVL(USED_SPACE, 0) / SPACE * 100, 2) "USED(%)",
       NVL(FREE_SPACE, 0) "FREE(M)"
  FROM (SELECT TABLESPACE_NAME,
               ROUND(SUM(BYTES) / (1024 * 1024), 2) SPACE,
               SUM(BLOCKS) BLOCKS
          FROM DBA_TEMP_FILES
         GROUP BY TABLESPACE_NAME) D,
       (SELECT TABLESPACE_NAME,
               ROUND(SUM(BYTES_USED) / (1024 * 1024), 2) USED_SPACE,
               ROUND(SUM(BYTES_FREE) / (1024 * 1024), 2) FREE_SPACE
          FROM V\$TEMP_SPACE_HEADER
         GROUP BY TABLESPACE_NAME) F
 WHERE D.TABLESPACE_NAME = F.TABLESPACE_NAME(+)
 ORDER BY 4;

PROMPT ***************************************************
PROMPT * Check datafile type along with ls -l check
PROMPT ***************************************************
SELECT name
FROM   v\$datafile;  

PROMPT ***************************************************
PROMPT * Check tables and indexes in system tablespace  
PROMPT * that NOT belong to SYS OR SYSTEM
PROMPT ** Check if there are many other objects,
PROMPT ** place in system tablespace, 
PROMPT ** if so, then performance might be affected
PROMPT ***************************************************
SELECT DISTINCT owner 
FROM   dba_tables
WHERE  tablespace_name = 'SYSTEM'
       AND owner NOT IN ('SYS', 'SYSTEM', 'MDSYS', 'OLAPSYS', 'OUTLN')
UNION
SELECT DISTINCT owner 
FROM   dba_indexes
WHERE  tablespace_name = 'SYSTEM'
       AND owner NOT IN ('SYS', 'SYSTEM', 'MDSYS', 'OLAPSYS', 'OUTLN') ; 


PROMPT ***************************************************
PROMPT * Check tablespace status
PROMPT ** Normal status should be "ONLINE"
PROMPT ***************************************************
SELECT tablespace_name,
       status
FROM   dba_tablespaces; 

PROMPT ************************************************************
PROMPT * Check IO status of each datafile
PROMPT ** To find out which datafile is in high write/read status
PROMPT ************************************************************
set linesize 100;
col file_name for a46
SELECT df.name                                          file_name,
       fs.phyrds                                        reads,
       fs.phywrts                                       writes,
       ( fs.readtim / Decode(fs.phyrds, 0, -1,
                                        fs.phyrds) )    readtime,
       ( fs.writetim / Decode(fs.phywrts, 0, -1,
                                          fs.phywrts) ) writetime
FROM   v\$datafile df,
       v\$filestat fs
WHERE  df.file# = fs.file#
ORDER  BY df.name; 


PROMPT ***************************************************
PROMPT * Check log file status
PROMPT ** Check basic info of redo log
PROMPT ** Status column may be the listed value:
PROMPT ** UNUSED, CURRENT, ACTIVE, INACTIVE,
PROMPT ** CLEARING, CLEARING_CURRENT,
PROMPT ***************************************************
col group# for 999999;
col member# for 999;
col "log file path" for a30;
col "MB" for 99999;
SELECT l.group#,
       l.members           AS "member#",
       lf.member           AS "log file path",
       bytes / 1024 / 1024 "MB",
       sequence#,
       l.status
FROM   v\$log l,
       v\$logfile lf
WHERE  l.group# = lf.group#
ORDER  BY group#,
          members;   


PROMPT ***************************************************
PROMPT * Check switch time of redo log
PROMPT ** Statistik the frequency,normally is close to 30mins
PROMPT ***************************************************
alter session set nls_date_format='yyyy-mm-dd hh24:mi:ss';
col thread# for 9999;
col sequence# for 999999;
SELECT thread#,
       sequence#,
       first_time
FROM   v\$log_history
ORDER  BY thread#, sequence#; 


PROMPT ***************************************************
PROMPT * Check controlfile status
PROMPT ***************************************************
set linesize 120;
col status for a10;
col name for a40;
col block_size for 99999;
col file_size_blks for 9999999;
SELECT *
FROM   v\$controlfile; 

PROMPT ***************************************************
PROMPT * Check if there is invalid objects
PROMPT ** Affirm the status of the objects
PROMPT ***************************************************
SELECT OWNER,
       OBJECT_NAME,
       OBJECT_TYPE
FROM   DBA_OBJECTS
WHERE  STATUS = 'INVALID'; 

PROMPT ***************************************************
PROMPT * Check if there is unusable indexes
PROMPT ** Affirm the use of the indexes
PROMPT ***************************************************
SELECT OWNER,
       INDEX_NAME,
       INDEX_TYPE,
       TABLE_NAME,
       STATUS
FROM   DBA_INDEXES
WHERE  STATUS = 'UNUSABLE'; 

PROMPT ***************************************************
PROMPT * Unindexed tables
PROMPT ** Only a check for necessary index creation
PROMPT ***************************************************
set linesize 80;
col owner for a10;
col segment_name for a30;
col segment_type for a10;
col tablespace_name for a15;
col size_mb for 9999999;
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
    AND t.owner NOT IN ('SYS', 'SYSTEM', 'SCOTT')
ORDER BY 5 DESC;


PROMPT ***************************************************
PROMPT * Check if there have disabled constraints
PROMPT ** Enable the disabled constraints
PROMPT ***************************************************
set linesize 100;
col owner for a20;
SELECT OWNER,
       CONSTRAINT_NAME,
       CONSTRAINT_TYPE,
       TABLE_NAME
FROM   DBA_CONSTRAINTS
WHERE  STATUS = 'DISABLED'; 


PROMPT ***************************************************
PROMPT * Check if there have disabled triggers
PROMPT ** Recompile the disabled triggers
PROMPT ***************************************************
col owner for a20;
SELECT OWNER,
       TRIGGER_NAME,
       TRIGGER_TYPE
FROM   DBA_TRIGGERS
WHERE  STATUS = 'DISABLED'; 


PROMPT ***************************************************
PROMPT * Check active Session Count
PROMPT ** Monitor the workload
PROMPT ***************************************************
SELECT Count(1) "ACTIVE Session Count"
FROM   v\$session
WHERE  status = 'ACTIVE'
       AND username NOT IN ( 'SYS', 'SYSTEM' ); 


PROMPT ***************************************************
PROMPT * Check Buffer Cache hit ratio
PROMPT ** This value should greater than 95%
PROMPT ***************************************************

SELECT (1 - (SUM(DECODE(NAME, 'physical reads', VALUE, 0)) /
       (SUM(DECODE(NAME, 'db block gets', VALUE, 0)) +
       SUM(DECODE(NAME, 'consistent gets', VALUE, 0))))) * 100 "Buffer Cache Hit Ratio(%)"
FROM V\$SYSSTAT;


PROMPT ***************************************************
PROMPT * Check Sorting Efficiency - Memory Sorting(%)
PROMPT ** This value should greater than 95%
PROMPT ***************************************************
SELECT a.VALUE        "Disk Sorting",
       b.VALUE        "Memory Sorting",
       ROUND(( 100 * b.VALUE ) / DECODE(( a.VALUE + b.VALUE ), 0, 1,
       ( a.VALUE + b.VALUE )), 2) "Memory Sorting (%)"
FROM   v\$sysstat a,
       v\$sysstat b
WHERE  a.name = 'sorts (disk)'
       AND b.name = 'sorts (memory)';



PROMPT ***************************************************
PROMPT * Check Redo Log Hit Ratio
PROMPT ** This value should greater than 95%
PROMPT ***************************************************
col name for a20;
col gets for 999999;
col misses for 99999;
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
FROM   v\$latch
WHERE  name IN ( 'redo allocation', 'redo copy' ); 


PROMPT ***************************************************
PROMPT * Check Dictionary Hit Ratio
PROMPT ** This value should greater than 95%
PROMPT ***************************************************
SELECT ROUND(( 1 - ( Sum(GETMISSES) / Sum(GETS) ) ), 2) * 100 "Dictionary Hit Ratio(%)"
FROM   V\$ROWCACHE;


PROMPT ***************************************************
PROMPT * Check Labrary Cache Hit Ratio
PROMPT ** This value should greater than 95%
PROMPT ***************************************************
SELECT ROUND(SUM(PINS) / (SUM(PINS) + SUM(RELOADS)), 2) * 100 "Labrary Cache Hit Ratio(%)"
FROM V\$LIBRARYCACHE;


PROMPT ***************************************************
PROMPT * Check if there lock exists
PROMPT ** Attention the lock rows last long time
PROMPT ***************************************************
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
FROM   gv\$locked_object l,
       dba_objects o,
       gv\$session s
WHERE  l.object_id = o.object_id
       AND l.session_id = s.sid
ORDER  BY o.object_id,
          xidusn DESC; 



PROMPT ***************************************************
PROMPT * Check the wait events
PROMPT ** Attention the top wait events
PROMPT ***************************************************
col event for a40;
col time_waited for 99999999999999999999;
SELECT *
FROM   (SELECT event,
               time_waited
        FROM   v\$system_event
        ORDER  BY time_waited DESC)
WHERE  rownum < 11;  


PROMPT ***************************************************
PROMPT * Query which sql cause the wait
PROMPT ** Attention the always appeared SQL
PROMPT ***************************************************
set linesize 120;
col sql_text for a60;
col event for a30;
select s.sql_text, sw.event 
from v\$session b,v\$session_wait sw,v\$sqltext s 
where b.sid=sw.sid 
	and sw.event not like '%SQL*Net%' 
	and sw.EVENT NOT LIKE 'rdbms%' 
	and s.hash_value=b.sql_hash_value 
	and s.sql_id=b.sql_id 
order by s.address,s.piece;


PROMPT ***************************************************
PROMPT * Check which new feature has been enabled
PROMPT ** This section displays the summary of Usage for Database Features.
PROMPT ** The Currently Used column is TRUE if usage was detected for the feature at the last sample time.
PROMPT ***************************************************
SELECT output
FROM   TABLE(dbms_feature_usage_report.display_text); 

spool off
exit;
EOF

