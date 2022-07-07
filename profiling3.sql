#The following is a table creation script and stored procedure to retrieve and store the maximum precision for numeric columns ignoring scale:

create table numeric_trunc_length_profile  (
table_schema varchar(100) NOT NULL,
table_name varchar(100) NOT NULL,
col_name varchar(100) NOT NULL,
trunc_col_length int4
);


CREATE OR REPLACE FUNCTION public.sp_getdatatypenumeric(pschema varchar)
	RETURNS void
	LANGUAGE plpgsql
	VOLATILE
AS $$
	

DECLARE
x int :=0;
varquery Text :='';
rec RECORD;
begin
    drop table if exists queryplaceholdernumeric;
    CREATE TEMP TABLE queryplaceholdernumeric (query_text varchar(65000));
    Truncate table numeric_trunc_length_profile;   
    insert into queryplaceholdernumeric SELECT
     'SELECT '''||i.table_schema||''''||' as table_schema, '||''''||i.table_name||''''||' as table_name,'''||i.column_name||''''||' as col_name,
    MAX(LENGTH(TRUNC('||i.column_name||') :: character varying)) as trunc_col_length
    from ' || pschema || '.' || tablist.table_name || ';'
    from information_schema.columns i,
    t_profile_candidate tablist
    where i.table_name = tablist.table_name
    and i.table_schema = tablist.table_schema
    and tablist.table_schema = pschema
    and data_type like 'numeric'
    and (numeric_precision is null or numeric_precision > 38)
    order by tablist.table_schema, tablist.table_name, i.ordinal_position;
    FOR rec IN SELECT query_text FROM queryplaceholdernumeric
    LOOP
      x:= x+ 1;
      RAISE INFO 'Counter:%', x;
      RAISE INFO 'Our query inside loop:%', rec.query_text;
      EXECUTE 'INSERT INTO numeric_trunc_length_profile   ' ||rec.query_text;
		
    END loop ;
END;


$$
;

