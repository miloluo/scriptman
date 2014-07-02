select tablespace_name,current_users,total_blocks,used_blocks,free_blocks from v$sort_segment;

SET LINES 140
col username FOR a10
col osuser FOR a15
col sql_text FOR a70
col tablespace_name FOR a10
SELECT a.username,
        a.sid,
        a.serial#,
        a.osuser,
        a.machine,
        b.tablespace,
        b.blocks,
        c.sql_text
  FROM v$session a, v$tempseg_usage b, v$sqlarea c
WHERE a.saddr = b.session_addr
    AND c.address = a.sql_address
    AND c.hash_value = a.sql_hash_value
  ORDER BY b.tablespace, b.blocks
/



-- 查询谁在使用temp
set lines 200;
col username for a15;
SELECT SE.USERNAME,
       SE.SID,
       SE.SERIAL#,
       SU.EXTENTS,
       SU.BLOCKS * TO_NUMBER(RTRIM(P.VALUE)) AS SPACE,
       TABLESPACE,
       SEGTYPE,
       SQL_TEXT
  FROM V$SORT_USAGE SU, V$PARAMETER P, V$SESSION SE, V$SQL S
WHERE P.NAME = 'db_block_size'
   AND SU.SESSION_ADDR = SE.SADDR
   AND S.ADDRESS = SU.SQLADDR;


SELECT * FROM GV$PX_SESSION WHERE QCSID IN(SELECT QCSID FROM GV$PX_SESSION WHERE SID=165);


REM SORT ACTIVITY

set linesize 150 pagesize 1400;

    SELECT d.tablespace_name "Name", 
                TO_CHAR(NVL(a.bytes / 1024 / 1024, 0),'99,999,990.900') "Size (M)", 
                TO_CHAR(NVL(t.hwm, 0)/1024/1024,'99999999.999')  "HWM (M)",
                TO_CHAR(NVL(t.hwm / a.bytes * 100, 0), '990.00') "HWM % " ,
                TO_CHAR(NVL(t.bytes/1024/1024, 0),'99999999.999') "Using (M)", 
                TO_CHAR(NVL(t.bytes / a.bytes * 100, 0), '990.00') "Using %" 
           FROM sys.dba_tablespaces d, 
                (select tablespace_name, sum(bytes) bytes from dba_temp_files group by tablespace_name) a,
                (select tablespace_name, sum(bytes_cached) hwm, sum(bytes_used) bytes from v$temp_extent_pool group by tablespace_name) t
          WHERE d.tablespace_name = a.tablespace_name(+) 
            AND d.tablespace_name = t.tablespace_name(+) 
            AND d.extent_management like 'LOCAL' 
            AND d.contents like 'TEMPORARY'
/

alter session set nls_date_format='dd-mon-yy';
set lines 160 pages 1000 echo off feedback off
col stat_name for a25
col date_time for a40
col BEGIN_INTERVAL_TIME for a20
col END_INTERVAL_TIME for a20
prompt "Enter the date in DD-Mon-YY Format and Stats you want to trend like 'redo size','physical reads','physical writes','session logical reads' etc."

WITH sysstat AS
(select sn.begin_interval_time begin_interval_time,
         sn.end_interval_time end_interval_time,
         ss.stat_name stat_name,
         ss.value e_value,
         lag(ss.value, 1) over(order by ss.snap_id) b_value
    from dba_hist_sysstat ss, dba_hist_snapshot sn
   where trunc(sn.begin_interval_time) >= sysdate-7
     and ss.snap_id = sn.snap_id
     and ss.dbid = sn.dbid
     and ss.instance_number = sn.instance_number
     and ss.dbid = (select dbid from v$database)
     and ss.instance_number = (select instance_number from v$instance)
     and ss.stat_name = 'sorts (disk)')
select to_char(BEGIN_INTERVAL_TIME, 'mm/dd/yy_hh24_mi') || to_char(END_INTERVAL_TIME, '_hh24_mi') date_time,
stat_name,
round((e_value - nvl(b_value,0)) / (extract(day from(end_interval_time - begin_interval_time)) * 24 * 60 * 60
+ extract(hour from(end_interval_time - begin_interval_time)) * 60 * 60
+ extract(minute from(end_interval_time - begin_interval_time)) * 60 + extract(second from(end_interval_time - begin_interval_time))),0) per_sec
from sysstat where(e_value - nvl(b_value,0)) > 0 and nvl(b_value,0) > 0
/

select temp_space/1024/1024,SQL_ID  from DBA_HIST_SQL_PLAN where temp_space>0 order by 1 asc;