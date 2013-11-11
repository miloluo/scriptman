---
---  Script Name: rand_dml
---  Description:
---  Orgnize the dml operations via random executions
--- 
---  Script Author:
---  Milo Luo from System Maintenance Services (Beijing) Technology Ltd(Auto Tech (Beijing) Technology Co., Ltd)
---
---  Script Update:
---  Date           Modifier               Comments
---  ------------   -------------------    ---------------------------------------------------------------------------
---  Oct.31 2013    Milo Luo               Initial the script.
---  Nov.02 2013    Milo Luo               Modify the insert logic.
---  Nov.05 2013    Milo Luo               Improve the randky algorithm.
---  Nov.05 2013    Milo Luo               Improve the Scalability.
---  Nov.08 2013    Milo Luo               Add logfile columns for scalability.
---  Nov.11 2013    Milo Luo               Perfmance improve on max(col1), max(col1)
---
--- 

-------------------------
--- Parameter Explain ---
-------------------------
---------------------------------------------------------------------------------------------------
--- total_dml_cnt:  How many dml you wanna execute, suggest higher than target.
--- tabname: The table you wanna do random dml operations.
---         In this scenario, the table is perf_tab1.
--- insbaktab: The table is used to keep the delete data from $tabname, now the table name 
---         in the scenario is call deldata1 base on trigger.
--- seqname: The sequence name using in inserting.
--- logfile: The log file that you can see the result of what kind of dml proceed in real time.
---------------------------------------------------------------------------------------------------

create or replace procedure rand_dml(total_dml_cnt IN number, tabname IN varchar2, insbaktab IN varchar2, seqname IN varchar2, logfile IN varchar2)
is
  -- define dml type code
  opcode number;

  -- define random key, lower and higher range
  randkey number;
  lowkey number;
  highkey number;
  maxkey number;
  minkey number;

  -- dml manipulate row source
  rowcnt number;

  -- insert new data string
  tmp_col1 number;
  tmp_col2 number;
  tmp_col3 date;
  tmp_col4 varchar2(40);
  tmp_col5 varchar2(60);

  -- sql statment 
  sqlstmt varchar2(4000);
 
  -- two random strings
  str1 varchar2(30);
  str2 varchar2(50);

  -- define dml type counter
  del_cnt number := 0;
  ins_cnt number := 0;
  upd_cnt number := 0;
  fail_cnt number := 0;
  
  -- define write log handler
  fhandle utl_file.file_type;
  buffer varchar2(1000);

  -- in $max_tries times, if the specific dml opeartion is ok.
  try_flag number := 0;

  -- max insert times
  instime number := 0; 

  -- define output logfile name
  logname varchar2(200) := logfile;

  -- define sequence name
  seqs varchar2(200) := seqname;

