
set linesize 200;
col sid_ser# for a20;
col username for a15;
col program for a40;
col machine for a40;
select s.sid || ',' ||s.serial# as sid_ser#,p.spid as ospid, s.username, s.machine, s.program
from v$session s, v$process p
where p.addr=s.paddr and s.sid = &sid; 