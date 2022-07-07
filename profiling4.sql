#The following is a table creation script and stored procedure to retrieve the maximum character length for character columns:

create table gpcharoctetlength  (
table_schema varchar(100) NOT NULL,
table_name varchar(100) NOT NULL,
col_name varchar(100) NOT NULL,
data_type varchar(40) NOT NULL,
defined_length numeric,
max_datalength numeric,
max_octetlength numeric,
diff_length_octet numeric
);


CREATE OR REPLACE FUNCTION public.sp_getchardatatype(pschema varchar)
	RETURNS void
	LANGUAGE plpgsql
	VOLATILE
AS $$
    

DECLARE
x int :=0;
varquery varchar :='';
rec RECORD;
begin
    drop table if exists queryplaceholder;
    CREATE  table queryplaceholder (query_text varchar);    
    insert into queryplaceholder SELECT
    'SELECT '''||i.table_schema||''''||' as table_schema,'||''''||i.table_name||''''||' as table_name, '''||i.column_name||''' as col_name,'''||i.data_type||''' as data_type , '||(case when i.character_maximum_length is not null
                then i.character_maximum_length else 0 end)||' as defined_length, MAX(length("'||i.column_name||'")) AS max_datalength, MAX(OCTET_LENGTH("'||i.column_name||'")) AS max_octetlength, '||       
           'MAX(OCTET_LENGTH ("'||i.column_name||'")) -MAX(LENGTH("'||i.column_name||'")) as diff_length_octet
    from ' || pschema || '.' || tablist.table_name || ' UNION ALL ' 
    from information_schema.columns i,
    t_profile_candidate tablist
    where i.table_name = tablist.table_name
    and i.table_schema = pschema
    and tablist.table_schema = pschema
    and data_type like '%char%'
    order by tablist.table_schema, tablist.table_name, i.ordinal_position;
    varquery := '';
    FOR rec IN SELECT query_text FROM queryplaceholder
    loop
        x:=x+1;
        varquery := varquery ||'  '|| rec.query_text;
        if MOD(x,100) = 0 then
        	varquery := RTRIM (varquery, 'UNION ALL');
        	EXECUTE 'INSERT INTO gpcharoctetlength  ' ||varquery;
        	x:=0;
            varquery:= '';
        end if;
    END loop ;
    RAISE INFO 'x is is:%', x;
    varquery := RTRIM (varquery, 'UNION ALL');
    RAISE INFO 'Our query is:%', varquery;
   	if x > 0 then
    	EXECUTE 'INSERT INTO gpcharoctetlength  ' ||varquery;
    end if;
END;

$$
;
