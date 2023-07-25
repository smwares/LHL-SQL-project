-- Rename each table prior to creating backups
ALTER TABLE all_sessions
RENAME TO all_sessions_backup;

ALTER TABLE analytics
RENAME TO analytics_backup;

ALTER TABLE products
RENAME TO products_backup;

ALTER TABLE sales_by_sku
RENAME TO sales_by_sku_backup;

ALTER TABLE sales_report
RENAME TO sales_report_backup;

-- For all_sessions table, recreate table with inserted serialized primary key
CREATE TABLE IF NOT EXISTS all_sessions (
	session_id SERIAL PRIMARY KEY,
	full_visitor_id numeric(24,0),
	channel_grouping varchar,
	time_info bigint,
	country varchar,
	city varchar,
	total_transaction_revenue numeric(32,2),
	transactions bigint,
	time_on_site bigint,
	pageviews bigint,
	session_quality_dim bigint,
	date_info bigint,
	visit_id bigint,
	type_info varchar,
	product_refund_amount numeric(32,2),
	product_quantity bigint,
	product_price numeric(32,2),
	product_revenue numeric(32,2),
	product_sku varchar,
	v2_product_name varchar,
	v2_product_category varchar,
	product_variant varchar,
	currency_code varchar,
	item_quantity bigint,
	item_revenue numeric(32,2),
	transaction_revenue numeric(32,2),
	transaction_id varchar,
	page_title varchar,
	search_keyword varchar,
	page_path_level_1 varchar,
	ecommerce_action_type bigint,
	ecommerce_action_step bigint,
	ecommerce_action_option varchar	
);
INSERT INTO all_sessions (
	full_visitor_id, channel_grouping, time_info, country, city, total_transaction_revenue,
	transactions, time_on_site, pageviews, session_quality_dim, date_info, visit_id,
	type_info, product_refund_amount, product_quantity, product_price, product_revenue,
	product_sku, v2_product_name, v2_product_category, product_variant, currency_code,
	item_quantity, item_revenue, transaction_revenue, transaction_id, page_title, search_keyword,
	page_path_level_1, ecommerce_action_type, ecommerce_action_step, ecommerce_action_option)
	SELECT *
	FROM all_sessions_backup;

-- Same approach for analytics table
CREATE TABLE IF NOT EXISTS analytics (
	analytics_id SERIAL PRIMARY KEY,
	visit_number bigint,
	visit_id bigint,
	visit_start_time bigint,
	date_info bigint,
	full_visitor_id numeric(24,0),
	user_id varchar,
	channel_grouping varchar,
	social_engagement_type varchar,
	units_sold bigint,
	pageviews bigint,
	time_on_site bigint,
	bounces bigint,
	revenue numeric(32,2),
	unit_price numeric(32,2)
);
INSERT INTO analytics (
	visit_number, visit_id, visit_start_time, date_info, full_visitor_id,
	user_id, channel_grouping, social_engagement_type, units_sold, pageviews,
	time_on_site, bounces, revenue,	unit_price)
	SELECT *
	FROM analytics_backup;

CREATE TABLE analytics AS
TABLE analytics_backup;

CREATE TABLE products AS
TABLE products_backup;

CREATE TABLE sales_by_sku AS
TABLE sales_by_sku_backup;

CREATE TABLE sales_report AS
TABLE sales_report_backup;

-- Remove redundant spacing from varchar fields at the beginning and end
UPDATE all_sessions
SET channel_grouping = BTRIM(channel_grouping),
	country = BTRIM(country),
	city = BTRIM(city),
	type_info = BTRIM(type_info),
	product_sku = BTRIM(product_sku),
	v2_product_name = BTRIM(v2_product_name),
	v2_product_category = BTRIM(v2_product_category),
	product_variant = BTRIM(product_variant),
	currency_code = BTRIM(currency_code),
	transaction_id = BTRIM(transaction_id),
	page_title = BTRIM(page_title),
	page_path_level_1 = BTRIM(page_path_level_1),
	ecommerce_action_option = BTRIM(ecommerce_action_option);
	
UPDATE analytics
SET channel_grouping = BTRIM(channel_grouping),
	social_engagement_type = BTRIM(social_engagement_type);
	
UPDATE products
SET sku = BTRIM(sku),
	product_name = BTRIM(product_name);
	
