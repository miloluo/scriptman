create or replace procedure rand_dml(total_dml_cnt IN number)
is
  opcode number;
  randkey number;
  lowkey number;
  highkey number;
  rowcnt number;
  sqlstmt varchar2(4000);
  str1 varchar2(30);
  str2 varchar2(50);
  try_flag number := 0;

-- define fetch the how much lines before and after from keys
  rows_before_after number := 10 ;
  max_tries number := 10;
  

begin

    for i in 1..total_dml_cnt loop

        -- ################################################
        -- # 1. Control what kind of dml should execute
        -- ## 0 -> insert
        -- ## 1 -> update
        -- ## 2 -> delete
        -- ################################################

        dbms_output.put_line(chr(10)||'++++++++++++++++++++++++++++++++++++++++++++++++');

        opcode := abs(mod(dbms_random.random,3));
        --dbms_output.put_line('OP code is : ' || opcode);


        -- ################################################
        -- # 2. execute the dml
        -- ################################################


        randkey := abs(mod(dbms_random.random,1000))+1 ;

        --dbms_output.put_line(randkey);


        lowkey := randkey - rows_before_after;
        highkey := randkey + rows_before_after;

        --dbms_output.put_line(lowkey);    
        --dbms_output.put_line(highkey);
    
        -- Initialize row count
        rowcnt := -1;

        -- Insert (opcode = 0)
        if opcode = 0 then

-- 添加判断是否deldata1为空，如果为空，插入行的记录。 

            -- I know the rowcnt
            select count(*) into rowcnt from perf.deldata1;
            --execute immediate sqlstmt into rowcnt using lowkey, highkey;

            proc_del_data_back('perf_tab1','deldata1');
            dbms_output.put_line('Loop ' || i || ' : Insert '  || ' -> ' || rowcnt || ' records.' );
            dbms_output.put_line('++++++++++++++++++++++++++++++++++++++++++++++++');
            
        -- Update (opcode = 1)
        elsif opcode = 1 then
            
            -- random strings
            str1 := dbms_random.string('A', 30);
            str2 := dbms_random.string('X', 50);
            
            -- I know the rowcnt
            sqlstmt := 'select count(*) from perf.perf_tab1 where col1 >= :2 and col1 <= :3';
            execute immediate sqlstmt into rowcnt using lowkey, highkey;
                   
            -- try max_tries times to see if there is a none empty resultset.   
            try_flag := 0;
                
            for j in 1..max_tries loop  
                  
               if rowcnt > 0 then
               
                  sqlstmt := 'update perf.perf_tab1 set col4 = :1 , col5 = :2  where col1 >= :3 and col1 <=  :4 ';
                  execute immediate sqlstmt using str1, str2, lowkey, highkey;
                  commit;
                  dbms_output.put_line('Loop ' || i || ' : Update ' || ' -> ' || rowcnt || ' records.');
                  dbms_output.put_line('++++++++++++++++++++++++++++++++++++++++++++++++'); 
                  try_flag := 1;
                  exit;
               
               end if ; 
                  
               -- generate randkey   
               randkey := abs(mod(dbms_random.random,1000))+1 ;
               
               lowkey := randkey - rows_before_after;
               highkey := randkey + rows_before_after;

               -- I know the rowcnt
               sqlstmt := 'select count(1) into rowcnt from perf.perf_tab1 where col1 >= :1 and col1 <= :2';
               execute immediate sqlstmt into rowcnt using lowkey, highkey;
            
            end loop;
            
            -- if update then do nothing
            if try_flag = 1 then 
                 null;
                 
            -- if no resultset match after $max_tries time, then output update failed     
            else 
                  dbms_output.put_line('Loop ' || i || ' : Update failed after try ' ||  max_tries || ' times!');
                  dbms_output.put_line('++++++++++++++++++++++++++++++++++++++++++++++++'); 
            end if;
            
            

            
        -- Delete (opcode = 2)
        elsif opcode = 2 then

-- 添加判断是否结果集为0，如果为0，调用其他值，调用有个次数限制，如果超过该值，操作改为insert或报出delete失败。         
--            execute immediate 'delete from perf.perf_tab1 where col1 >= ' || lowkey || ' and col1 <= ' || highkey ;
--            commit;
--            dbms_output.put_line('Loop ' || i || ' : Delete ');
--            dbms_output.put_line('++++++++++++++++++++++++++++++++++++++++++++++++');

	    -- I know the rowcnt
            sqlstmt := 'select count(*) from perf.perf_tab1 where col1 >= :2 and col1 <= :3';
            --sqlstmt := 'select count(*) into rowcnt from perf.perf_tab1 where col1 >= :1 and col1 <= :2';
            execute immediate sqlstmt into rowcnt using lowkey, highkey;

            -- try max_tries times to see if there is a none empty resultset.   
            try_flag := 0;
                
            for k in 1..max_tries loop  
                  
               if rowcnt > 0 then
                  sqlstmt := 'delete from perf.perf_tab1 where col1 >= :1 and col1 <= :2 '; 
                  execute immediate sqlstmt using lowkey, highkey ;
                  commit;               
                  dbms_output.put_line('Loop ' || i || ' : Delete ' || ' -> ' || rowcnt || ' records.');
                  dbms_output.put_line('++++++++++++++++++++++++++++++++++++++++++++++++'); 
                  try_flag := 1;
                  exit;
               
               end if ; 
                  
               -- generate randkey   
               randkey := abs(mod(dbms_random.random,1000))+1 ;
               lowkey := randkey - rows_before_after;
               highkey := randkey + rows_before_after;
               
               -- I know the rowcnt
               sqlstmt := 'select count(1) into rowcnt from perf.perf_tab1 where col1 >= :1 and col1 <= :2';
               execute immediate sqlstmt into rowcnt using lowkey, highkey;
            
            end loop;
               

        -- exception
        else

            dbms_output.put_line('Exception occur!!!');

        end if;
        


    end loop;


end;
/
