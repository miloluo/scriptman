CREATE OR REPLACE
PROCEDURE proc_mvtest2(
    lname   VARCHAR2,
    dname   VARCHAR2,
    maxloop NUMBER DEFAULT 1)
  -- For test BF_EVT_DEP_SAP_2012 table
IS
  -----------------From input ------------------------
  -- procedure log name
  logname VARCHAR2 (1000) := lname;
  -- config file with date time string
  date_fname VARCHAR2 (1000) := dname;
  -- procedure execution loop
  max_loop NUMBER := maxloop;
  --------------------------- ------------------------
  -----------------File Handler-----------------------
  -- file handler for write the procedure log
  fhandle UTL_FILE.file_type;
  -- file handler for read the config file
  fhandle1 UTL_FILE.file_type;
  ----------------------------------------------------
  ----------------Type define------------------------
  -- a type of table record date time string
TYPE date_type
IS
  TABLE OF VARCHAR2 (100) INDEX BY PLS_INTEGER;
  -- a variable to store date time string
  v_date date_type;
  ----------------------------------------------------
  ----------------Time calculation variable-----------
  -- begin time
  t1 DATE;
  -- end time
  t2 DATE;
  -- (end_time - begin_time) = diff time
  diff_t NUMBER;
  ----------------------------------------------------
  -- buffer cache(log)
  buffer VARCHAR2 (4000);
  -- get the max number of v_date table
  v_last NUMBER := 0;
  -- a count of operation records(not real)
  v_record NUMBER := 100;
BEGIN
  -- read the date file to fetch delimiter date
  fhandle1 := UTL_FILE.fopen ('CONF_DIR',date_fname,'r',30);
  LOOP
    BEGIN
      UTL_FILE.get_line (fhandle1, buffer, 30);
      v_last          := v_last + 1;
      v_date (v_last) := buffer;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      EXIT;
    END;
  END LOOP;
  UTL_FILE.fclose (fhandle1);
  -- check every date file
  FOR i IN 1 .. v_last
  LOOP
    DBMS_OUTPUT.put_line (v_date (i));
  END LOOP;
  DBMS_OUTPUT.put_line ('+++++++++++++++++++++++++++++++');
  DBMS_OUTPUT.put_line ('Max element number: ' || v_last);
  -- open logfile for writing logs
  fhandle := UTL_FILE.fopen ('MVLOG',logname,'w',1000);
  buffer  := CHR (10) || '++++++++++++++++++++++++++++++++++++++++++++++++' || CHR (10) || 'Table - BF_EVT_DEP_SAP_2012' || CHR (10) || '++++++++++++++++++++++++++++++++++++++++++++++++' || CHR (10);
  UTL_FILE.put_line (fhandle, buffer, TRUE);
  -- begin execute the dml and refresh mveiw
  FOR i IN 1 .. max_loop
  LOOP
    -- init the around records
    v_record := 100;
    -- go through the date file
    FOR k IN 1 .. v_last
    LOOP
      --dbms_output.put_line(v_date(i));
      buffer := '++++++++++++++++++++ Loop ' || i || ' with ' || v_record || ' w +++++++++++++++++++++++++++';
      UTL_FILE.put_line (fhandle, buffer, TRUE);
      ---------------------------
      -- 1. begin backup time
      ---------------------------
      --insert /*+ parallel(deldata2 8) */ into deldata2 select * from BF_EVT_DEP_SAP_2012 where sa_tx_dt <= '2012-01-04';
      --dbms_output.put_line('insert /*+ parallel(deldata2 8) */ into deldata2 select * from BF_EVT_DEP_SAP_2012 where sa_tx_dt <= ' || v_date(i));
      SELECT SYSDATE
      INTO t1
      FROM DUAL;
      --------execute immediate 'insert /*+ parallel(deldata2 8) */ into deldata2 select * from BF_EVT_DEP_SAP_2012 where sa_tx_dt <= ' || v_date(k);
      -- end time
      SELECT SYSDATE
      INTO t2
      FROM DUAL;
      -- calculating the backup delete data time
      SELECT ROUND ( (t2 - t1) * 86400, 2)
      INTO diff_t
      FROM DUAL;
      buffer := ' - Backup delete data Time: ' || diff_t || ' second.';
      UTL_FILE.put_line (fhandle, buffer, TRUE);
      -----------------------------
      -- 2. begin delete time
      -----------------------------
      --delete /*+ parallel(BF_EVT_DEP_SAP_2012 8) */ from BF_EVT_DEP_SAP_2012 where sa_tx_dt <= '2012-01-04';
      --commit;
      SELECT SYSDATE
      INTO t1
      FROM DUAL;
      -------execute immediate 'delete /*+ parallel(BF_EVT_DEP_SAP_2012 8) */ from BF_EVT_DEP_SAP_2012 where sa_tx_dt <= ' || v_date(k);
      COMMIT;
      -- end time
      SELECT SYSDATE INTO t2 FROM DUAL;
      -- calculating the delete data time
      SELECT ROUND ( (t2 - t1) * 86400, 2)
      INTO diff_t
      FROM DUAL;
      buffer := ' - Delete data Time: ' || diff_t || ' second.';
      UTL_FILE.put_line (fhandle, buffer, TRUE);
      ----------------------------
      -- 3. begin insert time
      ----------------------------
      SELECT SYSDATE
      INTO t1
      FROM DUAL;
      ------insert /*+ parallel(BF_EVT_DEP_SAP_2012 8) */  into BF_EVT_DEP_SAP_2012 select * from  deldata2;
      -- end time
      SELECT SYSDATE
      INTO t2
      FROM DUAL;
      -- calculating the delete data time
      SELECT ROUND ( (t2 - t1) * 86400, 2)
      INTO diff_t
      FROM DUAL;
      buffer := ' - Insert data Time: ' || diff_t || ' second.';
      UTL_FILE.put_line (fhandle, buffer, TRUE);
      --------------------------
      -- 4. begin truncate backup table time
      --------------------------
      SELECT SYSDATE
      INTO t1
      FROM DUAL;
      ------execute immediate 'truncate table deldata2';
      COMMIT;
      -- calculating the delete data time
      SELECT ROUND ( (t2 - t1) * 86400, 2)
      INTO diff_t
      FROM DUAL;
      buffer := ' - Truncate backup table Time: ' || diff_t || ' second.';
      UTL_FILE.put_line (fhandle, buffer, TRUE);
      --------------------------
      -- 5. begin refresh time
      --------------------------
      SELECT SYSDATE
      INTO t1
      FROM DUAL;
      -- MView Fast Refresh
      ------dbms_mview.refresh@link_slave('MV_BF_EVT_DEP_SAP_2012','F',parallelism => 8);
      -- end time
      SELECT SYSDATE
      INTO t2
      FROM DUAL;
      -- calculating the diff time
      SELECT ROUND ( (t2 - t1) * 86400, 2)
      INTO diff_t
      FROM DUAL;
      buffer := ' - Fast Refresh Time: ' || diff_t || ' second.' || CHR (10) || '++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++' || CHR (10) || CHR (10);
      UTL_FILE.put_line (fhandle, buffer, TRUE);
      v_record := v_record + 100;
    END LOOP;
  END LOOP;
END;
/