UPDATE sales_by_sku
SET product_sku = BTRIM(product_sku);

UPDATE sales_report
SET product_sku = BTRIM(product_sku),
	product_name = BTRIM(product_name);
	
-- Drop columns that are completely null
ALTER TABLE all_sessions
DROP COLUMN IF EXISTS product_refund_amount,
DROP COLUMN IF EXISTS item_quantity,
DROP COLUMN IF EXISTS item_revenue,
DROP COLUMN IF EXISTS search_keyword;

ALTER TABLE analytics
DROP COLUMN IF EXISTS user_id;

-- Revise SKU and product SKU columns in products, sales by SKU and sales report tables to become primary keys
ALTER TABLE products
ADD CONSTRAINT sku PRIMARY KEY(sku);

ALTER TABLE sales_by_sku
ADD CONSTRAINT product_sku PRIMARY KEY(product_sku);

-- Rename column product_sku to something else since it must be unique in the table, otherwise constraint fails
ALTER TABLE sales_report
RENAME COLUMN product_sku TO prod_sku
ALTER TABLE sales_report
ADD CONSTRAINT prod_sku PRIMARY KEY(prod_sku);

-- Set the foreign key in the sales_report table
ALTER TABLE sales_report
	ADD CONSTRAINT fk_sku
	FOREIGN KEY (prod_sku)
	REFERENCES products(sku);

-- Add missing SKUs into the products table prior to changing product sku to a foreign key in the sales_by_sku table
INSERT INTO products (sku, product_name, ordered_quantity, stock_level,
					  restocking_lead_time, sentiment_score, sentiment_magnitude)
	SELECT product_sku, NULL::varchar, total_ordered, NULL::bigint, NULL::bigint,
			NULL::numeric(4,1), NULL::numeric(4,1)
	FROM sales_by_sku
	WHERE product_sku NOT IN (SELECT DISTINCT(sku) FROM products);

-- Set the foreign key in the sales_by_sku table
ALTER TABLE sales_by_sku
	ADD CONSTRAINT fk_sku
	FOREIGN KEY (product_sku)
	REFERENCES products(sku);

-- Add missing SKUs into the products table prior to changing product sku to a foreign key in the all_sessions table
-- Build CTEs that contain unique SKUs in the all_sessions table and the most up-to-date product name and the total quantity first
-- Then insert CTE into product table
WITH sku_date AS (
	SELECT product_sku, MAX(date_info) AS date_info, SUM(product_quantity) AS product_quantity FROM all_sessions
	GROUP BY product_sku
),
sku_date_quantity AS (
	SELECT DISTINCT(sd.product_sku), a_s.v2_product_name, sd.product_quantity, sd.date_info FROM all_sessions AS a_s
	INNER JOIN sku_date AS sd
	ON a_s.product_sku = sd.product_sku AND a_s.date_info = sd.date_info
	ORDER BY sd.product_sku, a_s.v2_product_name, sd.date_info
)
INSERT INTO products (sku, product_name, ordered_quantity, stock_level,
					  restocking_lead_time, sentiment_score, sentiment_magnitude)
	SELECT product_sku, v2_product_name, product_quantity, NULL::bigint, NULL::bigint,
			NULL::numeric(4,1), NULL::numeric(4,1)
	FROM sku_date_quantity
	WHERE product_sku NOT IN (SELECT DISTINCT(sku) FROM products);

-- Set the foreign key in the all_sessions table
ALTER TABLE all_sessions
	ADD CONSTRAINT fk_sku
	FOREIGN KEY (product_sku)
	REFERENCES products(sku);

-- Revise the date_info column of all_sessions table to date type
ALTER TABLE all_sessions
ALTER COLUMN date_info TYPE date
USING to_date(date_info::varchar, 'YYYYMMDD')

-- Revise the date_info column of all_sessions table to date type
ALTER TABLE analytics
ALTER COLUMN date_info TYPE date
USING to_date(date_info::varchar, 'YYYYMMDD')

-- Revise visit_start_time column of analytics table to date-time
ALTER TABLE analytics
ALTER COLUMN visit_start_time TYPE timestamp
USING to_timestamp(visit_start_time)

-- Update all monetary column fields in all_sessions table to have the values divided by a million
UPDATE all_sessions
SET total_transaction_revenue = total_transaction_revenue/1000000,
    product_price = product_price/1000000,
    product_revenue = product_revenue/1000000,
	transaction_revenue = transaction_revenue/1000000;

