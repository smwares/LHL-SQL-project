What are your risk areas? Identify and describe them.

The biggest risk areas are the revenue fields that hold a large amount of null values. There are only two tables that have revenue columns, and there is no explicit way to refer them to each other as not only do none of the columns in both the tables have unique values, but also combining fields that should create unique values (e.g. concatenation of visit ID and full visitor ID columns) do not create unique values either. At best, the tables were able to fill in some fields for each other, but there was nowhere near enough data to fill in the null values. While revenue-based calculations based on what's in the tables is possible, due to the vast amount of incomplete data the results will very likely be inaccurate.

Another risk area would be the product category and name fields in the all sessions table. Purely relying on overarching queries will not reliably consolidate the categories as some categories are just brand names and not actual categories themselves and therefore would require more manual adjustments. The name column would require complex regex as there are multiple possible variations on a product name that could appear.  

QA Process:
Describe your QA process and include the SQL queries used to execute it.

First step after importing the CSV files is to determine data types and their character lengths using the following queries:

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

-- UDF to determine what each entry in the column is
CREATE OR REPLACE FUNCTION determine_type(col varchar)
RETURNS varchar
AS
$$
DECLARE
	data_type varchar;
BEGIN
	RETURN (
		SELECT
			CASE
				WHEN col IS NULL
					THEN 'Null'
				WHEN col SIMILAR TO '%\d%' AND col NOT SIMILAR TO '%.%' AND col NOT SIMILAR TO '%[A-Za-z]%'
					THEN 'Integer'
				WHEN col SIMILAR TO '%\d%' AND col SIMILAR TO '%.%' AND col NOT SIMILAR TO '%[A-Za-z]%'
					THEN 'Numeric'
				WHEN col SIMILAR TO '%\D%'
					THEN 'Varchar'
			END AS data_type
	);
END;
$$
LANGUAGE PLPGSQL;

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



Start converting data types next with the following queries:

-- Query to determine what type of numeric data types to use based on minimum and maximum values
-- and to find the largest amount of digits in a single entry
SELECT MIN(ratio::numeric(255,2)) AS minval, MAX(ratio::numeric(255,2)) AS maxval,
		MAX(LENGTH(ratio::varchar)) AS longest
FROM sales_report;

-- Query to convert varchar to float
ALTER TABLE sales_report
	ALTER COLUMN ratio TYPE numeric(32,20)
		USING ratio::numeric(32,20);

-- Query to convert varchar to integer
ALTER TABLE sales_report
	ALTER COLUMN restocking_lead_time TYPE bigint
		USING restocking_lead_time::bigint;

--Query to convert varchar to varchar with char limit
ALTER TABLE analytics
	ALTER COLUMN channel_grouping TYPE varchar(255)
		USING channel_grouping::varchar(255);



Next, query one table at a time.
Table all_sessions:

-- Query to check if combing the two visitor id columns can generate enough unique combinations to be used as the primary key
SELECT COUNT(*) AS total_rows,
		COUNT(DISTINCT(full_visitor_id::varchar || visit_id::varchar)) AS session_id_count
FROM all_sessions;

-- Query to check if there are any negative numbers in numeric columns by sorting the data
SELECT ecommerce_action_step FROM all_sessions
WHERE ecommerce_action_step < 0
ORDER BY ecommerce_action_step;

-- Query to check unique values, minimum and maximum values of numeric columns to check for anomalies
SELECT MIN(ecommerce_action_step) AS min_val, MAX(ecommerce_action_step) AS max_val,
		COUNT(DISTINCT(ecommerce_action_step)) AS unique_val
FROM all_sessions;

-- Query to check relation between ecommerce action type, step and option
SELECT ecommerce_action_type, ecommerce_action_step, ecommerce_action_option
FROM all_sessions
GROUP BY ecommerce_action_type, ecommerce_action_step, ecommerce_action_option
ORDER BY ecommerce_action_type, ecommerce_action_step;

-- Query to return date column in date format to ensure type conversion will work
SELECT to_date(date_info::varchar, 'YYYYMMDD') FROM all_sessions;

-- Query to compare the channel_grouping table to the one in the analytics table to find differences
SELECT DISTINCT(channel_grouping), 'all_sessions' AS table_source
FROM all_sessions

