create or replace procedure rand_dml(total_dml_cnt IN number)
is
  -- define dml type code
  opcode number;

  -- define random key, lower and higher range
  randkey number;
  lowkey number;
  highkey number;

  -- dml manipulate row source
  rowcnt number;

  -- sql statment 
  sqlstmt varchar2(4000);
 
  -- two random strings
  str1 varchar2(30);
  str2 varchar2(50);
  
  -- in $max_tries times, if the specific dml opeartion is ok.
  try_flag number := 0;

  -- define output logfile name
  logname varchar2(200) := 'rand_dml.log';

  -- define dml type counter
  del_cnt number := 0;
  ins_cnt number := 0;
  upd_cnt number := 0;

  -- define write log handler
  fhandle utl_file.file_type;
  buffer varchar2(1000);

  -- define fetch the how much lines before and after from keys
  rows_before_after number := 10 ;
  max_tries number := 10;

begin

    fhandle := utl_file.fopen('LOGDIR',logname,'w',1000);

    for i in 1..total_dml_cnt loop

        -- ################################################
        -- # 1. Control what kind of dml should execute
        -- ## 0 -> insert
        -- ## 1 -> update
        -- ## 2 -> delete
        -- ################################################

        --dbms_output.put_line(chr(10)||'++++++++++++++++++++++++++++++++++++++++++++++++');
        buffer := chr(10) || chr(10) || '++++++++++++++++++++++++++++++++++++++++++++++++' || chr(10);
	utl_file.put(fhandle,buffer);
	utl_file.fflush(fhandle);

        opcode := abs(mod(dbms_random.random,3));

        -- ################################################
        -- # 2. execute the dml
        -- ################################################

        -- generate randkey
        randkey := abs(mod(dbms_random.random,1000))+1 ;
        lowkey := randkey - rows_before_after;
        highkey := randkey + rows_before_after;

        -- Initialize row count
        rowcnt := -1;

        -- Insert (opcode = 0)
        if opcode = 0 then

-- 添加判断是否deldata1为空，如果为空，插入行的记录。 

            -- I know the rowcnt
            select count(*) into rowcnt from perf.deldata1;

            proc_del_data_back('perf_tab1','deldata1');
            --dbms_output.put_line('Loop ' || i || ' : Insert '  || ' -> ' || rowcnt || ' records.' );
            --dbms_output.put_line('++++++++++++++++++++++++++++++++++++++++++++++++');
	    ins_cnt := ins_cnt + 1;
            buffer := 'Loop ' || i || ' : Insert '  || ' -> ' || rowcnt || ' records.'||chr(10)|| '++++++++++++++++++++++++++++++++++++++++++++++++';
	    utl_file.put(fhandle,buffer);
	    utl_file.fflush(fhandle);
            
        -- Update (opcode = 1)
        elsif opcode = 1 then
            
            -- random strings
            str1 := dbms_random.string('A', 30);
            str2 := dbms_random.string('X', 50);
            
            -- I know the rowcnt
            sqlstmt := 'select count(*) from perf.perf_tab1 where col1 >= :2 and col1 <= :3';
	    --dbms_output.put_line(sqlstmt || chr(10) || 'rowcnt: ' || rowcnt || chr(10) || 'lowkey: ' || lowkey || chr(10) || 'highkey: ' || highkey);
            execute immediate sqlstmt into rowcnt using lowkey, highkey;
                   

            try_flag := 0;
            -- try max_tries times to see if there is a none empty resultset.   
            for j in 1..max_tries loop  
                  
               if rowcnt > 0 then
               
                  sqlstmt := 'update perf.perf_tab1 set col4 = :1 , col5 = :2  where col1 >= :3 and col1 <=  :4 ';
                  execute immediate sqlstmt using str1, str2, lowkey, highkey;
                  commit;
                  --dbms_output.put_line('Loop ' || i || ' : Update ' || ' -> ' || rowcnt || ' records.');
                  --dbms_output.put_line('++++++++++++++++++++++++++++++++++++++++++++++++'); 
	          upd_cnt := upd_cnt + 1;
                  buffer := 'Loop ' || i || ' : Update '  || ' -> ' || rowcnt || ' records.'||chr(10)|| '++++++++++++++++++++++++++++++++++++++++++++++++';
	          utl_file.put(fhandle,buffer);
	          utl_file.fflush(fhandle);
                  try_flag := 1;
                  exit;
               
               end if ; 
                  
               -- generate randkey   
               randkey := abs(mod(dbms_random.random,1000))+1 ;
               lowkey := randkey - rows_before_after;
               highkey := randkey + rows_before_after;

               -- I know the rowcnt
               sqlstmt := 'select count(1)  from perf.perf_tab1 where col1 >= :1 and col1 <= :2';
	       --dbms_output.put_line(sqlstmt || chr(10) || 'rowcnt: ' || rowcnt || chr(10) || 'lowkey: ' || lowkey || chr(10) || 'highkey: ' || highkey);
               execute immediate sqlstmt into rowcnt using lowkey, highkey;
            
            end loop;
            
            -- if no resultset match after $max_tries time, then output update failed     
            if try_flag = 0 then 
                  --dbms_output.put_line('Loop ' || i || ' : Update failed after try ' ||  max_tries || ' times!');
                  --dbms_output.put_line('++++++++++++++++++++++++++++++++++++++++++++++++'); 
                  buffer := 'Loop ' || i || ' : Update failed after try ' ||  max_tries || ' times!' || chr(10) || '++++++++++++++++++++++++++++++++++++++++++++++++';
	          utl_file.put(fhandle,buffer);
	          utl_file.fflush(fhandle);
            end if;
            
            
        -- Delete (opcode = 2)
        elsif opcode = 2 then

