SET VERIFY OFF
SET LINESIZE 255
COL SID FORMAT 999
COL STATUS FORMAT A8
COL PROCESS FORMAT A10
COL SCHEMANAME FORMAT A16
COL OSUSER  FORMAT A16
COL SQL_TEXT FORMAT A120 HEADING 'SQL QUERY'
COL PROGRAM FORMAT A30

SELECT s.sid,
       s.status,
       s.process,
       s.schemaname,
       a.sql_id,
       a.sql_text,
       p.program
FROM   v$session s,
       v$sqlarea a,
       v$process p
WHERE  s.SQL_HASH_VALUE = a.HASH_VALUE
AND    s.SQL_ADDRESS = a.ADDRESS
AND    s.PADDR = p.ADDR and s.sid=&sid
/

SET VERIFY ON
SET LINESIZE 255
