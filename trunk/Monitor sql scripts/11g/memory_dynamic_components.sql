-- -----------------------------------------------------------------------------------
-- File Name    : http://www.oracle-base.com/dba/11g/memory_dynamic_components.sql
-- Author       : Tim Hall
-- Description  : Provides information about dynamic memory components.
-- Requirements : Access to the v$ views.
-- Call Syntax  : @memory_dynamic_components
-- Last Modified: 23/08/2008
-- -----------------------------------------------------------------------------------
COLUMN component FORMAT A30

SELECT  component, current_size, min_size, max_size
FROM    v$memory_dynamic_components
WHERE   current_size != 0;