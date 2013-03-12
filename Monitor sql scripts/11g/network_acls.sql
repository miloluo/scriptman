-- -----------------------------------------------------------------------------------
-- File Name    : http://www.oracle-base.com/dba/11g/network_acls.sql
-- Author       : Tim Hall
-- Description  : Displays information about network ACLs.
-- Requirements : Access to the DBA views.
-- Call Syntax  : @network_acls
-- Last Modified: 30/11/2011
-- -----------------------------------------------------------------------------------
COLUMN host FORMAT A30
COLUMN acl FORMAT A30

SELECT host, lower_port, upper_port, acl
FROM   dba_network_acls;