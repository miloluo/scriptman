REM tablespace report

set linesize 200

select a.tablespace_name,
       round(a.bytes_alloc / 1024 / 1024) megs_alloc,
       round(nvl(b.bytes_free, 0) / 1024 / 1024) megs_free,
       round((a.bytes_alloc - nvl(b.bytes_free, 0)) / 1024 / 1024) megs_used,
       round((nvl(b.bytes_free, 0) / a.bytes_alloc) * 100) Pct_Free,
       100 - round((nvl(b.bytes_free, 0) / a.bytes_alloc) * 100) Pct_used,
       round(maxbytes / 1048576) Max
  from (select f.tablespace_name,
               sum(f.bytes) bytes_alloc,
               sum(decode(f.autoextensible, 'YES', f.maxbytes, 'NO', f.bytes)) maxbytes
          from dba_data_files f
         group by tablespace_name) a,
       (select f.tablespace_name, sum(f.bytes) bytes_free
          from dba_free_space f
         group by tablespace_name) b
 where a.tablespace_name = b.tablespace_name(+)
union all
select h.tablespace_name,
       round(sum(h.bytes_free + h.bytes_used) / 1048576) megs_alloc,
       round(sum((h.bytes_free + h.bytes_used) - nvl(p.bytes_used, 0)) /
             1048576) megs_free,
       round(sum(nvl(p.bytes_used, 0)) / 1048576) megs_used,
       round((sum((h.bytes_free + h.bytes_used) - nvl(p.bytes_used, 0)) /
             sum(h.bytes_used + h.bytes_free)) * 100) Pct_Free,
       100 -
       round((sum((h.bytes_free + h.bytes_used) - nvl(p.bytes_used, 0)) /
             sum(h.bytes_used + h.bytes_free)) * 100) pct_used,
       round(sum(f.maxbytes) / 1048576) max
  from sys.v_$TEMP_SPACE_HEADER h,
       sys.v_$Temp_extent_pool  p,
       dba_temp_files           f
 where p.file_id(+) = h.file_id
   and p.tablespace_name(+) = h.tablespace_name
   and f.file_id = h.file_id
   and f.tablespace_name = h.tablespace_name
 group by h.tablespace_name
 ORDER BY 1
/

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

ttitle -
   center  'Database Freespace Summary'  skip 2 

comp sum of nfrags totsiz avasiz on report
break on report 

set pages 999
col tsname  format     a16 justify c heading 'Tablespace'
col nfrags  format 999,990 justify c heading 'Free|Frags'
col mxfrag  format 999,999 justify c heading 'Largest|Frag (MB)'
col totsiz  format 999,999 justify c heading 'Total|(MB)'
col avasiz  format 999,999 justify c heading 'Available|(MB)'
col pctusd  format     990 justify c heading 'Pct|Used' 

select total.TABLESPACE_NAME tsname,
       D nfrags,
       C/1024/1024 mxfrag,
       A/1024/1024 totsiz,
       B/1024/1024 avasiz,
       (1-nvl(B,0)/A)*100 pctusd
from
    (select sum(bytes) A,
            tablespace_name
            from dba_data_files
            group by tablespace_name) TOTAL,
    (select sum(bytes) B,
            max(bytes) C,
            count(bytes) D,
            tablespace_name
            from dba_free_space
            group by tablespace_name) FREE
where
      total.TABLESPACE_NAME=free.TABLESPACE_NAME(+)
/

SELECT t.tablespace_name,
       CASE
         WHEN t.contents = 'TEMPORARY' AND t.extent_management = 'LOCAL' THEN
          u.bytes
         ELSE
          df.user_bytes - NVL(fs.bytes, 0)
       END / 1024 / 1024 used_mb,
       CASE
         WHEN t.contents = 'TEMPORARY' AND t.extent_management = 'LOCAL' THEN
          df.user_bytes - NVL(u.bytes, 0)
         ELSE
          NVL(fs.bytes, 0)
       END / 1024 / 1024 free_mb,
       fs.min_fragment / 1024 / 1024 min_fragment_mb,
       fs.max_fragment / 1024 / 1024 max_fragment_mb,
       (fs.bytes / 1024 / 1024) / fs.fragments avg_fragment_mb,
       fs.fragments,
       t.status,
       t.contents,
       t.logging,
       t.extent_management,
       t.allocation_type,
       t.force_logging,
       t.segment_space_management,
       t.def_tab_compression,
       t.retention,
       t.bigfile
  FROM dba_tablespaces t,
       (SELECT tablespace_name,
               SUM(bytes) bytes,
               MIN(min_fragment) min_fragment,
               MAX(max_fragment) max_fragment,
               SUM(fragments) fragments
          FROM (SELECT tablespace_name,
                       SUM(bytes) bytes,
                       MIN(bytes) min_fragment,
                       MAX(bytes) max_fragment,
                       COUNT(*) fragments
                  FROM dba_free_space
                 GROUP BY tablespace_name
                UNION ALL
                SELECT tablespace_name,
                       SUM(bytes) bytes,
                       MIN(bytes) min_fragment,
                       MAX(bytes) max_fragment,
                       COUNT(*) fragments
                  FROM dba_undo_extents
                 WHERE status = 'EXPIRED'
                 GROUP BY tablespace_name)
         GROUP BY tablespace_name) fs,
       (SELECT tablespace_name, SUM(user_bytes) user_bytes
          FROM dba_data_files
         GROUP BY tablespace_name
        UNION ALL
        SELECT tablespace_name, SUM(user_bytes) user_bytes
          FROM dba_temp_files
         GROUP BY tablespace_name) df,
       (SELECT tablespace_name, SUM(bytes_used) bytes
          FROM gv$temp_extent_pool
         GROUP BY tablespace_name) u
 WHERE t.tablespace_name = df.tablespace_name(+)
   AND t.tablespace_name = fs.tablespace_name(+)
   AND t.tablespace_name = u.tablespace_name(+)
/