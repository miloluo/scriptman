--#!/bin/bash
--##############################
--## Modify at Feb 12th, 2012 ##
--## By Milo Luo              ##
--##############################


--For Aix
-------------------------------
--prtconf
--bindprocessor -q
--oslevel
--lsps -s
--lsfs 
--df -k
--ps -ef | grep smon
--uname -a
--topas
-------------------------------


spool check_pm_result.txt

-- set linesize
set linesize 120;

-- check instance name
prompt *********************************
prompt check instance name and status
prompt *********************************

show parameter name;

prompt ******************
col host_name for a30;
select inst_id, instance_number, instance_name, host_name, status from gv$instance;

-- check service name
prompt *****************************
prompt check service name
prompt *****************************
show parameter service

-- check rdbms version
prompt
prompt *****************************
prompt check rdbms version
prompt *****************************
select * from v$version;

-- check total datafile size
prompt
prompt *****************************
prompt check total datafile size
prompt *****************************
col Total(GB) for 999999.999;
col Total(TB) for 999999.999;
select (d1+d2)/1024/1024/1024 "Total(GB)", (d1+d2)/1024/1024/1024/1024 "Total(TB)"  from 
(select sum(bytes) d1 from v$datafile ) , 
(select sum(bytes) d2 from v$tempfile);



-- check the datafile type
prompt *****************************
prompt check the datafile type
prompt *****************************
col tbs_name for a20;
col df_name for a50;
select ts.name tbs_name, t.name df_name from v$tablespace ts,
(select ts#, name from v$datafile
union all 
select ts#, name from v$tempfile) t
where t.ts# = ts.ts#;



-- check  block size and block buffer
prompt *****************************
prompt check block size
prompt *****************************
show parameter block



-- Query sga auto resize action (Avaiable for 10g and above)
set linesize 120;
column component format a20;
column parameter format a20;

alter session set nls_date_format='yyyy-mm-dd hh24:mi:ss';
select  * from v$sga_resize_ops;


-- Check sga basic info (Avaliable for 9i and above)
show sga;

-- Check sga and pga info (Avaliable for 9i and above)
show parameter ga;

show parameter size;


-- check share pool size
prompt *****************************
prompt check share pool size
prompt *****************************
set linesize 100;
show parameter shared; 

set linesize 120;
-- check the datafile number
prompt
prompt *****************************
prompt check datafile number
prompt *****************************
select count(name) datafile_cnt from  
(select name from v$datafile
 union
select name from v$tempfile);


-- check tablespace numbers
prompt *****************************
prompt check tablespaces number
prompt *****************************
select count(*) from dba_tablespaces;



-- check tablespace size
prompt
prompt *****************************
prompt check tablespace size
prompt *****************************
set linesize 120;
SELECT D.TABLESPACE_NAME,SPACE "Total(M)", SPACE-NVL(FREE_SPACE,0) "USED(M)",
ROUND((1-NVL(FREE_SPACE,0)/SPACE)*100,2) "USED(%)",FREE_SPACE "FREE(M)"
FROM
(SELECT TABLESPACE_NAME,ROUND(SUM(BYTES)/(1024*1024),2) SPACE,SUM(BLOCKS) BLOCKS
FROM DBA_DATA_FILES
GROUP BY TABLESPACE_NAME) D,
(SELECT TABLESPACE_NAME,ROUND(SUM(BYTES)/(1024*1024),2) FREE_SPACE
FROM DBA_FREE_SPACE
GROUP BY TABLESPACE_NAME) F
WHERE  D.TABLESPACE_NAME = F.TABLESPACE_NAME(+)
UNION ALL  --if have tempfile
SELECT D.TABLESPACE_NAME,SPACE "Total(M)",
USED_SPACE "USED(M)",ROUND(NVL(USED_SPACE,0)/SPACE*100,2) "USED(%)",
NVL(FREE_SPACE,0) "FREE(M)"
FROM
(SELECT TABLESPACE_NAME,ROUND(SUM(BYTES)/(1024*1024),2) SPACE,SUM(BLOCKS) BLOCKS
FROM DBA_TEMP_FILES
GROUP BY TABLESPACE_NAME) D,
(SELECT TABLESPACE_NAME,ROUND(SUM(BYTES_USED)/(1024*1024),2) USED_SPACE,
ROUND(SUM(BYTES_FREE)/(1024*1024),2) FREE_SPACE
FROM V$TEMP_SPACE_HEADER
GROUP BY TABLESPACE_NAME) F
WHERE  D.TABLESPACE_NAME = F.TABLESPACE_NAME(+)
--sorted by used percentage
ORDER BY 4;



-- check if the tablespace is on raw device
-- /dev/xxx ==> raw
-- /dirname/ ==> fs
-- +dg ==> asm ==> raw
-- check if the tablespace is on raw device
-- check if the tablespace are extented
prompt ***********************************
prompt check if the datafile is extented
prompt ***********************************
col tablespace_name for a20;
col file_name for a45;
col autoextensible for a3;
SELECT TABLESPACE_NAME, FILE_NAME, AUTOEXTENSIBLE FROM DBA_DATA_FILES ORDER BY 1;


-- check temp space
prompt *****************************
prompt check temp tablespace size
prompt *****************************
select tablespace_name, (sum(bytes_used)+sum(bytes_free))/1048576 "Total space(MB)",
sum(bytes_used)/1048576 "Used(MB)",  sum(bytes_free)/1048576 "Free(MB)", 
sum(bytes_used)/(sum(bytes_used)+sum(bytes_free))*100 "Used rate(%)" 
from v$temp_space_header
group by tablespace_name ;


-- check default temp space
prompt *****************************
prompt check default temp tablespace 
prompt *****************************
col property_name for a30;
col property_value for a30;
col description for a30;
set linesize 120;
select * from database_properties where property_name like '%TEMP%';

prompt ***************
col username for a20;
col account_status for a20;
col default_tablespace for a20;
col temporary_tablespace for a20;
select username, account_status, default_tablespace, temporary_tablespace from dba_users;


-- check if the db is in archive log mode
prompt *****************************
prompt check archive log mode
prompt *****************************
archive log list;

-- check if log file status
prompt *****************************
prompt check log file
prompt *****************************
-- check logfile location
set linesize 120;
col member for a30;
select * from v$logfile;


-- check logfile size and status
select group#, sequence#, bytes/1024/1024 "MB", status from v$log;


-- Non-default init parameters. 

column name format a30 tru 
column value format a48 wra 
select name, value 
from v$parameter 
where isdefault = 'FALSE';

-- check crs_stat if there is any
! crs_stat -t -v 


 
spool off;



