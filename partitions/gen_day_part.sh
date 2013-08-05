sqlplus -S / as sysdba << !

set lines 200;
set serveroutput on;
set timing on;

declare
    owner_name varchar2(30) := 'ABC';
    tab_name varchar2(60) := 'TAB';
    begin_date date := to_date('2013-01-01','yyyy-mm-dd');
    end_date date := to_date('2013-03-01','yyyy-mm-dd');
    init_date date := begin_date;
    --init_h_m_s char(10) := '00:00:00';
 
begin
    execute immediate ' alter session set nls_date_format=''yyyy-mm-dd hh24:mi:ss'' ' ;
    dbms_output.put_line('---------------------------------------------');
    dbms_output.put_line('Begin date: ' || begin_date);
    dbms_output.put_line('End date:   ' || end_date);
    dbms_output.put_line('---------------------------------------------');

    while true
    loop
     
      if init_date > end_date
      then
     
        exit;

      else
     
        dbms_output.put_line('alter table ' || owner_name || '.' || tab_name || ' add partition ' || ' P' || replace(replace(init_date,'-',''),'00:00:00','') ||
                            ' value less than (' || '''' || (init_date+1)  || '''' || ' , ' || '''' || 'yyyy-mm-dd hh24:mi:ss' || '''' || ' );');
        init_date := init_date+1;

      end if;

    end loop;

end;
/

!