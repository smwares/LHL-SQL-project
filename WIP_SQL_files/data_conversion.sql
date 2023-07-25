-- Query to determine what type of numeric data types to use based on minimum and maximum values
-- and to find the largest amount of digits in a single entry
SELECT MIN(ratio::numeric(255,2)) AS minval, MAX(ratio::numeric(255,2)) AS maxval,
		MAX(LENGTH(ratio::varchar)) AS longest
FROM sales_report;

-- Query to convert varchar to float
ALTER TABLE sales_report
	ALTER COLUMN ratio TYPE numeric(32,20)
		USING ratio::numeric(32,20);

-- Query to convert varchar to integer
-- ALTER TABLE sales_report
--	ALTER COLUMN restocking_lead_time TYPE bigint
--		USING restocking_lead_time::bigint;

-- Query to convert varchar to varchar with char limit
-- ALTER TABLE analytics
--	ALTER COLUMN channel_grouping TYPE varchar(255)
--		USING channel_grouping::varchar(255);