UNION ALL

SELECT DISTINCT(channel_grouping), 'analytics' AS table_source
FROM analytics
ORDER BY channel_grouping, table_source;

-- Query to check names of cities
SELECT DISTINCT(city) FROM all_sessions
ORDER BY city;

-- Query to check names of countries
SELECT DISTINCT(country) FROM all_sessions
ORDER BY country;

-- Query to find cities where they share the same name as cities in other countries
-- This is to check for pairings that do not exist
WITH cities_countries AS (
	SELECT city, country FROM all_sessions
	GROUP BY city, country
)
SELECT * FROM cities_countries
WHERE city IN (
	SELECT city FROM cities_countries
	GROUP BY city HAVING COUNT(city) > 1
)
ORDER BY city, country;

-- Query to see if there are the same amount of unique visit ids as there are of unique full visitor ids
SELECT COUNT(DISTINCT(visit_id)) AS vids, COUNT(DISTINCT(full_visitor_id)) AS fvids
FROM all_sessions;

-- Query to see if there are any entries where either total transaction revenue or transaction column is null
SELECT total_transaction_revenue, transactions FROM all_sessions
WHERE total_transaction_revenue IS NOT NULL OR transactions IS NOT NULL;

-- Query to check product SKU naming trends
SELECT DISTINCT(product_sku) FROM all_sessions
ORDER BY product_sku;

-- Query to check if any product SKUs that have only numerical characters have a price on them
SELECT * FROM all_sessions
WHERE product_sku NOT SIMILAR TO '%[A-Za-z]%' AND product_price > 0
ORDER BY product_sku;

-- Query to check if there are any entries for revenue or units_sold where the price is 0
SELECT revenue, units_sold, unit_price FROM analytics
WHERE (unit_price <= 0) AND (revenue >= 0 OR units_sold >= 0);

-- Query to check product names, ordered to make checking duplicates easier
SELECT DISTINCT(BTRIM(v2_product_name)) AS pname FROM all_sessions
ORDER BY pname;

-- Query to check product category, ordered to make checking duplicates easier
SELECT DISTINCT(BTRIM(v2_product_category)) AS pcat FROM all_sessions
ORDER BY pcat;

-- Query to check the unique country codes
SELECT DISTINCT(currency_code)
FROM all_sessions

-- Check pricing trends of products that have no currency code in order to determine if they can be revised to USD
SELECT v2_product_name, product_sku, AVG(product_price)::numeric(20,2) AS avg_price,
		currency_code
FROM all_sessions
WHERE v2_product_name IN (
	SELECT DISTINCT(v2_product_name)
	FROM all_sessions
	WHERE currency_code IS NULL
)
GROUP BY v2_product_name, product_sku, currency_code
ORDER BY v2_product_name, product_sku, currency_code;

-- Query to check if there are any rows where there is no entry for total transaction revenue but entries exist for other revenue columns
SELECT total_transaction_revenue, product_revenue, transaction_revenue
FROM all_sessions
ORDER BY total_transaction_revenue, product_revenue, transaction_revenue;

-- Query to check if there are any erroneous entries where revenue is lower than the amount sold times the price
SELECT * FROM all_sessions
WHERE total_transaction_revenue >= 0 AND (total_transaction_revenue < product_quantity * product_price
										  OR total_transaction_revenue < product_price);

-- Query to check time column conversion to datetime if the format was in epoch or not
SELECT MIN(to_timestamp(time_info)), MAX(to_timestamp(time_info)) FROM all_sessions;

-- Query to sort products by category counts in order to consodilate products into appropriate categories
-- First query creates a CTE to get a table with the counts of categories per product
-- Second query uses a window function on the CTE to assign a row number of 1 to the category with most instances per product
-- This row number will be used during the table formatting process to rename categories for all these products
WITH category_count AS (
	SELECT v2_product_name, v2_product_category, COUNT(v2_product_category) AS category_count
	FROM all_sessions
	GROUP BY v2_product_name, v2_product_category
)
SELECT *, ROW_NUMBER() OVER(PARTITION BY v2_product_name ORDER BY category_count DESC) AS row_rank
FROM category_count
ORDER BY v2_product_name, category_count DESC, row_rank;

