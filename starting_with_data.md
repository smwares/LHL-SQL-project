## Question 1: What is the overall sentiment on the products?

#### SQL Queries:
```sql
SELECT AVG(sentiment_score) FROM products;
```
#### Answer:

The overall sentiment score is 0.41, which indicates a positive sentiment.

## Question 2: What are the top five products that have been ordered?


#### SQL Queries:
```sql
SELECT product_name, SUM(ordered_quantity) as total_orders FROM products
GROUP BY product_name
HAVING SUM(ordered_quantity) IS NOT NULL
ORDER BY total_orders DESC
LIMIT 5;
```
#### Answer:

Top 5 products:
1. 22 oz Water Bottle - 19992
2. Kick Ball - 15170
3. Sunglasses - 9071
4. Spiral Journal with Pen - 3896
5. Custom Decals - 3786

## Question 3: Which country spent the least amount of time on the site on average?

#### SQL Queries:
```sql
SELECT country, AVG(time_on_site) AS avg_time FROM all_sessions
GROUP BY country
HAVING AVG(time_on_site) IS NOT NULL
ORDER BY avg_time ASC
LIMIT 1;
```

#### Answer:

Brunei with only 3 seconds.

## Question 4: Which product category has the most expensive products on average?

#### SQL Queries:
```sql
SELECT v2_product_category, AVG(product_price) AS avg_price FROM all_sessions
GROUP BY v2_product_category
HAVING AVG(product_price) IS NOT NULL
ORDER BY avg_price DESC
LIMIT 1;
```

#### Answer:

Nest-USA products with an average price of $144.76.

## Question 5: Which product has the lowest restocking time?

#### SQL Queries:

```sql
SELECT product_name, restocking_lead_time FROM products
WHERE restocking_lead_time = (SELECT MIN(restocking_lead_time) FROM products);
```

#### Answer:

PC gaming speakers with a lead time of 1 day.
