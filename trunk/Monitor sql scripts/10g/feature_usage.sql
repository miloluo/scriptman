-- -----------------------------------------------------------------------------------
-- File Name    : http://www.oracle-base.com/dba/10g/feature_usage.sql
-- Author       : Tim Hall
-- Description  : Displays feature usage statistics.
-- Requirements : Access to the DBA views.
-- Call Syntax  : @feature_usage
-- Last Modified: 26-NOV-2004
-- -----------------------------------------------------------------------------------

COLUMN name  FORMAT A50
COLUMN detected_usages FORMAT 999999999999

SELECT u1.name,
       u1.detected_usages
FROM   dba_feature_usage_statistics u1
WHERE  u1.version = (SELECT MAX(u2.version)
                     FROM   dba_feature_usage_statistics u2
                     WHERE  u2.name = u1.name)
ORDER BY u1.name;

COLUMN FORMAT DEFAULT
