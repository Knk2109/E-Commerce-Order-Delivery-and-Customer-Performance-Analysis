--Data Cleaning

--updating blank columns to 'unknown'

update raw_products rp 
set 
	product_category_name = case
		when trim(product_category_name) = '' or product_category_name is null then 'unknown'
		else product_category_name
	end,
	
	product_name_lenght = case
		when trim(cast(product_name_lenght as text)) = '' then NULL
		else product_name_lenght
	end,
	
	product_description_lenght = case
		when trim(cast(product_description_lenght as text)) = '' then NULL
		else product_description_lenght
	end,
	
	product_photos_qty = case
		when trim(cast(product_photos_qty as text)) = '' then NULL
		else product_photos_qty
	end
where
	trim(product_category_name) = '' or product_category_name is null OR
	trim(cast(product_name_lenght as text)) = '' or product_name_lenght is null	OR
	trim(cast(product_description_lenght as text)) = '' or product_description_lenght is null OR
	trim(cast(product_photos_qty as text)) = '' or product_photos_qty is null;
	
	
select *
from raw_products rp 
where rp.product_name_length is null;

alter table raw_products 
rename column product_name_lenght to product_name_length;

alter table raw_products 
rename column product_description_lenght to product_description_length;

update raw_products rp 
set product_category_name = 'portable_kitchen_and_food_preparers'
where rp.product_category_name = 'portateis_cozinha_e_preparadores_de_alimentos';

--1. Cleaning customers table

create table clean_customers as 
select
	cast(customer_id as varchar(50)) as customer_id,
	cast(customer_unique_id as varchar(50)) as customer_unique_id,
	cast(customer_zip_code_prefix as int) as customer_zip_code_prefix,
	cast(customer_city as varchar(100)) as customer_city,
	cast(customer_state as varchar(50)) as customer_state
from raw_customers;

-- creating clean orders table

CREATE TABLE clean_orders AS
SELECT 
    CAST(order_id AS varchar(100)) AS order_id,
    CAST(customer_id AS varchar(100)) AS customer_id,
    CAST(order_status AS varchar(50)) AS order_status,
    CASE WHEN TRIM(order_approved_at) = '' OR order_approved_at IS NULL THEN NULL 
         ELSE cast(order_approved_at as TIMESTAMP) END AS order_approved_at,
    CASE WHEN TRIM(order_delivered_carrier_date) = '' OR order_delivered_carrier_date IS NULL THEN NULL 
         ELSE cast(order_delivered_carrier_date as TIMESTAMP) END AS order_delivered_carrier_date,
	CASE WHEN TRIM(order_delivered_customer_date) = '' OR order_delivered_customer_date IS NULL THEN NULL 
         ELSE cast(order_delivered_customer_date as TIMESTAMP) END AS order_delivered_customer_date,
    CASE WHEN TRIM(order_estimated_delivery_date) = '' OR order_delivered_customer_date IS NULL THEN NULL 
         ELSE cast(order_estimated_delivery_date as TIMESTAMP) END AS order_estimated_delivery_date
FROM raw_orders;

SELECT order_delivered_customer_date 
FROM clean_orders 
WHERE order_delivered_customer_date IS NULL 
LIMIT 5;

-- 2. Cleaning geolocation table

CREATE TABLE clean_geolocation AS
SELECT DISTINCT *
FROM raw_geolocation;

SELECT COUNT(*) FROM raw_geolocation;

SELECT COUNT(*) FROM clean_geolocation;

-- Change Zip Code to short string
ALTER TABLE clean_geolocation 
ALTER COLUMN geolocation_zip_code_prefix TYPE VARCHAR(20);

-- Change Latitude to Double Float (converts empty spaces to NULL)
ALTER TABLE clean_geolocation 
ALTER COLUMN geolocation_lat TYPE DOUBLE PRECISION 
USING cast(NULLIF(TRIM(geolocation_lat), '') as DOUBLE precision);

