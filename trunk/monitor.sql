
-- 会话中等待时间的查询
select s.sid,s.seq#, s.username, s.machine, s.program, sw.event, sw.p1text,sw.p1,sw.p2text,sw.p2,sw.p3text,sw.p3
from v$session_wait sw, v$session s
where 
--sid between &1 and &2 and 
sw.SID = s.SID and 
s.username is not null and
sw.event not like '%SQL%'and 
sw.event not like '%rdbms%';


--查询锁,有缩进代表锁等待的session
set linesize 200;
col user_name for a20;
col owner for a15;
col object_name for a30;
col object_type for a15;
col sid for 99999;
col serial# for 99999;

select lpad(' ', decode(l.xidusn, 0, 3, 0)) || l.oracle_username user_name,
       o.owner, o.object_name, o.object_type, s.sid, s.serial#
from   v$locked_object l, dba_objects o, v$session s
where l.object_id=o.object_id and l.session_id=s.sid
order by o.object_id, xidusn desc;




