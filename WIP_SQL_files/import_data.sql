-- Import one CSV at a time
-- Directory name redacted for privacy concerns
COPY all_sessions(
	full_visitor_id,
	channel_grouping,
	time_info,
	country,
	city,
	total_transaction_revenue,
	transactions,
	time_on_site,
	pageviews,
	session_quality_dim,
	date_info,
	visit_id,
	type_info,
	product_refund_amount,
	product_quantity,
	product_price,
	product_revenue,
	product_sku,
	v2_product_name,
	v2_product_category,
	product_variant,
	currency_code,
	item_quantity,
	item_revenue,
	transaction_revenue,
	transaction_id,
	page_title,
	search_keyword,
	page_path_level_1,
	ecommerce_action_type,
	ecommerce_action_step,
	ecommerce_action_option
)
FROM 'C:\Users\_____\Documents\Lighthouse Labs\sql final project data_updated\all_sessions.csv'
DELIMITER ','
CSV HEADER;

COPY analytics(
	visit_number,
	visit_id,
	visit_start_time,
	date_info,
	full_visitor_id,
	user_id,
	channel_grouping,
	social_engagement_type,
	units_sold,
	pageviews,
	time_on_site,
	bounces,
	revenue,
	unit_price
)
FROM 'C:\Users\_____\Documents\Lighthouse Labs\sql final project data_updated\analytics.csv'
DELIMITER ','
CSV HEADER;

COPY products(
	sku,
	product_name,
	ordered_quantity,
	stock_level,
	restocking_lead_time,
	sentiment_score,
	sentiment_magnitude
)
FROM 'C:\Users\_____\Documents\Lighthouse Labs\sql final project data_updated\products.csv'
DELIMITER ','
CSV HEADER;

COPY sales_by_sku(
	product_sku,
	total_ordered
)
FROM 'C:\Users\_____\Documents\Lighthouse Labs\sql final project data_updated\sales_by_sku.csv'
DELIMITER ','
CSV HEADER;

COPY sales_report(
	product_sku,
	total_ordered,
	product_name,
	stock_level,
	restocking_lead_time,
	sentiment_score,
	sentiment_magnitude,
	ratio
)
FROM 'C:\Users\_____\Documents\Lighthouse Labs\sql final project data_updated\sales_report.csv'
DELIMITER ','
CSV HEADER;