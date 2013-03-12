-- -----------------------------------------------------------------------------------
-- File Name    : http://www.oracle-base.com/dba/10g/jobs_running.sql
-- Author       : Tim Hall
-- Description  : Displays scheduler information for running jobs.
-- Requirements : Access to the DBA views.
-- Call Syntax  : @jobs_running
-- Last Modified: 27/07/2005
-- -----------------------------------------------------------------------------------
SET LINESIZE 200

COLUMN owner FORMAT A20

SELECT owner,
       job_name,
       running_instance,
       elapsed_time
FROM   dba_scheduler_running_jobs
ORDER BY owner, job_name;