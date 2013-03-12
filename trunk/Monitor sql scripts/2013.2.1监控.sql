select * from GUWANG_PRODUCT_GROUP_MID;

select count(*) from WLOGINOPR201302;

select owner, table_name, partition_name, num_rows,stale_stats, to_char(last_analyzed, 'yyyy-mm-dd hh24:mi:ss') last_analyzed 
from dba_tab_statistics 
--where table_name='WLOGINOPR201302';
--where table_name='GUWANG_PRODUCT_GROUP_MID';
where table_name='SERV_PRODUCT_ATTR';

--PRODUCT.GUWANG_PRODUCT_GROUP_MID


select owner, object_name, object_type from dba_objects where object_name='DWO_IMEI';
select * from dba_synonyms where synonym_name='DWO_IMEI';



select distinct SQL_ID,PLAN_HASH_VALUE,to_char(TIMESTAMP,'yyyy-mm-dd hh24:mi:ss')  TIMESTAMP
from dba_hist_sql_plan 
where SQL_ID='449bq9ftbthnt' 
order by TIMESTAMP;

col options for a15;
col operation for a20;
col object_name for a25;
col timestamp for a20;
select plan_hash_value,id,operation,options,object_name,depth,cost,to_char(TIMESTAMP,'yyyy-mm-dd hh24:mi:ss') TIMESTAMP
    from DBA_HIST_SQL_PLAN  
    where sql_id ='449bq9ftbthnt' 
    and plan_hash_value in ('1168666225')
    order by  plan_hash_value,ID,TIMESTAMP;
    
    
  select * from dba_ind_columns where table_name='SRESPHONEORDERHIS';  
  select owner, table_name, index_name, status from dba_indexes where table_name='SRESPHONEORDERHIS';
  select * from dba_tab_statistics where table_name='SRESPHONEORDERHIS' AND partition_name like 'PART_2013%';
  select count(1) from SRESPHONEORDERHIS partition(PART_201302);
    
    
  
SELECT SUBSTR(sql_text, 1, 80) "SQL",
invalidations
FROM v$sqlarea
ORDER BY invalidations DESC;
    

select count(1) from wSndCmdDayInfo201302;
select * from dba_tables where table_name=upper('wSndCmdDayInfo201302');
select * from dba_part_tables where table_name=upper('wSndCmdDayInfo201302');


select count(*) from SRESPHONEORDERHIS;

select count(*) from SRESORDERSTATUS;
