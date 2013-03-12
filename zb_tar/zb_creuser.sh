ORACLE_BASE=/oracle;export ORACLE_BASE;
ORACLE_HOME=/oracle/product/10.2.0;export ORACLE_HOME;
PATH=$PATH:$ORACLE_HOME/bin;export PATH;
ORACLE_SID=cebipzb;export ORACLE_SID;
sqlplus '/as sysdba' <<!
create tablespace INDX_PRIV  datafile '/zbbak/oradata/cebipzb/INDX_PRIV.dbf' size 200M reuse autoextend on;
create tablespace CEBIP_PRIV datafile '/zbbak/oradata/cebipzb/CEBIP_PRIV.dbf' size 500M reuse autoextend on;
create tablespace CEBIP_JNL  datafile '/zbbak/oradata/cebipzb/CEBIP_JNL.dbf' size 800M reuse autoextend on;
create tablespace CEBIP_SYS  datafile '/zbbak/oradata/cebipzb/CEBIP_SYS.dbf' size 500M reuse autoextend on;
create tablespace INDX_JNL   datafile '/zbbak/oradata/cebipzb/INDX_JNL.dbf' size 1000M reuse autoextend on;
create tablespace INDX_SYS   datafile '/zbbak/oradata/cebipzb/INDX_SYS.dbf' size 1000M reuse autoextend on;
create tablespace CEBIP_APP  datafile '/zbbak/oradata/cebipzb/CEBIP_APP.dbf' size 1000M reuse autoextend on;
create tablespace CEBIP_HIS  datafile '/zbbak/oradata/cebipzb/CEBIP_HIS.dbf' size 3000M reuse autoextend on;
create user pbcebdb identified by pbcebdb default tablespace CEBIP_SYS ;
grant dba to pbcebdb;
!
