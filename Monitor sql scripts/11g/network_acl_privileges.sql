-- -----------------------------------------------------------------------------------
-- File Name    : http://www.oracle-base.com/dba/11g/network_acl_privileges.sql
-- Author       : Tim Hall
-- Description  : Displays privileges for the network ACLs.
-- Requirements : Access to the DBA views.
-- Call Syntax  : @network_acl_privileges
-- Last Modified: 30/11/2011
-- -----------------------------------------------------------------------------------
COLUMN acl FORMAT A30
COLUMN principal FORMAT A30

SELECT acl,
       principal,
       privilege,
       is_grant,
       TO_CHAR(start_date, 'DD-MON-YYYY') AS start_date,
       TO_CHAR(end_date, 'DD-MON-YYYY') AS end_date
FROM   dba_network_acl_privileges;