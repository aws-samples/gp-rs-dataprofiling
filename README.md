
**This Repo contains code and procedures to select optimal data structure while migrating from Greenplum to Amazon Redshift**

* Data Structure profiling is essential to avoid numeric overflow or character values that are too long. This repositroy consists of list of SQL's queries **you can execute on Greenplum Database to come up with right sizing data strcutures 

* The profiling result is based on the dataset for a particular instance of time. Always execute SQL;s in your latest Greenplum production environment to capture the right results . You need to determine the best time window for the same to avoid a performance bottleneck in production. Running in any other environment that gets the Greenplum production data synced with lag, even for a couple of days or weeks, works for most implementations as long as there is no drastic change in the data structures.


## Data profiling
The following example data profiling procedure uses the sample queries defined in the prior sections.

1.	Create tables to store your profiling result based on the type of profiling query you plan to use.
2.	Create a stored procedure with required logic to populate the table.
    a. Add necessary input parameters like tables or schemas for which you want to run the profiling as a set. 
    b. In the executable block of the program, create a temporary table to hold the output of the dynamic query results.
    c. Execute all the queries in the temporary table using a loop construct or bulk execution logic with a union of all queries, and store the output in       the profiling result table you created.
    d.As a best practice, drop the temporary table at the beginning of the script conditionally if it exists.
    e.Add debug statements as necessary to track the progress.
    
3.	Review the profiling result and make changes as necessary to accommodate the overflow numeric column candidates and multi-byte VARCHAR/CHAR fields in Amazon Redshift.
  a.For character data columns, you can always make the column length four times greater than the value defined or max_datalength. However, this doesn’t align with the best practices explained earlier. 
    i.	If the column length is defined, set the VARCHAR column length as 120% of the higher of defined_length and max_octetlength.
    ii.	If the column length is not defined, set the VARCHAR column length as 120% of the higher of max_datalength and max_octetlength.
    iii.	During migration, if any other columns fail with the message that the value is too long for the character type, you need to handle these on a      case-by-case basis. The chances of encountering this are minimal and depend on the quality of the profiled data and the gap between the profiling and    actual migration date.

## Enhancing Greenplum DDL

add_varchar_lengths.sh: Change unbounded varchar and text columns in a given schema to have length constraints in Greenplum. This helps in the migration to Redshift with AWS Schema Conversion Tool (SCT) and avoids treating these columns as LOBs.

## Security

See [CONTRIBUTING](CONTRIBUTING.md#security-issue-notifications) for more information.

## License

This library is licensed under the MIT-0 License. See the LICENSE file.

