-- -----------------------------------------------------------------------------------
-- File Name    : http://www.oracle-base.com/dba/10g/jobs.sql
-- Author       : Tim Hall
-- Description  : Displays scheduler job information.
-- Requirements : Access to the DBA views.
-- Call Syntax  : @jobs
-- Last Modified: 27/07/2005
-- -----------------------------------------------------------------------------------
SET LINESIZE 200

COLUMN owner FORMAT A20
COLUMN next_run_date FORMAT A35

SELECT owner,
       job_name,
       enabled,
       job_class,
       next_run_date
FROM   dba_scheduler_jobs
ORDER BY owner, job_name;