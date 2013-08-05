sqlplus -S / as sysdba << !

set lines 200;
set serveroutput on;
set timing on;

declare
    owner_name varchar2(30) := 'ABC';
    tab_name varchar2(60) := 'TAB';
    begin_date date := to_date('2010-01','yyyy-mm');
    end_date date := to_date('2013-03','yyyy-mm');
    init_date date := begin_date;
    --init_h_m_s char(10) := '00:00:00';
  
begin
    execute immediate ' alter session set nls_date_format=''yyyy-mm'' ' ;
    dbms_output.put_line('---------------------------------------------');
    dbms_output.put_line('Begin date: ' || begin_date);
    dbms_output.put_line('End date:   ' || end_date);
    dbms_output.put_line('---------------------------------------------');

    execute immediate ' alter session set nls_date_format=''yyyy-mm-dd hh24:mi:ss'' ' ;

    while true 
    loop
      
      if init_date > end_date 
      then
      
        exit;

      else
      
        dbms_output.put_line('alter table ' || owner_name || '.' || tab_name || ' add partition ' || 
                            ' P' || replace(replace(to_char(init_date,'yyyy-mm'),'-',''),'00:00:00','') || 
                            ' value less than (' || '''' || (last_day(init_date)+1)  || '''' || ' , ' || '''' || 'yyyy-mm-dd hh24:mi:ss' || '''' || ' );');
        init_date := add_months(init_date,1); 

      end if;

    end loop;

end;
/

!