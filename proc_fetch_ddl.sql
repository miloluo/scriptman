create or replace procedure proc_fetch_ddl (obj_set IN varchar2)    
as
v_obj_set varchar2(50);
v_obj varchar2(50);
v_str_pos number;
begin
   v_obj_set := obj_set;
   v_str_pos := instr(v_obj_set, ',');

-- split the objects' names and process in the loop   
   while v_str_pos  != 0
   loop
       dbms_output.put_line('################');
			 --dbms_output.put_line(v_obj_set);
			 
-- get the first object name in the v_object_set			 
   	   v_obj := trim(substr(v_obj_set, 1, v_str_pos-1));
   	   --dbms_output.put_line('v_obj:' ||v_obj );
   	   --dbms_output.put_line('v_obj length:' ||length(v_obj) );

-- trim the object set and ,update it's content
   	   v_obj_set := trim(substr(v_obj_set,v_str_pos+1));
   	   dbms_output.put_line('v_obj_set:'||v_obj_set);

-- update the str position, that is ',' position.   	   
   	   v_str_pos := instr(v_obj_set, ',');
   --end if; 
   end loop;

-- if there is only one left or single object pass-in
   if  v_str_pos = 0
   then
   	 dbms_output.put_line('Only one obj');
   	 dbms_output.put_line('')
   end if; 
   
end;
/