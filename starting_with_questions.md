# Answer the following questions and provide the SQL queries used to find the answer.

    
## **Question 1: Which cities and countries have the highest level of transaction revenues on the site?**

#### SQL Queries:
```sql
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
-- Simple group by query to have total revenue by city and country
SELECT city, country, SUM(revenue) AS rev_by_city_country
FROM anasrev
WHERE city NOT LIKE '%not available%' AND city NOT LIKE '%not set%' -- omit entries that are missing city info
GROUP BY city, country
HAVING SUM(revenue) IS NOT NULL
ORDER BY rev_by_city_country DESC;
```

#### Answer:

Top countries in descending order: USA, Israel, Australia, Canada, Switzerland.

Top cities: San Francisco, Seattle, Sunnyvale, Atlanta, Palo Alto, Tel Aviv-Yafo, New York, Mountain View, Los Angeles, Chicago, Sydney, San Jose, Austin, Nashville, San Bruno, Toronto, Houston, Columbus, Zurich

## **Question 2: What is the average number of products ordered from visitors in each city and country?**

#### SQL Queries:
```sql
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
```

#### Answer:

Madrid, Spain - 10

Sales, USA - 8

Atlanta, USA - 4

Houston, USA - 2

New York, USA - 1.17

Bengaluru, India - 1

Dublin, Ireland - 1

Ann Arbor, Chicago, Columbus, Dallas, Detroit, Los Angeles, Mountain View, Palo Alto, San Francisco, San Jose, Seattle, Sunnyvale, USA - 1

## **Question 3: Is there any pattern in the types (product categories) of products ordered from visitors in each city and country?**

#### SQL Queries:
```sql
-- Group-by statement to get category counts per city and country
SELECT country, city, v2_product_category, COUNT(v2_product_category) AS cat_count
FROM all_sessions
WHERE city NOT LIKE '%not available%' AND city NOT LIKE '%not set%' -- omit entries that are missing city info
GROUP BY country, city, v2_product_category
ORDER BY cat_count DESC, country, city;
```

#### Answer:

Top 10 spots are all due to 3 cities in the US, 7 of them being Mountain View, two being New York and one being San Francisco. Most popular category among them seem to be men's T-shirts.

## **Question 4: What is the top-selling product from each city/country? Can we find any pattern worthy of noting in the products sold?**

#### SQL Queries:
```sql
-- Group-by statement to get product counts per city and country
SELECT country, city, v2_product_name, COUNT(v2_product_name) AS prod_count
FROM all_sessions
WHERE city NOT LIKE '%not available%' AND city NOT LIKE '%not set%' -- omit entries that are missing city info
GROUP BY country, city, v2_product_name
ORDER BY prod_count DESC, country, city;
```

#### Answer:

Top 10 spots are once again taken up by cities in the US, 9 out of 10 being Mountain View and the other one being New York. The most popular product seems to be Nest devices (outdoor security camera, smoke alarm and thermostat) followed by men's T-shirts.

## **Question 5: Can we summarize the impact of revenue generated from each city/country?**

#### SQL Queries:
```sql
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
```

#### Answer:

Once again, the top ten contributing cities are mostly in the US, with only one of the cities being in Israel. San Francisco is the biggest contributor with its portion of the revenue being 9.34% of the total revenue, followed closely by Seattle at 8.55%. The next 3 cities are Sunnyvale, Atlanta and Palo Alto, which contributed 5.92%, 5.1% and 3.63% respectively.
