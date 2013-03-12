-- ##################################################################################

-- Script Name: Automatic Generate AWR Report Script

-- ################################################################################## 

-- Purpose: This script is used to automatic generate AWR report every day
-- Created by: Jialin.Lee
-- Date: 2012-11-27
-- ##################################################################################



---- Basic setting
conn / as sysdba;
set echo off;
set veri off;
set feedback off;
set termout on;
set heading off;

---- Enable ADDM
variable rpt_options number;
define NO_OPTIONS = 0;
define ENABLE_ADDM = 8;

---- According to your needs, the report type can be 'text' or 'html'
define report_type='html';
begin
:rpt_options := &NO_OPTIONS;
end;

---- Generate begin_snap, end_snap, dbis, datetime and instance_number
/ 
variable dbid number;
variable inst_num number;
variable bid number;
variable eid number;
begin 
select max(snap_id)-4 into :bid from dba_hist_snapshot;
select max(snap_id)-3 into :eid from dba_hist_snapshot;
select dbid into :dbid from v$database;
select instance_number into :inst_num from v$instance;
end;
/

---- According to your needs, the report type can be 'text' or 'html'
column ext new_value ext noprint
column fn_name new_value fn_name noprint;
column lnsz new_value lnsz noprint;
--select 'text' ext from dual where lower('&report_type') = 'text';
select 'html' ext from dual where lower('&report_type') = 'html';
--select 'awr_report_text' fn_name from dual where lower('&report_type') = 'text';
select 'awr_report_html' fn_name from dual where lower('&report_type') = 'html';
--select '80' lnsz from dual where lower('&report_type') = 'text';
select '1500' lnsz from dual where lower('&report_type') = 'html';
set linesize &lnsz;

---- Print the AWR results into the report_name file using the spool command
column report_name new_value report_name noprint;
select (select instance_name from v$instance)||'_'||(select sysdate from dual)||'_'||'awr'||'.'||'&ext' report_name from dual;
set termout off;
spool &report_name;
select output from table(dbms_workload_repository.&fn_name(:dbid, :inst_num,:bid, :eid,:rpt_options ));
spool off;
set termout on;
clear columns sql;
ttitle off;
btitle off;
repfooter off;
undefine report_name
undefine report_type
undefine fn_name
undefine lnsz
undefine NO_OPTIONS
exit
