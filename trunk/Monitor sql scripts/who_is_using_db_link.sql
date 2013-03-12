
-----------------------
-- works for 9i above
-----------------------


set linesize 200;
col username for a15;
col ORIGIN for a20;
col GTXID for a40;
col LSESSION for a20;
col WAITING for a20;
col s for a10;
select /*+ ORDERED */
 substr(s.ksusemnm, 1, 10) || '-' || substr(s.ksusepid, 1, 10) "ORIGIN",
 substr(g.K2GTITID_ORA, 1, 35) "GTXID",
 substr(s.indx, 1, 4) || '.' || substr(s.ksuseser, 1, 5) "LSESSION",
 s2.username,
 substr(decode(bitand(ksuseidl, 11),
               1,
               'ACTIVE',
               0,
               decode(bitand(ksuseflg, 4096), 0, 'INACTIVE', 'CACHED'),
               2,
               'SNIPED',
               3,
               'SNIPED',
               'KILLED'),
        1,
        1) "S",
 substr(w.event, 1, 20) "WAITING"
  from x$k2gte g, x$ktcxb t, x$ksuse s, v$session_wait w, v$session s2
 where g.K2GTDXCB = t.ktcxbxba
   and g.K2GTDSES = t.ktcxbses
   and s.addr = g.K2GTDSES
   and w.sid = s.indx
   and s2.sid = w.sid;
   
  
  
----------------------------
-- works for 10g above
----------------------------   
set linesize 200;
col username for a15;
col ORIGIN for a20;
col GTXID for a40;
col LSESSION for a20;
col WAITING for a20;
col s for a10;   
select /*+ ORDERED */
substr(s.ksusemnm,1,10)||'-'|| substr(s.ksusepid,1,10) "ORIGIN",
substr(g.K2GTITID_ORA,1,35) "GTXID",
substr(s.indx,1,4)||'.'|| substr(s.ksuseser,1,5) "LSESSION" ,
s2.username,
substr(
decode(bitand(ksuseidl,11),
1,'ACTIVE',
0, decode( bitand(ksuseflg,4096) , 0,'INACTIVE','CACHED'),
2,'SNIPED',
3,'SNIPED',
'KILLED'
),1,1
) "S",
substr(s2.event,1,10) "WAITING"
from x$k2gte g, x$ktcxb t, x$ksuse s, v$session s2
where g.K2GTDXCB =t.ktcxbxba
and g.K2GTDSES=t.ktcxbses
and s.addr=g.K2GTDSES
and s2.sid=s.indx;