
set linesize 200;
col sid for 999999;
col seq# for 99999999;
col username for a15;
col machine for a15;
col program for a20;
col event for a30;
col p1text for a10;
col p2text for a10;
col p3text for a10;
select s.sid,s.seq#, s.username, sw.event, s.machine, s.program,  sw.p1text,sw.p1,sw.p2text,sw.p2,sw.p3text,sw.p3
from v$session_wait sw, v$session s
where sw.SID = s.SID and
      s.username is not null and
      sw.event not like '%SQL%'and
      sw.event not like '%rdbms%'
      order by event;
      

set linesize 200;
col event for a30;      
select inst_id, sid, serial#, program, event, p1, p2, p3, count(*) from  gv$session s
where
event not like '%SQL%'and event not like '%rdbms%' and state='WAITING'
group by inst_id, sid, serial#, program, event, p1, p2,p3
order by event,inst_id
/


set linesize 200;
col SAMPLE_TIME for a20;
alter session set nls_date_format='yyyy-mm-dd hh24:mi:ss';
select sample_time, sql_id, event, current_obj#
  from gv$active_session_history
where sample_time between
       to_date('01-FEB-2013 00:10:00', 'DD-MON-YYYY HH24:MI:SS') and
       to_date('01-FEB-2013 01:40:00', 'DD-MON-YYYY HH24:MI:SS')
   and event like '%row cache%' 
group by sample_time, sql_id, event, current_obj#
order by sample_time, sql_id;


select current_obj#, sql_id, event, count(1) cnt
  from gv$active_session_history
where sample_time between
       to_date('01-FEB-2013 00:10:00', 'DD-MON-YYYY HH24:MI:SS') and
       to_date('01-FEB-2013 01:30:00', 'DD-MON-YYYY HH24:MI:SS')
   --and event like '%row cache%' 
group by sql_id, event, current_obj#
order by current_obj#, cnt desc, sql_id;

    
    
    
SELECT s.sid,
       s.status,
       s.process,
       s.schemaname,
       s.osuser,
       a.sql_id,
       a.sql_text,
       p.program
FROM   v$session s,
       v$sqlarea a,
       v$process p
WHERE  s.SQL_HASH_VALUE = a.HASH_VALUE
AND    s.SQL_ADDRESS = a.ADDRESS
AND    s.PADDR = p.ADDR
and    s.sid =&sid;
/  