-- Change Longitude to Double Float (converts empty spaces to NULL)
ALTER TABLE clean_geolocation 
ALTER COLUMN geolocation_lng TYPE DOUBLE PRECISION 
USING cast(NULLIF(TRIM(geolocation_lng), '') as DOUBLE precision);

-- changing case
ALTER TABLE clean_geolocation 
ALTER COLUMN geolocation_city TYPE VARCHAR(100),
ALTER COLUMN geolocation_state TYPE VARCHAR(10);

UPDATE clean_geolocation
SET geolocation_city = INITCAP(TRIM(geolocation_city))
WHERE geolocation_city IS NOT NULL AND geolocation_city <> '';

SELECT * FROM clean_geolocation 
ORDER BY geolocation_city ASC 
LIMIT 10;


-- 3. Cleaning payments table

CREATE TABLE clean_payments AS
SELECT 
    cast(TRIM(order_id) as VARCHAR(50)) AS order_id,
    cast(TRIM(LOWER(payment_type)) as VARCHAR(50)) AS payment_type,
    -- Installments is an integer count
    CASE WHEN TRIM(payment_installments) = '' THEN NULL 
         ELSE cast(payment_installments as INT) END AS payment_installments,
    -- Financial currency conversion
    CASE WHEN TRIM(payment_value) = '' THEN 0.00 
         ELSE cast(payment_value as NUMERIC(10,2)) END AS payment_value
FROM raw_payments;

alter table clean_payments 
add payment_sequential INT;

UPDATE clean_payments c
SET payment_sequential = r.payment_sequential
FROM raw_payments r
where c.order_id = r.order_id;


-- 4. cleaning order_items table

CREATE TABLE clean_order_items AS
SELECT 
    cast(TRIM(order_id) as VARCHAR(50)) AS order_id,
    cast(TRIM(order_item_id) as INT) AS order_item_id, -- Sequence number of item
    cast(TRIM(product_id) as VARCHAR(50)) AS product_id,
    cast(TRIM(seller_id) as VARCHAR(50)) AS seller_id,
    -- Financial conversions
    CASE WHEN TRIM(price) = '' THEN 0.00 
         ELSE cast(price as NUMERIC(10,2)) END AS price,
    CASE WHEN TRIM(freight_value) = '' THEN 0.00 
         ELSE cast(freight_value as NUMERIC(10,2)) END AS freight_value,
    CASE WHEN TRIM(shipping_limit_date) = '' OR shipping_limit_date IS NULL THEN NULL 
         ELSE cast(shipping_limit_date as TIMESTAMP) END AS shipping_limit_date
FROM raw_order_items;

--5 creating clean products table

CREATE TABLE clean_products AS
SELECT 
    cast(TRIM(product_id) as VARCHAR(50)) AS product_id,
    -- Text check with default value fallback
    CASE WHEN TRIM(product_category_name) = '' OR product_category_name IS NULL THEN 'unknown' 
         ELSE cast(TRIM(LOWER(product_category_name)) as VARCHAR(100)) END AS product_category_name,
    -- Numeric statistics checks
    product_name_length,
	product_description_length,
    product_photos_qty,
    -- Physical dimension metrics (Weights/Sizes as Integers)
    CASE WHEN TRIM(product_weight_g) = '' THEN NULL ELSE cast(product_weight_g as INT) END AS product_weight_g,
    CASE WHEN TRIM(product_length_cm) = '' THEN NULL ELSE cast(product_length_cm as INT) END AS product_length_cm,
    CASE WHEN TRIM(product_height_cm) = '' THEN NULL ELSE cast(product_height_cm as INT) END AS product_height_cm,
    CASE WHEN TRIM(product_width_cm) = '' THEN NULL ELSE cast(product_width_cm as INT) END AS product_width_cm
FROM raw_products;

select count(*)
from clean_products cp
where cp.product_width_cm is null;

--6 creating clean reviews table

