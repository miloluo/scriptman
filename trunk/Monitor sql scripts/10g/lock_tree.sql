-- -----------------------------------------------------------------------------------
-- File Name    : http://www.oracle-base.com/dba/10g/lock_tree.sql
-- Author       : Tim Hall
-- Description  : Displays information on all database sessions with the username
--                column displayed as a heirarchy if locks are present.
-- Requirements : Access to the V$ views.
-- Call Syntax  : @lock_tree
-- Last Modified: 18-MAY-2005
-- -----------------------------------------------------------------------------------
SET LINESIZE 500
SET PAGESIZE 1000

COLUMN username FORMAT A15
COLUMN machine FORMAT A25
COLUMN logon_time FORMAT A20

SELECT LPAD(' ', (level-1)*2, ' ') || NVL(s.username, '(oracle)') AS username,
       s.osuser,
       s.sid,
       s.serial#,
       s.lockwait,
       s.status,
       s.module,
       s.machine,
       s.program,
       TO_CHAR(s.logon_Time,'DD-MON-YYYY HH24:MI:SS') AS logon_time
FROM   v$session s
CONNECT BY PRIOR s.sid = s.blocking_session
START WITH s.blocking_session IS NULL;

SET PAGESIZE 14