-- Update all monetary column fields in analytics table to have the values divided by a million
UPDATE analytics
SET revenue = revenue/1000000,
	unit_price = unit_price/1000000;

-- Modify 'not available in demo' text to '(not available)' in all_sessions's city column
UPDATE all_sessions
SET city = '(not available)'
WHERE city = 'not available in demo dataset';

-- Delete row where units sold is less than 0
DELETE FROM analytics WHERE units_sold < 0;

-- Delete records from all_sessions table where country and city combinations do not exist
DELETE FROM all_sessions
WHERE (country = 'United States' AND city IN ('Bangkok', 'Hong Kong', 'London', 'Mexico City', 'Yokohamaa'))
	OR (country = 'Netherlands' AND city IN ('Dublin'))
	OR (country = 'Hungary' AND city IN ('Istanbul'))
	OR (country = 'Australia' AND city IN ('Los Angeles'))
	OR (country = 'Japan' AND city IN ('Mountain View', 'San Francisco'))
	OR (country = 'Canada' AND city IN ('New York'))
	OR (country = 'France' AND city IN ('San Francisco', 'Singapore'))

-- Add 'USD' to all fields under the currency code column in the all_sessions table
UPDATE all_sessions
SET currency_code = 'USD'
WHERE currency_code IS NULL;

-- Remove redundant spacing from product name in all sessions table
-- Revised code from the following source: https://www.postgresqltutorial.com/postgresql-string-functions/regexp_replace/
UPDATE all_sessions
SET v2_product_name = REGEXP_REPLACE(v2_product_name,'( ){2,}',' ');

-- Remove the backslash at the end and 'Home/' at the beginning from the category fields in the all_sessions table
UPDATE all_sessions
SET v2_product_category = BTRIM(LTRIM(RTRIM(v2_product_category, '/'), 'Home/'));

-- Reduce the amount of categories in the all_sessions table as many products are unnecessarily in multiple categories
-- First query creates a CTE to get a table with the counts of categories per product
-- Second query uses a window function on the CTE to assign a row number of 1 to the category with most instances per product
-- This row number will be used during the table formatting process to rename categories for all these products
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
UPDATE all_sessions
SET v2_product_category = ranked_categories.v2_product_category
FROM ranked_categories
WHERE all_sessions.v2_product_name = ranked_categories.v2_product_name
	AND ranked_categories.row_rank = 1;

-- Manually revise products whose categories are '(not set)' in the all_sessions table
UPDATE all_sessions
SET v2_product_category = 'Gift Cards'
WHERE LOWER(v2_product_name) SIMILAR TO '%gift card%';

UPDATE all_sessions
SET v2_product_category = 'Electronics'
WHERE LOWER(v2_product_name) SIMILAR TO '%edc flashlight%';

UPDATE all_sessions
SET v2_product_category = 'Office/Notebooks & Journals'
WHERE LOWER(v2_product_name) SIMILAR TO '%google%%journal%';

UPDATE all_sessions
SET v2_product_category = $$Apparel/Men's/Men's-Outerwear$$ -- Double dollar signs to inclde escape character
WHERE LOWER(v2_product_name) SIMILAR TO '%google men%%zip hoodie%';

UPDATE all_sessions
SET v2_product_category = $$Apparel/Women's/Women's-Outerwear$$
WHERE LOWER(v2_product_name) SIMILAR TO '%google women%%zip jacket%'
	OR LOWER(v2_product_name) SIMILAR TO '%google women%%softshell jacket%'
	OR LOWER(v2_product_name) SIMILAR TO '%google women%%zip hoodie%';

UPDATE all_sessions
SET v2_product_category = $$Apparel/Women's/Women's-T-Shirts$$
WHERE LOWER(v2_product_name) SIMILAR TO '%google women%%baseball raglan%'
	OR LOWER(v2_product_name) SIMILAR TO '%google women%%hero tee%'
	OR LOWER(v2_product_name) SIMILAR TO '%waze women%%sleeve tee%';
	
UPDATE all_sessions
SET v2_product_category = 'Accessories/Sports & Fitness'
WHERE LOWER(v2_product_name) SIMILAR TO '%yoga mat%';