-- 添加判断是否结果集为0，如果为0，调用其他值，调用有个次数限制，如果超过该值，操作改为insert或报出delete失败。         

	    -- I know the rowcnt
            sqlstmt := 'select count(*) from perf.perf_tab1 where col1 >= :2 and col1 <= :3';
	    --dbms_output.put_line(sqlstmt || chr(10) || 'rowcnt: ' || rowcnt || chr(10) || 'lowkey: ' || lowkey || chr(10) || 'highkey: ' || highkey);
            execute immediate sqlstmt into rowcnt using lowkey, highkey;

            -- try max_tries times to see if there is a none empty resultset.   
            try_flag := 0;
                
            for k in 1..max_tries loop  
                  
               if rowcnt > 0 then
                  sqlstmt := 'delete from perf.perf_tab1 where col1 >= :1 and col1 <= :2 '; 
                  execute immediate sqlstmt using lowkey, highkey ;
                  commit;               
                  --dbms_output.put_line('Loop ' || i || ' : Delete ' || ' -> ' || rowcnt || ' records.');
                  --dbms_output.put_line('++++++++++++++++++++++++++++++++++++++++++++++++'); 
                  buffer := 'Loop ' || i || ' : Delete '  || ' -> ' || rowcnt || ' records.'||chr(10) ||'++++++++++++++++++++++++++++++++++++++++++++++++';
	          utl_file.put(fhandle,buffer);
	          utl_file.fflush(fhandle);
                  try_flag := 1;
		  del_cnt := del_cnt + 1;
                  exit;
               
               end if ; 
                  
               -- generate randkey   
               randkey := abs(mod(dbms_random.random,1000))+1 ;
               lowkey := randkey - rows_before_after;
               highkey := randkey + rows_before_after;
               
               -- I know the rowcnt
               sqlstmt := 'select count(1) from perf.perf_tab1 where col1 >= :1 and col1 <= :2';
	       --dbms_output.put_line(sqlstmt || chr(10) || 'rowcnt: ' || rowcnt || chr(10) || 'lowkey: ' || lowkey || chr(10) || 'highkey: ' || highkey);
               execute immediate sqlstmt into rowcnt using lowkey, highkey;
            
            end loop;
               
            -- if no resultset match after $max_tries time, then output delete failed     
            if try_flag = 0 then 
                  --dbms_output.put_line('Loop ' || i || ' : Delete failed after try ' ||  max_tries || ' times!');
                  --dbms_output.put_line('++++++++++++++++++++++++++++++++++++++++++++++++'); 
                  buffer := 'Loop ' || i || ' : Delete failed after try ' ||  max_tries || ' times!' || chr(10) || '++++++++++++++++++++++++++++++++++++++++++++++++';
	          utl_file.put(fhandle,buffer);
	          utl_file.fflush(fhandle);
            end if;

        -- exception
        else

                  --dbms_output.put_line('Exception occur!!!');
                  buffer := 'Exception occur!!!';
	          utl_file.put(fhandle,buffer);
	          utl_file.fflush(fhandle);
		  -- close fd
                  utl_file.fclose(fhandle);
		  -- exit the program
		  exit;

        end if;

        
    end loop;

    -- program summary
    buffer := chr(10) || 
              chr(10) || 
	      chr(10) || 
	      '***************************************************************' || chr(10) || 
	      'RANDOM DML SUMMARY'||chr(10) || 
	      '***************************************************************'; 
    utl_file.put(fhandle,buffer);
    utl_file.fflush(fhandle);
    
    buffer := chr(10) || 'Total executes ' || total_dml_cnt || ' times.';
    utl_file.put(fhandle,buffer);
    utl_file.fflush(fhandle);

    buffer := chr(10) || 'INSERT executes ' || ins_cnt || ' times.';
    utl_file.put(fhandle,buffer);
    utl_file.fflush(fhandle);

    buffer := chr(10) || 'UPDATE executes ' || upd_cnt || ' times.';
    utl_file.put(fhandle,buffer);
    utl_file.fflush(fhandle);

    buffer := chr(10) || 'DELETE executes ' || del_cnt || ' times.';
    utl_file.put(fhandle,buffer);
    utl_file.fflush(fhandle);

    buffer := chr(10) || 'RANDOM DML COMPELETE SUCESSFULLY!' || chr(10); 
    utl_file.put(fhandle,buffer);
    utl_file.fflush(fhandle);

    -- close fd
    utl_file.fclose(fhandle);

end;
/