CREATE TABLE clean_reviews AS
SELECT 
    cast(TRIM(review_id) as VARCHAR(50)) AS review_id,
    cast(TRIM(order_id) as VARCHAR(50)) AS order_id,
    -- Cast satisfaction scores safely to integers
    CASE WHEN TRIM(review_score) = '' THEN NULL 
         ELSE cast(review_score as INT) END AS review_score,
    -- Retain raw text logs for unstructured analysis strings
    NULLIF(TRIM(review_comment_title), '') AS review_comment_title,
    NULLIF(TRIM(review_comment_message), '') AS review_comment_message,
    -- Timestamps handling
    case when TRIM(review_creation_date) = '' then null
    	 else cast(review_creation_date as TIMESTAMP) end AS review_creation_date,
    CASE WHEN TRIM(review_answer_timestamp) = '' THEN NULL 
         ELSE cast(review_answer_timestamp as TIMESTAMP) END AS review_answer_timestamp
FROM raw_reviews;

CREATE TABLE clean_sellers AS
SELECT 
    cast(TRIM(seller_id) as VARCHAR(50)) AS seller_id,
    cast(TRIM(seller_zip_code_prefix) as INT) AS seller_zip_code_prefix,
    cast(TRIM(initcap(seller_city)) as varchar(50)) AS seller_city,
    cast(TRIM(seller_state) as VARCHAR(100)) AS seller_state
FROM raw_sellers;


truncate table raw_sellers;
drop table clean_sellers;
drop table raw_sellers;



SELECT * FROM raw_sellers LIMIT 5;
select * from clean_sellers limit 10;
select * from clean_orders limit 5;

SELECT 'clean_customers' AS table_name, COUNT(*) FROM clean_customers
UNION ALL
SELECT 'clean_orders', COUNT(*) FROM clean_orders
UNION ALL
SELECT 'clean_order_items', COUNT(*) FROM clean_order_items
UNION ALL
SELECT 'clean_payments', COUNT(*) FROM clean_payments
UNION ALL
SELECT 'clean_products', COUNT(*) FROM clean_products
UNION ALL
SELECT 'clean_reviews', COUNT(*) FROM clean_reviews
UNION ALL
SELECT 'clean_sellers', COUNT(*) FROM clean_sellers
UNION ALL
SELECT 'clean_geolocation', COUNT(*) FROM clean_geolocation;

SELECT column_name,
       data_type
FROM information_schema.columns
WHERE table_name = 'clean_orders';

SELECT column_name,
       data_type
FROM information_schema.columns
WHERE table_name = 'clean_order_items';

SELECT column_name,
       data_type
FROM information_schema.columns
WHERE table_name = 'clean_payments';

alter table clean_orders 
add order_purchase_timestamp timestamp;

UPDATE clean_orders co
SET order_purchase_timestamp = cast(ro.order_purchase_timestamp as timestamp)
FROM raw_orders ro
where co.order_id = ro.order_id;

SELECT column_name,
       data_type
FROM information_schema.columns
WHERE table_name = 'clean_geolocation';

SELECT COUNT(*) total_rows,
       COUNT(DISTINCT customer_id) unique_customers
FROM clean_customers;

SELECT COUNT(*) total_rows,
       COUNT(DISTINCT order_id) unique_orders
FROM clean_orders;

SELECT COUNT(*) total_rows,
       COUNT(DISTINCT product_id) unique_products
FROM clean_products;

SELECT COUNT(*) total_rows,
       COUNT(DISTINCT seller_id) unique_sellers
FROM clean_sellers;

SELECT COUNT(*) total_rows,
       COUNT(DISTINCT geolocation_zip_code_prefix) unique_zip_codes
FROM clean_geolocation;

SELECT
COUNT(*) FILTER (WHERE order_approved_at IS NULL) approved_nulls,
COUNT(*) FILTER (WHERE order_delivered_carrier_date IS NULL) carrier_nulls,
COUNT(*) FILTER (WHERE order_delivered_customer_date IS NULL) delivered_nulls
FROM clean_orders;

SELECT COUNT(*) FROM raw_orders;
SELECT COUNT(*) FROM raw_customers;
SELECT COUNT(*) FROM raw_products;

SELECT COUNT(*) 
FROM raw_products
WHERE product_category_name IS NULL;