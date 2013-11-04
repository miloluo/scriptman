---  Description:
---  Orgnize the dml operations via random executions
--- 
---  Script Author:
---  Milo Luo from System Maintenance Services (Beijing) Technology Ltd(Auto Tech (Beijing) Technology Co., Ltd)
---
---  Script Update:
---  Date           Modifier               Comments
---  ------------   -------------------    -------------------------------------------------------
---  Oct.31 2013    Milo Luo               Initial the script
---  Nov.02 2013    Milo Luo               Modify the insert part
---
--- 
---


create or replace procedure rand_dml(total_dml_cnt IN number)
--create or replace procedure rand_dml(total_dml_cnt IN number, tabname IN varchar2, insbaktab IN varchar2)
is
  -- define dml type code
  opcode number;

  -- define random key, lower and higher range
  randkey number;
  lowkey number;
  highkey number;

  -- dml manipulate row source
  rowcnt number;

  -- insert new data string
  tmp_col1 number;
  tmp_col2 number;
  tmp_col3 date;
  tmp_col4 varchar2(30);
  tmp_col5 varchar2(50);

  -- sql statment 
  sqlstmt varchar2(4000);
 
  -- two random strings
  str1 varchar2(30);
  str2 varchar2(50);

  -- define dml type counter
  del_cnt number := 0;
  ins_cnt number := 0;
  upd_cnt number := 0;
  
  -- define write log handler
  fhandle utl_file.file_type;
  buffer varchar2(1000);

  -- in $max_tries times, if the specific dml opeartion is ok.
  try_flag number := 0;

  -- max insert times
  instime number := 0; 

--############ User Defined Variable ##############################
  -- define output logfile name
  logname varchar2(200) := 'rand_dml.log';

  -- define fetch the how much lines before and after from keys
  rows_before_after number := 10 ;
  max_tries number := 10;
--#################################################################

