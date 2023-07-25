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