ORACLE_SID=cebipzb;export ORACLE_SID;
ORACLE_HOME=/oracle/product/10.2.0;export ORACLE_HOME;
PATH=$PATH:$ORACLE_HOME/bin;export PATH;
#���´����û�
sqlplus '/as sysdba' <<!
drop  user pbcebdb CASCADE;
create user pbcebdb identified by pbcebdb default tablespace CEBIP_SYS ;
grant dba to pbcebdb;
!
