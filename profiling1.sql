#With these queries, you can find the maximum precision values, which is an output comparing all the values of a numeric column across integer and decimal values. See the following code:

select
	'SELECT ''' || i.table_schema || '''' || ' as table_schema, ' || '''' || i.table_name || '''' || ' as table_name,''' || i.column_name || '''' || ' as col_name,MAX(LENGTH(replace(' || i.column_name || '::CHARACTER VARYING,''.'',''''))) as max_precision,
    MAX(CASE When position(''.'' in ' || i.column_name || '::CHARACTER VARYING) > 0 THEN
    LENGTH(SUBSTRING (' || column_name || '::CHARACTER VARYING,position(''.'' in ' || column_name || '::CHARACTER VARYING)+1))
    ELSE 0 end) max_scale
    from ' || tablist.table_schema || '.' || tablist.table_name || ';'
from
	information_schema.columns i,
	t_profile_candidate tablist
where
	i.table_name = tablist.table_name
	and i.table_schema = tablist.table_schema
	and data_type like 'numeric'
	and (numeric_precision is null
		or numeric_precision > 38)
order by
	tablist.table_schema,
	tablist.table_name,
	i.ordinal_position;

#Create a table and make an entry of the table schemas and table names in scope of the migration:

create table t_profile_candidate(
table_schema varchar(100),
table_name varchar(100)
);

#Retrieve maximum scale and precision for numeric columns
#Run the following query to dynamically generate list of queries that you can execute to extract the maximum precision and maximum scale for any numeric columns that have an undefined length or a defined length of more than 38.



#Retrieve maximum precision (whole number part of numeric data with scale)
#Run the following query to dynamically generate list of queries that you can run to extract the maximum precision and maximum scale for any numeric columns that have an undefined length or a defined length of more than 38.

#These queries can help you find the maximum precision value by comparing all the values of a column, ignoring the decimal part. You can always decide on a generic rule of fixed scale and round the decimal part for relevant column data during migration. However, if the whole number part is more than the defined length, it will fail to load.

select
	'SELECT ''' || i.table_schema || '''' || ' as table_schema, ' || '''' || i.table_name || '''' || ' as table_name,''' || i.column_name || '''' || ' as col_name,
    MAX(LENGTH(TRUNC(' || i.column_name || ') :: character varying)) as trunc_col_length
    from ' || tablist.table_schema || '.' || tablist.table_name || ';'
from
	information_schema.columns i,
	t_profile_candidate tablist
where
	i.table_name = tablist.table_name
	and i.table_schema = tablist.table_schema
	and data_type like 'numeric'
	and (numeric_precision is null
		or numeric_precision > 38)
order by
	tablist.table_schema,
	tablist.table_name,
	i.ordinal_position;

#Retrieve maximum character length for character columns
#Run the following query to dynamically generate a list of queries that you can run to extract the maximum character length for Greenplum table columns that have either a defined or undefined length.

#These queries can help you find the following:

#	defined_length – The defined length of the Greenplum character column.

#	max_datalength – The maximum length of the Greenplum character column based on data on a given point of time.
#	max_octetlength – The maximum octet length of the Greenplum character column based on data on a given instance.
#	diff_length_octet – The difference between the defined length and maximum data length. This column is not mandatory for this profiling; it signifies the columns that have multi-byte characters.

select
	'SELECT ''' || i.table_schema || '''' || ' as table_schema,' || '''' || i.table_name || '''' || ' as table_name, ''' || i.column_name || ''' as col_name,''' || i.data_type || ''' as data_type , ' ||
	(case
		when i.character_maximum_length is not null
                then i.character_maximum_length
		else 0
	end)|| ' as defined_length, MAX(length("' || i.column_name || '")) AS max_datalength, MAX(OCTET_LENGTH("' || i.column_name || '")) AS max_octetlength, ' ||       
           'MAX(OCTET_LENGTH ("' || i.column_name || '")) -MAX(LENGTH("' || i.column_name || '")) as diff_length_octet
    from ' || tablist.table_schema || '.' || tablist.table_name || ';'
from
	information_schema.columns i,
	t_profile_candidate tablist
where
		i.table_name = tablist.table_name
	and i.table_schema = tablist.table_schema
	and data_type like '%char%'
order by
		tablist.table_schema,
		tablist.table_name,
		i.ordinal_position;
