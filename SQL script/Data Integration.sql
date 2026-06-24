-- 1. Dimension Tables

CREATE TABLE dim_customer AS
SELECT DISTINCT
       customer_id,
       customer_unique_id,
       customer_city,
       customer_state
FROM clean_customers;

CREATE TABLE dim_product AS
SELECT DISTINCT
       product_id,
       product_category_name,
       product_weight_g,
       product_length_cm,
       product_height_cm,
       product_width_cm,
       product_name_length,
       product_description_length,
       product_photos_qty
FROM clean_products;

CREATE TABLE dim_seller AS
SELECT DISTINCT
       seller_id,
       seller_city,
       seller_state,
       seller_zip_code_prefix
FROM clean_sellers;

CREATE TABLE dim_geography AS
SELECT
       geolocation_zip_code_prefix,
       MAX(geolocation_city) AS city,
       MAX(geolocation_state) AS state
FROM clean_geolocation
GROUP BY geolocation_zip_code_prefix;

select count(*)
from dim_geography;

-- fact tables

CREATE TABLE fact_orders AS
SELECT
       order_id,
       customer_id,
       order_status,

       order_purchase_timestamp,
       order_approved_at,

       order_delivered_carrier_date,
       order_delivered_customer_date,
       order_estimated_delivery_date,

       (
         order_delivered_customer_date::date
         -
         order_purchase_timestamp::date
       ) AS delivery_days,

       (
         order_delivered_customer_date::date
         -
         order_estimated_delivery_date::date
       ) AS delay_days

FROM clean_orders;

CREATE TABLE fact_order_items AS
SELECT *
FROM clean_order_items;

CREATE TABLE fact_payments AS
SELECT *
FROM clean_payments;

CREATE TABLE fact_reviews AS
SELECT *
FROM clean_reviews;

SELECT COUNT(*) FROM dim_customer;
SELECT COUNT(*) FROM dim_product;
SELECT COUNT(*) FROM dim_seller;
SELECT COUNT(*) FROM dim_geography;

SELECT COUNT(*) FROM fact_orders;
SELECT COUNT(*) FROM fact_order_items;
SELECT COUNT(*) FROM fact_payments;
SELECT COUNT(*) FROM fact_reviews;

SELECT
EXTRACT(MONTH FROM order_purchase_timestamp),
COUNT(*)
FROM fact_orders
GROUP BY 1;

SELECT
MIN(order_purchase_timestamp),
MAX(order_purchase_timestamp)
FROM fact_orders;

CREATE TABLE dim_date AS
SELECT
       d::date AS date_key,
       EXTRACT(YEAR FROM d)::INT AS year,
       EXTRACT(MONTH FROM d)::INT AS month_num,
       TO_CHAR(d,'Month') AS month_name,
       EXTRACT(QUARTER FROM d)::INT AS quarter,
       'Q' || EXTRACT(QUARTER FROM d)::INT AS quarter_name,
       EXTRACT(WEEK FROM d)::INT AS week_num,
       EXTRACT(DAY FROM d)::INT AS day_num,
       TO_CHAR(d,'Day') AS day_name,
       CASE
            WHEN EXTRACT(ISODOW FROM d) IN (6,7)
            THEN 'Weekend'
            ELSE 'Weekday'
       END AS day_type

FROM generate_series(
       '2016-09-04'::date,
       '2018-10-17'::date,
       interval '1 day'
) d;

SELECT COUNT(*)
FROM dim_date;

ALTER TABLE fact_orders
ADD COLUMN purchase_date DATE;

UPDATE fact_orders
SET purchase_date = order_purchase_timestamp::date
WHERE purchase_date IS NULL;

select *
from fact_orders
limit 5;

SELECT COUNT(*)
FROM fact_orders
WHERE purchase_date IS NULL;

ALTER TABLE dim_customer
ADD PRIMARY KEY (customer_id);

ALTER TABLE dim_product
ADD PRIMARY KEY (product_id);

ALTER TABLE dim_seller
ADD PRIMARY KEY (seller_id);

ALTER TABLE dim_geography
ADD PRIMARY KEY (geolocation_zip_code_prefix);

ALTER TABLE dim_date
ADD PRIMARY KEY (date_key);

SELECT
COUNT(DISTINCT order_id) total_orders
FROM fact_orders;

SELECT
COUNT(*) total_payment_rows,
COUNT(DISTINCT order_id) distinct_orders
FROM fact_payments;

SELECT
COUNT(DISTINCT order_id) total_orders
FROM fact_order_items;