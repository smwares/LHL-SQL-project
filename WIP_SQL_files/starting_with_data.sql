-- Question 1: What is the overall sentiment on the products?

SELECT AVG(sentiment_score) FROM products;

-- Question 2: What are the top five products that have been ordered?

SELECT product_name, SUM(ordered_quantity) AS total_orders FROM products
GROUP BY product_name
HAVING SUM(ordered_quantity) IS NOT NULL
ORDER BY total_orders DESC
LIMIT 5;

-- Question 3: Which country spent the most time on the site on average?

SELECT country, AVG(time_on_site) AS avg_time FROM all_sessions
GROUP BY country
HAVING AVG(time_on_site) IS NOT NULL
ORDER BY avg_time ASC
LIMIT 1;

-- Question 4: Which product category has the most expensive products on average?

SELECT v2_product_category, AVG(product_price)::numeric(10,2) AS avg_price FROM all_sessions
GROUP BY v2_product_category
HAVING AVG(product_price) IS NOT NULL
ORDER BY avg_price DESC
LIMIT 1;

-- Question 5: Which product has the lowest restocking time?

SELECT product_name, restocking_lead_time FROM products
WHERE restocking_lead_time = (SELECT MIN(restocking_lead_time) FROM products);