CREATE TABLE raw_orders (
    order_id TEXT,
    customer_id TEXT,
    order_status TEXT,
    order_purchase_timestamp TEXT,
    order_approved_at TEXT,
    order_delivered_carrier_date TEXT,
    order_delivered_customer_date TEXT,
    order_estimated_delivery_date TEXT
);

select count(1)
from raw_orders ro;

CREATE TABLE raw_order_items (
    order_id TEXT,
    order_item_id TEXT,
    product_id TEXT,
    seller_id TEXT,
    price TEXT,
    freight_value TEXT
);

CREATE TABLE raw_customers (
    customer_id TEXT,
    customer_unique_id TEXT,
    customer_city TEXT,
    customer_state TEXT
);

CREATE TABLE raw_products (
    product_id TEXT,
    product_category_name TEXT,
    product_weight_g TEXT,
    product_length_cm TEXT,
    product_height_cm TEXT,
    product_width_cm TEXT
);

CREATE TABLE raw_sellers (
    seller_id TEXT,
    seller_zip_code_prefix text,
    seller_city TEXT,
    seller_state TEXT
);

CREATE TABLE raw_payments (
    order_id TEXT,
    payment_type TEXT,
    payment_installments TEXT,
    payment_value TEXT
);

CREATE TABLE raw_reviews (
    review_id TEXT,
    order_id TEXT,
    review_score TEXT,
    review_creation_date TEXT
);

CREATE TABLE raw_geolocation (
    geolocation_zip_code_prefix TEXT,
    geolocation_lat TEXT,
    geolocation_lng TEXT,
    geolocation_city TEXT,
    geolocation_state TEXT
);

drop table if exists raw_reviews ;

CREATE TABLE raw_reviews (
    review_id TEXT,
    order_id TEXT,
    review_score TEXT,
    review_comment_title TEXT,
    review_comment_message TEXT,
    review_creation_date TEXT,
    review_answer_timestamp TEXT
);

COPY public.raw_reviews
FROM 'C:/dataset/olist_order_reviews_dataset.csv'
DELIMITER ',' 
CSV HEADER;

COPY public.raw_sellers
FROM 'C:/dataset/olist_sellers_dataset.csv'
DELIMITER ',' 
CSV HEADER;

select count(1)
from raw_reviews rr ;

select *
from raw_reviews rr ;

select count(1)
from raw_sellers rs ;

select *
from raw_sellers rs ;

select count(1)
from raw_customers rc  ;

select *
from raw_customers rc ;

select count(1)
from raw_order_items roi ;

select count(1)
from raw_payments rp ; 


select count(1)
from raw_products rp  ; 

COPY public.raw_geolocation
FROM 'C:/dataset/olist_geolocation_dataset.csv'
DELIMITER ',' 
CSV HEADER;

select count(1)
from raw_geolocation rg   ; 

select *
from raw_geolocation rg ;

TRUNCATE TABLE public.raw_geolocation;

drop table raw_geolocation ;

select *
from raw_customers rc  ;

select *
from raw_products rp ;

create table raw_product_category_name_translation (
	product_category_name text,
	product_categor_name_english text
);


COPY public.raw_product_category_name_translation
FROM 'C:/dataset/product_category_name_translation.csv'
DELIMITER ',' 
CSV HEADER;

update public.raw_products rp
set product_category_name = rpcnt.product_categor_name_english
from public.raw_product_category_name_translation rpcnt 
where rp.product_category_name = rpcnt.product_category_name;

select *
from raw_products rp ;

select *
from raw_product_category_name_translation rpcnt ;

SELECT product_category_name, COUNT(*) 
FROM public.raw_products
GROUP BY product_category_name
ORDER BY COUNT(*) DESC;

	
SELECT product_id, product_category_name 
FROM public.raw_products 
WHERE product_category_name IS NOT NULL 
  AND product_category_name <> ''
LIMIT 10;

select count(*)
from raw_products rp
where rp.product_category_name = '';


