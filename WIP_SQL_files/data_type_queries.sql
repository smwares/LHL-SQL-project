-- Run once to get all column names
SELECT column_name FROM INFORMATION_SCHEMA.columns
WHERE table_name = 'sales_report';

-- First query gets the total amount of rows, useful for checking uniqueness and for null values
SELECT 'total columns', COUNT(*) FROM sales_report

UNION

-- Second query gets a count of null columns
SELECT 'null columns', COUNT(*) FROM sales_report
WHERE ratio IS NULL

UNION

-- Third query gets the number of distinct values, useful for checking if every single row is unique
SELECT 'unique ratio', COUNT(DISTINCT(ratio)) FROM sales_report

UNION

-- Last query checks the type of data in each row and gives a count of each types of data
SELECT type_name, COUNT(type_name)
FROM (SELECT determine_type(ratio) AS type_name FROM sales_report) as data_types
GROUP BY type_name;

-- Query to determine how many decimal places to keep
SELECT MAX(POSITION('.' IN sentiment_score) - 1) AS left_of_decimal,
		MAX(LENGTH(sentiment_score) - POSITION('.' IN sentiment_score)) AS right_of_decimal
FROM sales_report
ORDER BY left_of_decimal;