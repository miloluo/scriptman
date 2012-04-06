-- Procedure: proc_fetch_ddl
-- Purpose: For tuning sql, we want to get the object info in sql statement
-- Usage: you can provide the object the first argument of the procedure, multiple objects can be splited by ','
-- Before execute the procedure, PLEASE MAKE SURE, YOU HAVE DBA PRIVILLEGE AND SET SERVEROUTPUT ON;
-- Eg 1: single object:
-----> exec proc_fetch_ddl('tab1');
-- Eg 2: multiple objects:
-----> exec proc_fetch_ddl('tab1,tab2');


create or replace procedure proc_fetch_ddl (obj_list IN varchar2)    
as
v_obj_list varchar2(50); --obj list
v_obj varchar2(50); -- single obj
v_str_pos number; -- the position of one object name

v_if_part_table int;



begin
-- ### Passin the obj list to variable
	v_obj_list := obj_list;
	
-- ### Use ',' to split the each object name	
	v_str_pos := instr(v_obj_list, ',');

-- ### Get the first object name in the v_object_set ###			 
	v_obj := trim(substr(v_obj_list, 1, v_str_pos-1));

	dbms_output.put_line('set linesize 200;');
	dbms_output.put_line('alter session set nls_date_format=''yyyy-mm-dd hh24:mi:ss'';');
	
	
-- ### Split the objects' names and process in the loop ###  
	while v_str_pos  != 0
	loop

-- #### Get the first object name in the v_object_set	###		 
		v_obj := trim(substr(v_obj_list, 1, v_str_pos-1));
		--dbms_output.put_line('v_obj:' ||v_obj );
		--dbms_output.put_line('v_obj length:' ||length(v_obj) );
		
-- ################# Filter the object type part #########################
-- 1. Check if it's partitions table ;
-- 2. Check if it's the normal table/view ;
-- 3. Check if it's public synonym ( get the local or remote table/view infomation) ;
-- 4. If none of the above obj found, then raise error
-- #######################################################################
    
		
		
		
		
		dbms_output.put_line('---------'||v_obj||'------------');
		dbms_output.put_line('col object_name for a30;');
		dbms_output.put_line('select owner, object_name, object_type from dba_objects where object_name = '''||upper(v_obj)||''';');
		--dbms_output.put_line('select owner, table_name, tablespace_name, status, freelists, logging, last_analyzed from dba_tables where lower(table_name)='''||v_obj||''';');

-- ### Trim the object set and ,update it's content ###
		v_obj_list := trim(substr(v_obj_list,v_str_pos+1));
		--dbms_output.put_line('v_obj_list:'||v_obj_list);

-- ### Update the str position, that is ',' position ### 	   
		v_str_pos := instr(v_obj_list, ',');
   		 
	end loop;

-- ### If there is only one left or single object pass-in ###
	if  v_str_pos = 0
	then
		dbms_output.put_line('Only one obj');
		dbms_output.put_line('');
	end if; 
   
end;
/