--############ User Defined Variable ##############################

  -- define fetch the how much lines before and after from keys
  rows_before_after number := 20 ;
  max_tries number := 20;
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

        buffer := chr(10) || '++++++++++++++++++++++++++++++++++++++++++++++++';
        utl_file.put_line(fhandle,buffer,TRUE);

        opcode := abs(mod(dbms_random.random,3));

        -- ################################################
        -- # 2. Execute the Random dml
        -- ################################################

        -- generate randkey
        sqlstmt := 'select max(col1) from ' || tabname;
	execute immediate sqlstmt into maxkey;
        sqlstmt := 'select min(col1) from ' || tabname;
	execute immediate sqlstmt into minkey;
        randkey := abs(mod(dbms_random.random,maxkey-minkey)) + minkey + 1;

        lowkey := randkey - rows_before_after;
        highkey := randkey + rows_before_after;

        -- Initialize row count
        rowcnt := -1;

        -- ################################################
        -- Insert (opcode = 0)
        -- ################################################
        if opcode = 0 then

            -- I know the rowcnt
            sqlstmt := 'select count(*) from ' || insbaktab;
	    execute immediate sqlstmt into rowcnt;

	    -- if the rowcnt equal to zero, then insert some data
            if rowcnt > 0 then
               proc_del_data_back(tabname,insbaktab);

	    else
	       instime := abs(mod(dbms_random.random,2*rows_before_after)) + 2;
	       --dbms_output.put_line('From new insert ' || instime || ' times.');

	       for z in 1..instime loop
                   -- random strings
	           --tmp_col1 := seq1.nextval;
	           --tmp_col1 := seqs.nextval;
	           execute immediate 'select ' || seqs || '.nextval from dual' into tmp_col1;
		   --dbms_output.put_line(tmp_col1);
                   tmp_col2 := trunc(dbms_random.value(1,2)*1000000000+1);
	           tmp_col3 := to_date(sysdate-trunc(mod(dbms_random.value(1,2)*1000000000,365)),'yyyy-mm-dd');
	           tmp_col4 := dbms_random.string('A', 30);
	           tmp_col5 := dbms_random.string('X', 50);
		    
		   -- insert random value base on the sequence
		   sqlstmt := 'insert into ' || tabname || ' values( :1 ,:2 , :3 , :4 , :5  )';
		   execute immediate sqlstmt using tmp_col1, tmp_col2, tmp_col3, tmp_col4, tmp_col5; 
	       end loop;
	       rowcnt := instime;
	    end if;

	    ins_cnt := ins_cnt + 1;
            buffer := 'Loop ' || i || ' : Insert '  || ' -> ' || rowcnt || ' records.'||chr(10)|| '++++++++++++++++++++++++++++++++++++++++++++++++';
            utl_file.put_line(fhandle,buffer,TRUE);
            
        -- ################################################
        -- Update (opcode = 1)
        -- ################################################
        elsif opcode = 1 then
            
            -- random strings
            str1 := dbms_random.string('A', 30);
            str2 := dbms_random.string('X', 50);
            
            -- I know the rowcnt
            sqlstmt := 'select count(col1) from ' || tabname || ' where col1 >= :2 and col1 <= :3';
            execute immediate sqlstmt into rowcnt using lowkey, highkey;

	        ---  Script Author:
            ---  Milo Luo from System Maintenance Services (Beijing) Technology Ltd(Auto Tech (Beijing) Technology Co., Ltd

            try_flag := 0;

            -- try max_tries times to see if there is a none empty resultset.   
            for j in 1..max_tries loop  
                  
               if rowcnt > 0 then
               
                  sqlstmt := 'update ' || tabname || ' set col4 = :1 , col5 = :2  where col1 >= :3 and col1 <=  :4 ';
                  execute immediate sqlstmt using str1, str2, lowkey, highkey;
                  commit;
	          upd_cnt := upd_cnt + 1;
                  buffer := 'Loop ' || i || ' : Update '  || ' -> ' || rowcnt || ' records.'||chr(10)|| '++++++++++++++++++++++++++++++++++++++++++++++++';
                  utl_file.put_line(fhandle,buffer,TRUE);
                  try_flag := 1;
                  exit;
               
               end if ; 
                  
               -- generate randkey   
               randkey := abs(mod(dbms_random.random,1000))+1 ;
               lowkey := randkey - rows_before_after;
               highkey := randkey + rows_before_after;

               -- I know the rowcnt
               sqlstmt := 'select count(col1)  from ' || tabname || ' where col1 >= :1 and col1 <= :2';
               execute immediate sqlstmt into rowcnt using lowkey, highkey;
            
            end loop;
            
            -- if no resultset match after $max_tries time, then output update failed     
            if try_flag = 0 then 
                  buffer := 'Loop ' || i || ' : Update failed after try ' ||  max_tries || ' times!' || chr(10) || '++++++++++++++++++++++++++++++++++++++++++++++++';
                  utl_file.put_line(fhandle,buffer,TRUE);
            end if;
            
            
        -- ################################################
        -- Delete (opcode = 2)
        -- ################################################
        elsif opcode = 2 then

	    -- I know the rowcnt
            sqlstmt := 'select count(col1) from ' || tabname || ' where col1 >= :2 and col1 <= :3';
            execute immediate sqlstmt into rowcnt using lowkey, highkey;

            -- try max_tries times to see if there is a none empty resultset.   
            try_flag := 0;
                
            for k in 1..max_tries loop  
                  
               if rowcnt > 0 then
                  sqlstmt := 'delete from ' || tabname || ' where col1 >= :1 and col1 <= :2 '; 
                  execute immediate sqlstmt using lowkey, highkey ;
                  commit;               
                  buffer := 'Loop ' || i || ' : Delete '  || ' -> ' || rowcnt || ' records.'||chr(10) ||'++++++++++++++++++++++++++++++++++++++++++++++++';
                  utl_file.put_line(fhandle,buffer,TRUE);
                  try_flag := 1;
		  del_cnt := del_cnt + 1;
                  exit;
               
               end if ; 
                  
               -- generate randkey   
               randkey := abs(mod(dbms_random.random,1000))+1 ;
               lowkey := randkey - rows_before_after;
               highkey := randkey + rows_before_after;
               
               -- I know the rowcnt
               sqlstmt := 'select count(col1) from ' || tabname || ' where col1 >= :1 and col1 <= :2';
               execute immediate sqlstmt into rowcnt using lowkey, highkey;
            
            end loop;
               
            -- if no resultset match after $max_tries time, then output delete failed     
            if try_flag = 0 then 
                  buffer := 'Loop ' || i || ' : Delete failed after try ' ||  max_tries || ' times!' || chr(10) || '++++++++++++++++++++++++++++++++++++++++++++++++';
                  utl_file.put_line(fhandle,buffer,TRUE);
            end if;

        -- ################################################
        -- Random Number Exception
        -- ################################################
        else
                  -- random number exception
                  buffer := 'Exception occur!!!';
                  utl_file.put_line(fhandle,buffer,TRUE);
		
		  -- close fd
                  utl_file.fclose(fhandle);

		  -- exit the program
		  exit;

        end if;

        
    end loop;

    -- program summary
    buffer := chr(10) || 
	      chr(10) || 
	      '************************************************' || chr(10) || 
	      'RANDOM DML SUMMARY'||chr(10) || 
	      '************************************************'; 
    utl_file.put_line(fhandle,buffer,TRUE);
    
    buffer := chr(10) || 
              'Total executes ' || total_dml_cnt || ' times.';
    utl_file.put_line(fhandle,buffer,TRUE);

    buffer := chr(10) || 
              'INSERT executes ' || ins_cnt || ' times.';
    utl_file.put_line(fhandle,buffer,TRUE);

    buffer := 'UPDATE executes ' || upd_cnt || ' times.';
    utl_file.put_line(fhandle,buffer,TRUE);

    buffer := 'DELETE executes ' || del_cnt || ' times.';
    utl_file.put_line(fhandle,buffer,TRUE);

    fail_cnt := total_dml_cnt - ins_cnt - upd_cnt -del_cnt;
    if ( fail_cnt = 0 ) then     
        buffer := chr(10) || 
              'RANDOM DML COMPELETE SUCESSFULLY!' ; 
        utl_file.put_line(fhandle,buffer,TRUE);
    elsif ( fail_cnt > 0 ) then 
        buffer := chr(10)|| 'FAIL DML count after max tries random: ' || fail_cnt || ' . ' ||
	       chr(10) || 
              'RANDOM DML COMPELETE, BUT THERE ARE SOME FAILURE AFTER MAXTRIES GET RANDOM !' ; 
        utl_file.put_line(fhandle,buffer,TRUE);
    else 
        buffer := chr(10) || 
              'Unknow error occur!' ; 
        utl_file.put_line(fhandle,buffer,TRUE);
    end if;

    -- close fd
    utl_file.fclose(fhandle);

end;
/