-- Use the same query as above to find a list of products where the top category is '(not set)'
WITH category_count AS (
	SELECT v2_product_name, v2_product_category, COUNT(v2_product_category) AS category_count
	FROM all_sessions
	GROUP BY v2_product_name, v2_product_category
),
ranked_categories AS (
	SELECT *, ROW_NUMBER() OVER(PARTITION BY v2_product_name ORDER BY category_count DESC) AS row_rank
	FROM category_count
	ORDER BY v2_product_name, row_rank, category_count DESC
)
SELECT * FROM ranked_categories
WHERE v2_product_name IN (
	SELECT v2_product_name FROM ranked_categories WHERE row_rank = 1 AND v2_product_category = '(not set)'
)
ORDER BY v2_product_name, row_rank;



Table analytics:

-- Query to check if combing the two visitor id columns can generate enough unique combinations to be used as the primary key
SELECT COUNT(*) AS total_rows, COUNT(DISTINCT(full_visitor_id::varchar || visit_id::varchar)) AS session_id_count
FROM analytics;

-- Query to check if there are any negative numbers in numeric columns by sorting the data
SELECT unit_price FROM analytics
WHERE unit_price < 0
ORDER BY unit_price;

-- Query to check unique values, minimum and maximum values of numeric columns to check for anomalies
SELECT MIN(unit_price) AS min_val, MAX(unit_price) AS max_val,
		COUNT(DISTINCT(unit_price)) AS unique_val
FROM analytics;

-- Query to return date column in date format to ensure type conversion will work
SELECT to_date(date_info::varchar, 'YYYYMMDD') FROM analytics;

-- Query to see if there are the same amount of unique visit ids as there are of unique full visitor ids
SELECT COUNT(DISTINCT(visit_id)) AS vids, COUNT(DISTINCT(full_visitor_id)) AS fvids
FROM analytics;

-- Query to check if visit_id is the exact same as visit_start_time, if not, how many entries are different
SELECT COUNT(DISTINCT(visit_id)), COUNT(DISTINCT(visit_start_time))
FROM analytics
WHERE visit_id <> visit_start_time;

-- Query to check if there are any entries for revenue or units_sold where the price is 0
SELECT revenue, units_sold, unit_price FROM analytics
WHERE (unit_price <= 0) AND (revenue >= 0 OR units_sold >= 0);

-- Query to check if there are any entries for revenue where no units have been sold (0 or null)
SELECT revenue, units_sold, unit_price FROM analytics
WHERE (units_sold <= 0 OR units_sold IS NULL) AND (revenue >= 0);

-- Query to check if there are any erroneous entries where revenue is lower than the amount sold times the price
SELECT * FROM analytics
WHERE units_sold > 0 AND revenue < units_sold * unit_price;

-- Query to check if there are any visit start time entries (which are in epoch format) that differ from the date column
WITH timestamp_date AS(
	SELECT to_timestamp(visit_start_time) AS ts, to_date(date_info::varchar, 'YYYYMMDD') AS d
	FROM analytics
)
SELECT * FROM timestamp_date
WHERE ts::date <> d;



Table products:

-- Query to check if there are any negative numbers in numeric columns by sorting the data
SELECT sentiment_magnitude FROM products
WHERE sentiment_magnitude < 0
ORDER BY sentiment_magnitude;
-- Sentiment_score has negative values

-- Query to check minimum and maximum values of sentiment scores and magnitudes to get a better understanding
SELECT MIN(sentiment_score) AS min_score, MAX(sentiment_score) AS max_score,
		MIN(sentiment_magnitude) AS min_mag, MAX(sentiment_magnitude) AS max_mag
FROM products;
-- Judging by the range, the score seems to range from -1 to +1, and magnitude ranges from 0 to 2

-- Query to notice SKU label trends by sorting the product_sku column alphabetically
SELECT sku FROM products
ORDER BY sku;

-- Since there seems to be two different SKU label formats, query the table to notice any trends
SELECT * FROM products
ORDER BY sku;

-- The strictly numerical SKUs seem to have no orders or any in stock. Query the table to confirm
SELECT sku, ordered_quantity, stock_level FROM products 
WHERE ordered_quantity > 0 OR stock_level > 0
ORDER BY sku;
-- The products with strictly numerical SKUs seem to have no orders or any left in stock, possibly due to the product being delisted or discontinued. Further analyses with cross-references to other tables is required

