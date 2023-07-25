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