CREATE OR REPLACE PACKAGE BODY dsp AS
-- --------------------------------------------------------------------------
-- Name         : http://www.oracle-base.com/dba/miscellaneous/dsp.pkb
-- Author       : Tim Hall
-- Description  : An extension of the DBMS_OUTPUT package.
-- Requirements : http://www.oracle-base.com/dba/miscellaneous/dsp.pks
-- Ammedments   :
--   When         Who       What
--   ===========  ========  =================================================
--   08-JAN-2002  Tim Hall  Initial Creation.
--   04-APR-2005  Tim Hall  Store last call. Add get_last_prefix and
--                          get_last_data to allow retrieval.
--                          Switch from date to timestamp for greater accuracy.
-- --------------------------------------------------------------------------

-- Package Variables
g_show_output  BOOLEAN         := FALSE;
g_show_date    BOOLEAN         := FALSE;
g_line_wrap    BOOLEAN         := TRUE;
g_max_width    NUMBER(10)      := 255;
g_date_format  VARCHAR2(32767) := 'DD-MON-YYYY HH24:MI:SS.FF';
g_file_dir     VARCHAR2(32767) := NULL;
g_file_name    VARCHAR2(32767) := NULL;
g_last_prefix  VARCHAR2(32767) := NULL;
g_last_data    VARCHAR2(32767) := NULL;

-- Hidden Methods
PROCEDURE display (p_prefix  IN  VARCHAR2,
                   p_data    IN  VARCHAR2);
PROCEDURE wrap_line (p_data  IN  VARCHAR2);
PROCEDURE output (p_data  IN  VARCHAR2);


-- Exposed Methods

-- --------------------------------------------------------------------------
PROCEDURE reset_defaults IS
-- --------------------------------------------------------------------------
BEGIN
  g_show_output  := FALSE;
  g_show_date    := FALSE;
  g_line_wrap    := TRUE;
  g_max_width    := 255;
  g_date_format  := 'DD-MON-YYYY HH24:MI:SS.FF';
END;
-- --------------------------------------------------------------------------


-- --------------------------------------------------------------------------
PROCEDURE show_output_on IS
-- --------------------------------------------------------------------------
BEGIN
  g_show_output := TRUE;
END;
-- --------------------------------------------------------------------------


-- --------------------------------------------------------------------------
PROCEDURE show_output_off IS
-- --------------------------------------------------------------------------
BEGIN
  g_show_output := FALSE;
END;
-- --------------------------------------------------------------------------


-- --------------------------------------------------------------------------
PROCEDURE show_date_on IS
-- --------------------------------------------------------------------------
BEGIN
  g_show_date := TRUE;
END;
-- --------------------------------------------------------------------------


-- --------------------------------------------------------------------------
PROCEDURE show_date_off IS
-- --------------------------------------------------------------------------
BEGIN
  g_show_date := FALSE;
END;
-- --------------------------------------------------------------------------


-- --------------------------------------------------------------------------
PROCEDURE line_wrap_on IS
-- --------------------------------------------------------------------------
BEGIN
  g_line_wrap := TRUE;
END;
-- --------------------------------------------------------------------------


-- --------------------------------------------------------------------------
PROCEDURE line_wrap_off IS
-- --------------------------------------------------------------------------
BEGIN
  g_line_wrap := FALSE;
END;
-- --------------------------------------------------------------------------


-- --------------------------------------------------------------------------
PROCEDURE set_max_width (p_width  IN  NUMBER) IS
-- --------------------------------------------------------------------------
BEGIN
  g_max_width := p_width;
END;
-- --------------------------------------------------------------------------


-- --------------------------------------------------------------------------
PROCEDURE set_date_format (p_date_format  IN  VARCHAR2) IS
-- --------------------------------------------------------------------------
BEGIN
  g_date_format := p_date_format;
END;
-- --------------------------------------------------------------------------


-- --------------------------------------------------------------------------
PROCEDURE file_output_on (p_file_dir   IN  VARCHAR2 DEFAULT NULL,
                          p_file_name  IN  VARCHAR2 DEFAULT NULL) IS
-- --------------------------------------------------------------------------
BEGIN
  g_file_dir  := p_file_dir;
  g_file_name := p_file_name;
END;
-- --------------------------------------------------------------------------


-- --------------------------------------------------------------------------
PROCEDURE file_output_off IS
-- --------------------------------------------------------------------------
BEGIN
  g_file_dir  := NULL;
  g_file_name := NULL;
END;
-- --------------------------------------------------------------------------


-- --------------------------------------------------------------------------
FUNCTION get_last_prefix
  RETURN VARCHAR2 IS
-- --------------------------------------------------------------------------
BEGIN
  RETURN g_last_prefix;
END;
-- --------------------------------------------------------------------------


-- --------------------------------------------------------------------------
FUNCTION get_last_data
  RETURN VARCHAR2 IS
-- --------------------------------------------------------------------------
BEGIN
  RETURN g_last_data;
