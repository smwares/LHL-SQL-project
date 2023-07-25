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