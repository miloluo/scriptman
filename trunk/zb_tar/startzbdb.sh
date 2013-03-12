ORACLE_BASE=/oracle;export ORACLE_BASE;
ORACLE_HOME=/oracle/product/10.2.0;export ORACLE_HOME;
PATH=$PATH:$ORACLE_HOME/bin;export PATH;
ORACLE_SID=cebipzb;export ORACLE_SID;
sqlplus /nolog <<EOF
conn / as sysdba
startup
quit
EOF
exit
!

