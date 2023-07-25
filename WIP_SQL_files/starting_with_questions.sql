-- **Question 1: Which cities and countries have the highest level of transaction revenues on the site?**

-- First, create CTE joining the all_sessions and analytics table, then coalesce revenue columns to fill in missing data
-- Tables are joined on six matching columns in order to have as unique values as possible
WITH anasrev AS (
	SELECT a_s.city, a_s.country, COALESCE(a_s.total_transaction_revenue, an.revenue) AS revenue
	FROM all_sessions AS a_s
	LEFT JOIN analytics AS an
	ON an.full_visitor_id = a_s.full_visitor_id AND an.visit_id = a_s.visit_id
		AND an.date_info = a_s.date_info AND an.channel_grouping = a_s.channel_grouping
		AND an.time_on_site = a_s.time_on_site AND an.pageviews = a_s.pageviews
		AND an.units_sold = a_s.product_quantity
)
-- Group-by query to have total revenue by city and country
SELECT city, country, SUM(revenue) AS rev_by_city_country
FROM anasrev
WHERE city NOT LIKE '%not available%' AND city NOT LIKE '%not set%' -- omit entries that are missing city info
GROUP BY city, country
HAVING SUM(revenue) IS NOT NULL
ORDER BY rev_by_city_country DESC;


-- **Question 2: What is the average number of products ordered from visitors in each city and country?**

-- First, create CTE joining the all_sessions and analytics table, then coalesce revenue columns to fill in missing data
-- Tables are joined on six matching columns in order to have as unique values as possible
WITH anasqty AS (
	SELECT a_s.city, a_s.country, COALESCE(a_s.product_quantity, an.units_sold) AS quantity
	FROM all_sessions AS a_s
	LEFT JOIN analytics AS an
	ON an.full_visitor_id = a_s.full_visitor_id AND an.visit_id = a_s.visit_id
		AND an.date_info = a_s.date_info AND an.channel_grouping = a_s.channel_grouping
		AND an.time_on_site = a_s.time_on_site AND an.pageviews = a_s.pageviews
		AND an.units_sold = a_s.product_quantity
)
-- Group-by query to have average quantity by city and country
SELECT city, country, AVG(quantity)::numeric(10,2) AS avg_ordered
FROM anasqty
WHERE city NOT LIKE '%not available%' AND city NOT LIKE '%not set%' -- omit entries that are missing city info
GROUP BY city, country
HAVING AVG(quantity) IS NOT NULL
ORDER BY avg_ordered DESC, country, city;


-- **Question 3: Is there any pattern in the types (product categories) of products ordered from visitors in each city and country?**

-- Group-by statement to get category counts per city and country
SELECT country, city, v2_product_category, COUNT(v2_product_category) AS cat_count
FROM all_sessions
WHERE city NOT LIKE '%not available%' AND city NOT LIKE '%not set%' -- omit entries that are missing city info
GROUP BY country, city, v2_product_category
ORDER BY cat_count DESC, country, city;


-- **Question 4: What is the top-selling product from each city/country? Can we find any pattern worthy of noting in the products sold?**

-- Group-by statement to get product counts per city and country
SELECT country, city, v2_product_name, COUNT(v2_product_name) AS prod_count
FROM all_sessions
WHERE city NOT LIKE '%not available%' AND city NOT LIKE '%not set%' -- omit entries that are missing city info
GROUP BY country, city, v2_product_name
ORDER BY prod_count DESC, country, city;


-- **Question 5: Can we summarize the impact of revenue generated from each city/country?**

-- Tables are joined on six matching columns in order to have as unique values as possible
WITH anasrev AS (
	SELECT a_s.city, a_s.country, COALESCE(a_s.total_transaction_revenue, an.revenue) AS revenue
	FROM all_sessions AS a_s
	LEFT JOIN analytics AS an
	ON an.full_visitor_id = a_s.full_visitor_id AND an.visit_id = a_s.visit_id
		AND an.date_info = a_s.date_info AND an.channel_grouping = a_s.channel_grouping
		AND an.time_on_site = a_s.time_on_site AND an.pageviews = a_s.pageviews
		AND an.units_sold = a_s.product_quantity
),
-- Generate a CTE containing a column with the total revenue
total_revenue AS (
	SELECT DISTINCT(city), country, SUM(revenue) OVER () AS total_rev,
		SUM(revenue) OVER (PARTITION BY city, country) AS rev_by_city
	FROM anasrev
	ORDER BY rev_by_city DESC
)
-- Query to get percentage of revenue contribution by city, ordered by highest generator first
SELECT city, country, total_rev, (100 * rev_by_city/total_rev)::numeric(10,2) AS rev_percent
FROM total_revenue
-- Omit entries that are missing info. NOTE: cities and countries that are missing were not omitted from the total calculation...
-- ... as it's assumed that transactions were made, it's just that the visitor did not set their location information
WHERE city NOT LIKE '%not available%' AND city NOT LIKE '%not set%' AND rev_by_city IS NOT NULL 
ORDER BY rev_percent DESC, country, city;