#Sample scripts of tables to store profiling data and stored procedures The following is a table creation script and stored procedure to retrieve and store the maximum scale and precision for numeric columns:

create table gpscaleprecision ( table_schema varchar(100) NOT NULL, table_name varchar(100) NOT NULL, col_name varchar(100) NOT NULL, max_precision numeric, max_scale numeric );

CREATE OR REPLACE FUNCTION public.sp_getdatatype_allnumeric() RETURNS void LANGUAGE plpgsql VOLATILE AS $$

DECLARE x int; varquery varchar :=''; rec RECORD; begin truncate table gpscaleprecision; drop table if exists queryplaceholder; create temp table queryplaceholder(query_text varchar);

insert into queryplaceholder SELECT
   'SELECT '''||i.table_schema||''''||' as table_schema, '||''''||i.table_name||''''||' as table_name,'''||i.column_name||''''||' as col_name,MAX(LENGTH(replace('||i.column_name||'::CHARACTER VARYING,''.'',''''))) as max_precision,
   MAX(CASE When position(''.'' in '||i.column_name||'::CHARACTER VARYING) > 0 THEN
   LENGTH(SUBSTRING ('||i.column_name||'::CHARACTER VARYING,position(''.'' in '||i.column_name||'::CHARACTER VARYING)+1))
   ELSE 0 end) max_scale
   from ' || tablist.table_schema || '.' || tablist.table_name 
   from information_schema.columns i,
   t_profile_candidate tablist
   where i.table_name = tablist.table_name
   and i.table_schema = tablist.table_schema
   and data_type like 'numeric'
   and (numeric_precision is null or numeric_precision > 38)
   order by tablist.table_schema, tablist.table_name, i.ordinal_position;

FOR rec IN SELECT query_text FROM queryplaceholder
LOOP
   execute 'INSERT INTO gpscaleprecision  ' ||rec.query_text;

END loop ;
END;

$$ ;
