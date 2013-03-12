CREATE OR REPLACE PACKAGE trc AS
-- --------------------------------------------------------------------------
-- Name         : http://www.oracle-base.com/dba/miscellaneous/trc.pks
-- Author       : Tim Hall
-- Description  : A simple mechanism for tracing information to a table.
-- Requirements : trc.pkb, dsp.pks, dsp.pkb and:
--
-- CREATE TABLE trace_data (
-- id           NUMBER(10)      NOT NULL,
-- prefix       VARCHAR2(50),
-- data         VARCHAR2(2000)  NOT NULL,
-- trc_level    NUMBER(2)       NOT NULL,
-- created_date DATE            NOT NULL,
-- created_by   VARCHAR2(50)    NOT NULL);
--                       
-- ALTER TABLE trace_data ADD (CONSTRAINT trc_pk PRIMARY KEY (id));
-- 
-- CREATE SEQUENCE trc_seq;
-- 
-- Ammedments  :
--   When         Who       What
--   ===========  ========  =================================================
--   08-JAN-2002  Tim Hall  Initial Creation
-- --------------------------------------------------------------------------

  PROCEDURE reset_defaults;

  PROCEDURE trace_on;
  PROCEDURE trace_off;
  
  PROCEDURE set_date_format (p_date_format IN VARCHAR2 DEFAULT 'DD-MON-YYYY HH24:MI:SS');
  
  PROCEDURE line (p_prefix     IN  VARCHAR2,
                  p_data       IN  VARCHAR2,
                  p_trc_level  IN  NUMBER   DEFAULT 5,
                  p_trc_user   IN  VARCHAR2 DEFAULT USER);

  PROCEDURE display (p_trc_level  IN  NUMBER   DEFAULT NULL,
                     p_trc_user   IN  VARCHAR2 DEFAULT NULL,
                     p_from_date  IN  DATE     DEFAULT NULL,
                     p_to_date    IN  DATE     DEFAULT NUll);
END trc;
/

SHOW ERRORS