-- Query to see if there are any product SKUs that are missing or if there are extras when compared to other tables 
WITH distinct_product_skus AS (
	SELECT DISTINCT(sku) FROM products
),
distinct_sales_by_sku_skus AS (
	SELECT DISTINCT(product_sku) FROM sales_by_sku
),
distinct_sales_report_skus AS (
	SELECT DISTINCT(prod_sku) FROM sales_report
),
distinct_all_sessions_skus AS (
	SELECT DISTINCT(product_sku) FROM all_sessions
),
skus_in_cols AS (
	SELECT dps.sku AS psku, dsbss.product_sku AS sbssku, dsrs.prod_sku AS srsku, dass.product_sku AS assku
	FROM distinct_product_skus AS dps
	FULL OUTER JOIN distinct_sales_by_sku_skus AS dsbss	ON dps.sku = dsbss.product_sku
	FULL OUTER JOIN distinct_sales_report_skus AS dsrs ON dps.sku = dsrs.prod_sku
	FULL OUTER JOIN distinct_all_sessions_skus AS dass ON dps.sku = dass.product_sku
)
SELECT * FROM skus_in_cols
WHERE psku IS NULL OR sbssku IS NULL OR srsku IS NULL OR assku IS NULL
ORDER BY psku, sbssku, srsku, assku;

-- Query to see what product names have different SKUs
SELECT BTRIM(product_name) AS product_name, sku FROM products
ORDER BY product_name, sku;

-- Query to see if the products with numerical SKUs have multiple SKUs
-- (with a subquery to generate a table containing product names with numerical SKUs)
-- Start with creating a window function that generates a table that EXCLUDE products that only have alphanumeric SKUs
WITH old_sku AS (
	SELECT BTRIM(product_name) AS product_name, sku FROM products
	WHERE BTRIM(product_name) IN (
		SELECT BTRIM(product_name) AS product_name FROM products
		WHERE sku NOT SIMILAR TO '%[A-Za-z]%'
	)
)
-- Query window function by joining a sub-table from the window function that only has numeric SKUs,
-- then filter the resulting query to find which products ONLY have numeric SKUs
SELECT os1.product_name, COUNT(os1.product_name) AS product_name_count, COUNT(os2.sku) AS numeric_sku_count
FROM old_sku AS os1
LEFT JOIN (
	SELECT * FROM old_sku
	WHERE sku NOT SIMILAR TO '%[A-Za-z]%'
) AS os2
USING(sku)
GROUP BY os1.product_name HAVING COUNT(os1.product_name) = COUNT(os2.sku)
ORDER BY os1.product_name

-- Query to check if any product names are named differently in the sales_report table
SELECT pr.sku, pr.product_name AS prod_name, sr.prod_sku, sr.product_name AS sr_name
FROM products AS pr
FULL OUTER JOIN sales_report AS sr
ON pr.sku = sr.prod_sku
WHERE pr.product_name <> sr.product_name;

-- Query to check if any product names are named differently in the all_sessions table
SELECT pr.sku, pr.product_name AS prod_name, a_s.product_sku, a_s.v2_product_name AS as_name
FROM products AS pr
FULL OUTER JOIN all_sessions AS a_s
ON pr.sku = a_s.product_sku
WHERE pr.product_name <> a_s.v2_product_name
GROUP BY pr.sku, pr.product_name, a_s.product_sku, a_s.v2_product_name
ORDER BY pr.sku;



Table sales_by_sku:

-- Query to check if there are any null entries in either of the two columns
SELECT 'null product SKUs', COUNT(product_sku) FROM sales_by_sku
WHERE product_sku IS NULL

UNION

SELECT 'null order count entries', COUNT(total_ordered) FROM sales_by_sku
WHERE total_ordered IS NULL;

-- Query to theck if all the product SKUs are unique
SELECT product_sku, COUNT(product_sku) FROM sales_by_sku
GROUP BY (product_sku) HAVING COUNT(product_sku) > 1;

-- Query to check if there are any negative numbers the total_ordered column by sorting the data
SELECT total_ordered FROM sales_by_sku
ORDER BY total_ordered;

