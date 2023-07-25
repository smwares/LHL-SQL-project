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