begin

    fhandle := utl_file.fopen('LOGDIR',logname,'w',1000);

    for i in 1..total_dml_cnt loop

        -- ################################################
        -- # 1. Control what kind of dml should execute
        -- ## 0 -> insert
        -- ## 1 -> update
        -- ## 2 -> delete
        -- ################################################

        buffer := chr(10) || chr(10) || '++++++++++++++++++++++++++++++++++++++++++++++++' || chr(10);
	utl_file.put(fhandle,buffer);
	utl_file.fflush(fhandle);

        opcode := abs(mod(dbms_random.random,3));

        -- ################################################
        -- # 2. Execute the Random dml
        -- ################################################

        -- generate randkey
        randkey := abs(mod(dbms_random.random,1000))+1 ;
        lowkey := randkey - rows_before_after;
        highkey := randkey + rows_before_after;

        -- Initialize row count
        rowcnt := -1;

        -- ################################################
        -- Insert (opcode = 0)
        -- ################################################
        if opcode = 0 then

            -- I know the rowcnt
            select count(*) into rowcnt from perf.deldata1;
            --execute immediate 'select count(*) into rowcnt from :1.:2' using tabowner, tabname;
            --sqlstmt := 'select count(*) from :1';
            --execute immediate 'select count(*) into rowcnt from ' ||  tabowner || '.' || tabname;
            --execute immediate sqlstmt returning into rowcnt using tabname;
	    
	    -- if the rowcnt equal to zero, then insert some data
            if rowcnt > 0 then
               proc_del_data_back('perf_tab1','deldata1');
	       --dbms_output.put_line('call procedure!');
	    else
	       instime := abs(mod(dbms_random.random,2*rows_before_after)) + 2;
	       dbms_output.put_line('From new insert' || instime);


	       for z in 1..instime loop
                   -- random strings
	           tmp_col1 := seq1.nextval;
                   tmp_col2 := trunc(dbms_random.value(1,2)*1000000000+1);
	           tmp_col3 := to_date(sysdate-trunc(mod(dbms_random.value(1,2)*1000000000,365)),'yyyy-mm-dd');
	           tmp_col4 := dbms_random.string('A', 30);
	           tmp_col5 := dbms_random.string('X', 50);
		    
		   -- insert random value base on the sequence
		   sqlstmt := 'insert into perf.perf_tab1 values( :1 ,:2 , :3 , :4 , :5  )';
		   execute immediate sqlstmt using tmp_col1, tmp_col2, tmp_col3, tmp_col4, tmp_col5; 
	       end loop;
	       rowcnt := instime;
	    end if;

	    ins_cnt := ins_cnt + 1;
            buffer := 'Loop ' || i || ' : Insert '  || ' -> ' || rowcnt || ' records.'||chr(10)|| '++++++++++++++++++++++++++++++++++++++++++++++++';
	    utl_file.put(fhandle,buffer);
	    utl_file.fflush(fhandle);
            
        -- ################################################
        -- Update (opcode = 1)
        -- ################################################
        elsif opcode = 1 then
            
            -- random strings
            str1 := dbms_random.string('A', 30);
            str2 := dbms_random.string('X', 50);
            
            -- I know the rowcnt
            sqlstmt := 'select count(*) from perf.perf_tab1 where col1 >= :2 and col1 <= :3';
            execute immediate sqlstmt into rowcnt using lowkey, highkey;
                   
            try_flag := 0;

            -- try max_tries times to see if there is a none empty resultset.   
            for j in 1..max_tries loop  
                  
               if rowcnt > 0 then
               
                  sqlstmt := 'update perf.perf_tab1 set col4 = :1 , col5 = :2  where col1 >= :3 and col1 <=  :4 ';
                  execute immediate sqlstmt using str1, str2, lowkey, highkey;
                  commit;
	          upd_cnt := upd_cnt + 1;
                  --buffer := 'Loop ' || i || ' : Update '  || ' -> ' || rowcnt || ' records.'||chr(10)|| lowkey || '-' || highkey || chr(10) || '++++++++++++++++++++++++++++++++++++++++++++++++';
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
               execute immediate sqlstmt into rowcnt using lowkey, highkey;
            
            end loop;
            
            -- if no resultset match after $max_tries time, then output update failed     
            if try_flag = 0 then 
                  buffer := 'Loop ' || i || ' : Update failed after try ' ||  max_tries || ' times!' || chr(10) || '++++++++++++++++++++++++++++++++++++++++++++++++';
	          utl_file.put(fhandle,buffer);
	          utl_file.fflush(fhandle);
            end if;
            
            
        -- ################################################
        -- Delete (opcode = 2)
        -- ################################################
        elsif opcode = 2 then

	    -- I know the rowcnt
            sqlstmt := 'select count(*) from perf.perf_tab1 where col1 >= :2 and col1 <= :3';
            execute immediate sqlstmt into rowcnt using lowkey, highkey;

            -- try max_tries times to see if there is a none empty resultset.   
            try_flag := 0;
                
            for k in 1..max_tries loop  
                  
               if rowcnt > 0 then
                  sqlstmt := 'delete from perf.perf_tab1 where col1 >= :1 and col1 <= :2 '; 
                  execute immediate sqlstmt using lowkey, highkey ;
                  commit;               
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
               execute immediate sqlstmt into rowcnt using lowkey, highkey;
            
            end loop;
               
            -- if no resultset match after $max_tries time, then output delete failed     
            if try_flag = 0 then 
                  buffer := 'Loop ' || i || ' : Delete failed after try ' ||  max_tries || ' times!' || chr(10) || '++++++++++++++++++++++++++++++++++++++++++++++++';
	          utl_file.put(fhandle,buffer);
	          utl_file.fflush(fhandle);
            end if;

        -- ################################################
        -- Random Number Exception
        -- ################################################
        else
                  -- random number exception
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
    
    buffer := chr(10) || 
              'Total executes ' || total_dml_cnt || ' times.';
    utl_file.put(fhandle,buffer);
    utl_file.fflush(fhandle);

    buffer := chr(10) || 
              'INSERT executes ' || ins_cnt || ' times.';
    utl_file.put(fhandle,buffer);
    utl_file.fflush(fhandle);

    buffer := chr(10) || 
              'UPDATE executes ' || upd_cnt || ' times.';
    utl_file.put(fhandle,buffer);
    utl_file.fflush(fhandle);

    buffer := chr(10) || 
              'DELETE executes ' || del_cnt || ' times.';
    utl_file.put(fhandle,buffer);
    utl_file.fflush(fhandle);

    buffer := chr(10) || 
              'RANDOM DML COMPELETE SUCESSFULLY!' || chr(10); 
    utl_file.put(fhandle,buffer);
    utl_file.fflush(fhandle);

    -- close fd
    utl_file.fclose(fhandle);

end;
/