-- Query to notice SKU label trends by sorting the product_sku column alphabetically
SELECT product_sku FROM sales_by_sku
ORDER BY product_sku;

-- Since there seems to be two different SKU label formats, query the table to notice any trends
SELECT * FROM sales_by_sku
ORDER BY product_sku;

-- The strictly numerical SKUs seem to have no orders. Query the table to confirm
SELECT * FROM sales_by_sku
WHERE total_ordered > 0
ORDER BY product_sku;

-- Query to check if any of the products that aren't present in any other tables have been ordered in the past
SELECT * FROM sales_by_sku
WHERE product_sku NOT IN (
	SELECT DISTINCT(product_sku) FROM all_sessions
		UNION
	SELECT DISTINCT(sku) FROM products
		UNION
	SELECT DISTINCT(prod_sku) FROM sales_report
);



Table sales_report:

-- Query to check if there are any negative numbers in numeric columns by sorting the data
SELECT ratio
FROM sales_report
WHERE ratio < 0
ORDER BY ratio;
-- Sentiment_score has negative values

-- Query to check minimum and maximum values of sentiment scores and magnitudes to get a better understanding
SELECT MIN(sentiment_score) AS min_score, MAX(sentiment_score) AS max_score,
		MIN(sentiment_magnitude) AS min_mag, MAX(sentiment_magnitude) AS max_mag
FROM sales_report;
-- Judging by the range, the score seems to range from -1 to +1, and magnitude ranges from 0 to 2

-- Query to notice SKU label trends by sorting the product_sku column alphabetically
SELECT product_sku FROM sales_report
ORDER BY product_sku;

-- Since there seems to be two different SKU label formats, query the table to notice any trends
SELECT * FROM sales_report
ORDER BY product_sku;

-- The strictly numerical SKUs seem to have no orders or any in stock. Query the table to confirm
SELECT product_sku, total_ordered, stock_level FROM sales_report 
WHERE total_ordered > 0 OR stock_level > 0
ORDER BY product_sku;
-- The products with strictly numerical SKUs seem to have no orders or any left in stock, possibly due to the product being delisted or discontinued. Further analyses with cross-references to other tables is required

-- Query to see if there are any product SKUs that are missing or if there are extras when compared to the sales_by_sku table
SELECT sr.product_sku AS sales_report_skus, sbs.product_sku AS sales_by_sku_skus
FROM sales_report AS sr
FULL OUTER JOIN sales_by_sku AS sbs
USING(product_sku)
WHERE sr.product_sku IS NULL OR sbs.product_sku IS NULL
ORDER BY sr.product_sku, sbs.product_sku;

-- Query to see what product names have different SKUs
SELECT BTRIM(product_name) AS product_name, product_sku FROM sales_report
ORDER BY product_name, product_sku;

-- Query to see if the products with numerical SKUs have multiple SKUs
-- (with a subquery to generate a table containing product names with numerical SKUs)
-- Start with creating a window function that generates a table that EXCLUDE products that only have alphanumeric SKUs
WITH old_product_sku AS (
	SELECT BTRIM(product_name) AS product_name, product_sku
	FROM sales_report
	WHERE BTRIM(product_name) IN (
		SELECT BTRIM(product_name) AS product_name
		FROM sales_report
		WHERE product_sku NOT SIMILAR TO '%[A-Za-z]%'
	)
)
-- Query window function by joining a sub-table from the window function that only has numeric SKUs,
-- then filter the resulting query to find which products ONLY have numeric SKUs
SELECT ops1.product_name, COUNT(ops1.product_name) AS product_name_count, COUNT(ops2.product_sku) AS numeric_sku_count
FROM old_product_sku AS ops1
LEFT JOIN (
	SELECT * FROM old_product_sku
	WHERE product_sku NOT SIMILAR TO '%[A-Za-z]%'
) AS ops2
USING(product_sku)
GROUP BY ops1.product_name
HAVING COUNT(ops1.product_name) = COUNT(ops2.product_sku)
ORDER BY ops1.product_name

-- Query to see if there is any correletaion between total ordered divided by stock level and the ratio column
SELECT CORR(total_ordered/stock_level::numeric(32,20), ratio) FROM sales_report
WHERE stock_level > 0