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