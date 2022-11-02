#!/bin/bash
set -e

table_schema="$1"
if [ "${table_schema}" == "" ]; then
	echo "ERROR: You must provide the name of the schema you wish to fix the data type lengths."
	exit 1
fi
schema_check=$(psql -t -A -c "SELECT count(*) FROM pg_namespace WHERE nspname = '${table_schema}' and nspname not like 'pg_%' and nspname <> 'gp_toolkit'")
if [ "${schema_check}" -eq "0" ]; then
	echo "ERROR: Schema \"${table_schema}\" not found!"
	exit 1
fi
drop_indexes()
{
	#called from alter_tables()
	table_name_check="$1"
	column_name_check="$2"
	for i in $(psql -t -A -c "SELECT i.relname AS index_name, ix.indisunique FROM pg_class t JOIN pg_namespace ts ON t.relnamespace = ts.oid JOIN (select indisunique, indexrelid, indrelid, unnest(indkey) AS indkey FROM pg_index) ix ON t.oid = ix.indrelid JOIN pg_attribute a on t.oid = a.attrelid and a.attnum = ix.indkey JOIN pg_class i on i.oid = ix.indexrelid JOIN pg_namespace i_s on i.relnamespace = i_s.oid WHERE t.relkind = 'r' AND ts.nspname = '${table_schema}' AND t.relname = '${table_name_check}' AND a.attname = '${column_name_check}'"); do
		index_name=$(echo $i | awk -F '|' '{print $1}')
		unique_ind=$(echo $i | awk -F '|' '{print $2}')
		if [ "$unique_ind" == "t" ]; then
			psql -e -c "ALTER TABLE \"${table_schema}\".\"${table_name_check}\" DROP CONSTRAINT \"${index_name}\""
		else
			psql -e -c "DROP INDEX IF EXISTS \"${table_schema}\".\"${index_name}\""
		fi
	done
}
alter_tables()
{
	for table_name in $(psql -t -A -c "SELECT c.relname FROM pg_class c JOIN pg_namespace n ON c.relnamespace = n.oid JOIN pg_attribute a ON c.oid = a.attrelid JOIN pg_type t ON a.atttypid = t.oid WHERE c.relkind = 'r' AND c.oid NOT IN (SELECT c1.oid FROM pg_class c1 JOIN pg_inherits i ON c1.oid = i.inhrelid WHERE c1.relkind = 'r') AND n.nspname = '${table_schema}' AND t.typname IN ('varchar', 'text') AND a.atttypmod = -1 GROUP BY c.relname"); do
		test_for_data=$(psql -t -A -c "SELECT 1 FROM ${table_schema}.${table_name} limit 1" | wc -l)
		if [ "$test_for_data" -gt "0" ]; then
			column_count="0"
			columns=()
			for column_name in $(psql -t -A -c "SELECT a.attname FROM pg_class c JOIN pg_namespace n ON c.relnamespace = n.oid JOIN pg_attribute a ON c.oid = a.attrelid JOIN pg_type t ON a.atttypid = t.oid WHERE c.relkind = 'r' AND c.relname = '${table_name}' AND c.oid NOT IN (SELECT c1.oid FROM pg_class c1 JOIN pg_inherits i ON c1.oid = i.inhrelid WHERE c1.relkind = 'r') AND n.nspname = '${table_schema}' AND t.typname in ('varchar', 'text') AND a.atttypmod = -1 order by a.attnum"); do

				drop_indexes "${table_name}" "${column_name}"
				column_count=$((column_count+1))
				columns+=(${column_name})
				if [ "$column_count" -eq "1" ]; then
					sql_text="SELECT max(coalesce(length(\"${column_name}\"),0))"
				else
					sql_text+=", max(coalesce(length(\"${column_name}\"),0))"
				fi
			done
			if [ "$column_count" -gt "0" ]; then
				sql_text+=" FROM ${table_schema}.${table_name}"
				i=0
				SAVEIFS=$IFS
				IFS="|"
				for column_max in $(psql -t -A -c "${sql_text}"); do
					column_name=${columns[$i]}
					if [ "${column_max}" -eq "0" ]; then
						alter_sql="ALTER TABLE \"${table_schema}\".\"${table_name}\" ALTER COLUMN \"${column_name}\" TYPE varchar(10)"
					elif [ "${column_max}" -lt "50" ]; then
						alter_sql="ALTER TABLE \"${table_schema}\".\"${table_name}\" ALTER COLUMN \"${column_name}\" TYPE varchar(50)"
					elif [[ "${column_max}" -ge "50" && "${column_max}" -lt "100" ]]; then
						alter_sql="ALTER TABLE \"${table_schema}\".\"${table_name}\" ALTER COLUMN \"${column_name}\" TYPE varchar(100)"
					elif [[ "${column_max}" -ge "100" && "${column_max}" -lt "500" ]]; then
						alter_sql="ALTER TABLE \"${table_schema}\".\"${table_name}\" ALTER COLUMN \"${column_name}\" TYPE varchar(500)"
					elif [[ "${column_max}" -ge "500" && "${column_max}" -lt "1000" ]]; then
						alter_sql="ALTER TABLE \"${table_schema}\".\"${table_name}\" ALTER COLUMN \"${column_name}\" TYPE varchar(1000)"
					elif [ "${column_max}" -ge "1000" ]; then
						alter_sql="ALTER TABLE \"${table_schema}\".\"${table_name}\" ALTER COLUMN \"${column_name}\" TYPE varchar(30000)"
					fi
					echo "${alter_sql}"
					psql -c "${alter_sql}"
					i=$((i+1))
				done
				IFS=$SAVEIFS
			fi
		else
			for column_name in $(psql -t -A -c "SELECT a.attname FROM pg_class c JOIN pg_namespace n ON c.relnamespace = n.oid JOIN pg_attribute a ON c.oid = a.attrelid JOIN pg_type t ON a.atttypid = t.oid WHERE c.relkind = 'r' AND c.relname = '${table_name}' AND c.oid NOT IN (SELECT c1.oid FROM pg_class c1 JOIN pg_inherits i ON c1.oid = i.inhrelid WHERE c1.relkind = 'r') AND n.nspname = '${table_schema}' AND t.typname in ('varchar', 'text') AND a.atttypmod = -1"); do
				drop_indexes "${table_name}" "${column_name}"
				alter_sql="ALTER TABLE \"${table_schema}\".\"${table_name}\" ALTER COLUMN \"${column_name}\" TYPE varchar(500)"
				psql -e -c "${alter_sql}"
			done
		fi
	done
}

alter_tables
