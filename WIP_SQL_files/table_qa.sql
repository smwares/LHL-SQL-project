--get count of columns per table to ensure the right amount of columns are in the tables
SELECT table_name, COUNT(*) AS column_count
FROM INFORMATION_SCHEMA.COLUMNS
WHERE table_schema = 'public'
GROUP BY table_name
ORDER BY table_name;

--get number of rows per table
SELECT relname AS table_name, n_tup_ins AS row_count
FROM pg_stat_all_tables
WHERE schemaname = 'public'
ORDER BY relname;