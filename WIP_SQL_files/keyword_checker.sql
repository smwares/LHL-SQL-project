-- Create a table that has the column names of all the tables
WITH column_names AS (
	SELECT table_name, column_name FROM information_schema.columns
	WHERE table_schema = 'public'
),
-- Then create a table containing PostgreSQL keywords
keywords_list AS (
	SELECT word	FROM pg_get_keywords()
)

-- Query to determine which column names in which tables are keywords
SELECT cn.table_name, cn.column_name FROM column_names AS cn
JOIN keywords_list AS kl
ON cn.column_name = kl.word;