END;
-- --------------------------------------------------------------------------


-- --------------------------------------------------------------------------
PROCEDURE line (p_data  IN  VARCHAR2) IS
-- --------------------------------------------------------------------------
BEGIN
  display (NULL, p_data);
END;
-- --------------------------------------------------------------------------


-- --------------------------------------------------------------------------
PROCEDURE line (p_data  IN  NUMBER) IS
-- --------------------------------------------------------------------------
BEGIN
  display (NULL, p_data);
END;
-- --------------------------------------------------------------------------


-- --------------------------------------------------------------------------
PROCEDURE line (p_data  IN  BOOLEAN) IS
-- --------------------------------------------------------------------------
BEGIN
  line (NULL, p_data);
END;
-- --------------------------------------------------------------------------


-- --------------------------------------------------------------------------
PROCEDURE line (p_data    IN  DATE,
                p_format  IN  VARCHAR2 DEFAULT 'DD-MON-YYYY HH24:MI:SS.FF') IS
-- --------------------------------------------------------------------------
BEGIN
  line (NULL, p_data, p_format);
END;
-- --------------------------------------------------------------------------


-- --------------------------------------------------------------------------
PROCEDURE line (p_prefix  IN  VARCHAR2,
                p_data    IN  VARCHAR2) IS
-- --------------------------------------------------------------------------
BEGIN
  display (p_prefix, p_data);
END;
-- --------------------------------------------------------------------------


-- --------------------------------------------------------------------------
PROCEDURE line (p_prefix  IN  VARCHAR2,
                p_data    IN  NUMBER) IS
-- --------------------------------------------------------------------------
BEGIN
  display (p_prefix, TO_CHAR(p_data));
END;
-- --------------------------------------------------------------------------


-- --------------------------------------------------------------------------
PROCEDURE line (p_prefix  IN  VARCHAR2,
                p_data    IN  BOOLEAN) IS
-- --------------------------------------------------------------------------
BEGIN
  IF p_data THEN
    display (p_prefix, 'TRUE');
  ELSE
    display (p_prefix, 'FALSE');
  END IF;
END;
-- --------------------------------------------------------------------------


-- --------------------------------------------------------------------------
PROCEDURE line (p_prefix  IN  VARCHAR2,
                p_data    IN  DATE,
                p_format  IN  VARCHAR2 DEFAULT 'DD-MON-YYYY HH24:MI:SS.FF') IS
-- --------------------------------------------------------------------------
BEGIN
  display (p_prefix, TO_CHAR(p_data, p_format));
END;
-- --------------------------------------------------------------------------


-- --------------------------------------------------------------------------
PROCEDURE display (p_prefix  IN  VARCHAR2,
                   p_data    IN  VARCHAR2) IS
-- --------------------------------------------------------------------------
  l_data  VARCHAR2(32767) := p_data;
BEGIN
  g_last_prefix := p_prefix;
  g_last_data   := p_data;
  IF g_show_output THEN
    IF l_data IS NULL THEN
      l_data := '<NULL>';
    END IF;

    IF p_prefix IS NOT NULL THEN
      l_data := p_prefix || ' : ' || l_data;
    END IF;

    IF g_show_date THEN
      l_data := TO_CHAR(SYSTIMESTAMP, g_date_format) || ' : ' || l_data;
    END IF;

    IF Length(l_data) > g_max_width THEN
      IF g_line_wrap THEN
        wrap_line (l_data);
      ELSE
        l_data := SUBSTR(l_data, 1, g_max_width);
        output (l_data);
      END IF;
    ELSE
      output (l_data);
    END IF;
  END IF;
END;
-- --------------------------------------------------------------------------


-- --------------------------------------------------------------------------
PROCEDURE wrap_line (p_data  IN  VARCHAR2) IS
-- --------------------------------------------------------------------------
  l_data  VARCHAR2(32767) := p_data;
BEGIN
  LOOP
    display (NULL, SUBSTR(l_data, 1, g_max_width));
    l_data := SUBSTR(l_data, g_max_width + 1);
    EXIT WHEN l_data IS NULL;
  END LOOP;
END;
-- --------------------------------------------------------------------------


-- --------------------------------------------------------------------------
PROCEDURE output (p_data  IN  VARCHAR2) IS
-- --------------------------------------------------------------------------
BEGIN
  IF g_file_dir IS NULL OR g_file_name IS NULL THEN
    DBMS_OUTPUT.put_line(p_data);
  ELSE
    DECLARE
      l_file  UTL_FILE.file_type;
    BEGIN
      l_file := UTL_FILE.fopen (g_file_dir, g_file_name, 'A');
      UTL_FILE.put_line(l_file, p_data);
      UTL_FILE.fclose (l_file);
    EXCEPTION
      WHEN OTHERS THEN
        UTL_FILE.fclose (l_file);
    END;
  END IF;
END;
-- --------------------------------------------------------------------------

END dsp;
/

SHOW ERRORS

