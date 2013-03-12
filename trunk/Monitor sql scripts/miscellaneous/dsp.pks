CREATE OR REPLACE PACKAGE dsp AS
-- --------------------------------------------------------------------------
-- Name         : http://www.oracle-base.com/dba/miscellaneous/dsp.pks
-- Author       : Tim Hall
-- Description  : An extension of the DBMS_OUTPUT package.
-- Requirements : http://www.oracle-base.com/dba/miscellaneous/dsp.pkb
-- Ammedments   :
--   When         Who       What
--   ===========  ========  =================================================
--   08-JAN-2002  Tim Hall  Initial Creation
--   04-APR-2005  Tim Hall  Store last call. Add get_last_prefix and
--                          get_last_data to allow retrieval.
--                          Switch from date to timestamp for greater accuracy.
-- --------------------------------------------------------------------------

  PROCEDURE reset_defaults;

  PROCEDURE show_output_on;
  PROCEDURE show_output_off;

  PROCEDURE show_date_on;
  PROCEDURE show_date_off;

  PROCEDURE line_wrap_on;
  PROCEDURE line_wrap_off;

  PROCEDURE set_max_width (p_width  IN  NUMBER);

  PROCEDURE set_date_format (p_date_format  IN  VARCHAR2);

  PROCEDURE file_output_on (p_file_dir   IN  VARCHAR2 DEFAULT NULL,
                            p_file_name  IN  VARCHAR2 DEFAULT NULL);

  PROCEDURE file_output_off;

  FUNCTION get_last_prefix
    RETURN VARCHAR2;

  FUNCTION get_last_data
    RETURN VARCHAR2;

  PROCEDURE line (p_data    IN  VARCHAR2);
  PROCEDURE line (p_data    IN  NUMBER);
  PROCEDURE line (p_data    IN  BOOLEAN);
  PROCEDURE line (p_data    IN  DATE,
                  p_format  IN  VARCHAR2 DEFAULT 'DD-MON-YYYY HH24:MI:SS.FF');

  PROCEDURE line (p_prefix  IN  VARCHAR2,
                  p_data    IN  VARCHAR2);
  PROCEDURE line (p_prefix  IN  VARCHAR2,
                  p_data    IN  NUMBER);
  PROCEDURE line (p_prefix  IN  VARCHAR2,
                  p_data    IN  BOOLEAN);
  PROCEDURE line (p_prefix  IN  VARCHAR2,
                  p_data    IN  DATE,
                  p_format  IN  VARCHAR2 DEFAULT 'DD-MON-YYYY HH24:MI:SS.FF');

END dsp;
/

SHOW ERRORS

