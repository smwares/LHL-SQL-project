-- add snake casing to avoid PostgreSQL issues, rename column names that have keywords to something similar
CREATE TABLE IF NOT EXISTS all_sessions (
	full_visitor_id varchar,
	channel_grouping varchar,
	time_info varchar,
	country varchar,
	city varchar,
	total_transaction_revenue varchar,
	transactions varchar,
	time_on_site varchar,
	pageviews varchar,
	session_quality_dim varchar,
	date_info varchar,
	visit_id varchar,
	type_info varchar,
	product_refund_amount varchar,
	product_quantity varchar,
	product_price varchar,
	product_revenue varchar,
	product_sku varchar,
	v2_product_name varchar,
	v2_product_category varchar,
	product_variant varchar,
	currency_code varchar,
	item_quantity varchar,
	item_revenue varchar,
	transaction_revenue varchar,
	transaction_id varchar,
	page_title varchar,
	search_keyword varchar,
	page_path_level_1 varchar,
	ecommerce_action_type varchar,
	ecommerce_action_step varchar,
	ecommerce_action_option varchar
);

CREATE TABLE IF NOT EXISTS analytics (
	visit_number varchar,
	visit_id varchar,
	visit_start_time varchar,
	date_info varchar,
	full_visitor_id varchar,
	user_id varchar,
	channel_grouping varchar,
	social_engagement_type varchar,
	units_sold varchar,
	pageviews varchar,
	time_on_site varchar,
	bounces varchar,
	revenue varchar,
	unit_price varchar
);

CREATE TABLE IF NOT EXISTS products (
	sku varchar,
	product_name varchar,
	ordered_quantity varchar,
	stock_level varchar,
	restocking_lead_time varchar,
	sentiment_score varchar,
	sentiment_magnitude varchar
);

CREATE TABLE IF NOT EXISTS sales_by_sku (
	product_sku varchar,
	total_ordered varchar
);

CREATE TABLE IF NOT EXISTS sales_report (
	product_sku varchar,
	total_ordered varchar,
	product_name varchar,
	stock_level varchar,
	restocking_lead_time varchar,
	sentiment_score varchar,
	sentiment_magnitude varchar,
	ratio varchar
);