CREATE OR REPLACE PACKAGE csv AS
-- --------------------------------------------------------------------------
-- Name         : http://www.oracle-base.com/dba/miscellaneous/cvs.sql
-- Author       : DR Timothy S Hall
-- Description  : Basic CSV API. For usage notes see:
--                  http://www.oracle-base.com/articles/9i/GeneratingCSVFiles.php
--
--                  CREATE OR REPLACE DIRECTORY dba_dir AS '/u01/app/oracle/dba/';
--                  ALTER SESSION SET NLS_DATE_FORMAT='DD-MON-YYYY HH24:MI:SS';
--
--                  EXEC csv.generate('DBA_DIR', 'generate.csv', p_query => 'SELECT * FROM emp');
--
-- Requirements : UTL_FILE, DBMS_SQL
-- Ammedments   :
--   When         Who       What
--   ===========  ========  =================================================
--   14-MAY-2005  Tim Hall  Initial Creation
-- --------------------------------------------------------------------------

PROCEDURE generate (p_dir     IN  VARCHAR2,
                    p_file    IN  VARCHAR2,
                    p_query   IN  VARCHAR2);
END csv;
/
SHOW ERRORS

CREATE OR REPLACE PACKAGE BODY csv AS
-- --------------------------------------------------------------------------
-- Name         : http://www.oracle-base.com/dba/miscellaneous/cvs.sql
-- Author       : DR Timothy S Hall
-- Description  : Basic CSV API. For usage notes see:
--                  http://www.oracle-base.com/articles/9i/GeneratingCSVFiles.php
--
--                  CREATE OR REPLACE DIRECTORY dba_dir AS '/u01/app/oracle/dba/';
--                  ALTER SESSION SET NLS_DATE_FORMAT='DD-MON-YYYY HH24:MI:SS';
--
--                  EXEC csv.generate('DBA_DIR', 'generate.csv', p_query => 'SELECT * FROM emp');
--
-- Requirements : UTL_FILE, DBMS_SQL
-- Ammedments   :
--   When         Who       What
--   ===========  ========  =================================================
--   14-MAY-2005  Tim Hall  Initial Creation
-- --------------------------------------------------------------------------

g_sep         VARCHAR2(5)  := ',';

PROCEDURE generate (p_dir     IN  VARCHAR2,
                    p_file    IN  VARCHAR2,
                    p_query   IN  VARCHAR2) AS
  l_cursor    PLS_INTEGER;
  l_rows      PLS_INTEGER;
  l_col_cnt   PLS_INTEGER;
  l_desc_tab  DBMS_SQL.desc_tab;
  l_buffer    VARCHAR2(32767);

  l_file      UTL_FILE.file_type;
BEGIN
  l_cursor := DBMS_SQL.open_cursor;
  DBMS_SQL.parse(l_cursor, p_query, DBMS_SQL.native);

  DBMS_SQL.describe_columns (l_cursor, l_col_cnt, l_desc_tab);

  FOR i IN 1 .. l_col_cnt LOOP
    DBMS_SQL.define_column(l_cursor, i, l_buffer, 32767 );
  END LOOP;

  l_rows := DBMS_SQL.execute(l_cursor);

  l_file := UTL_FILE.fopen(p_dir, p_file, 'w', 32767);

  -- Output the column names.
  FOR i IN 1 .. l_col_cnt LOOP
    IF i > 1 THEN
      UTL_FILE.put(l_file, g_sep);
    END IF;
    UTL_FILE.put(l_file, l_desc_tab(i).col_name);
  END LOOP;
  UTL_FILE.new_line(l_file);

  -- Output the data.
  LOOP
    EXIT WHEN DBMS_SQL.fetch_rows(l_cursor) = 0;

    FOR i IN 1 .. l_col_cnt LOOP
      IF i > 1 THEN
        UTL_FILE.put(l_file, g_sep);
      END IF;

      DBMS_SQL.COLUMN_VALUE(l_cursor, i, l_buffer);
      UTL_FILE.put(l_file, l_buffer);
    END LOOP;
    UTL_FILE.new_line(l_file);
  END LOOP;

  UTL_FILE.fclose(l_file);
EXCEPTION
  WHEN OTHERS THEN
    IF UTL_FILE.is_open(l_file) THEN
      UTL_FILE.fclose(l_file);
    END IF;
    IF DBMS_SQL.is_open(l_cursor) THEN
      DBMS_SQL.close_cursor(l_cursor);
    END IF;
    RAISE;
END generate;

END csv;
/
SHOW ERRORS
