-- TASK 1 Overall Order Operations Health Check. Finding total number of orders, delivered orders, cancelled orders, and average order value across the dataset

select
	count(distinct order_id) as total_orders,
	
	count(distinct case
			when order_status = 'delivered'
			then order_id
		end) as delivered_orders,
		
	round(count(distinct case
			when order_status = 'delivered'
			then order_id
		end) * 100.0
		/ count(distinct order_id), 2) as order_delivery_rate,
	
	count(distinct case
			when order_status = 'canceled'
			then order_id
		end) as canceled_orders,
		
	round(count(distinct case
			when order_status = 'canceled'
			then order_id
		end) * 100.0
		/ count(distinct order_id), 2) as order_canceled_rate
from fact_orders;

-- Average order Value

SELECT
ROUND(
    SUM(payment_value)
    /
    COUNT(DISTINCT order_id), 2) as average_order_value
FROM fact_payments;

-- Task 2 - Order Lifecycle Performance( Order Distribution status)

SELECT
	order_status,
	COUNT(*) AS orders
FROM fact_orders
GROUP BY order_status
ORDER BY orders DESC;

-- Task 3 - Delivery Time Analysis

SELECT
	ROUND(AVG(delivery_days),2) AS avg_delivery_days
FROM fact_orders
WHERE delivery_days IS NOT NULL;

-- Task 4: Delivery Delay Analysis

SELECT
	CASE
		WHEN delay_days > 0
		THEN 'Delayed'
		ELSE 'On Time'
END AS delivery_status,
	COUNT(*) orders
FROM fact_orders
WHERE delay_days IS NOT NULL
GROUP BY 1;

-- Task 5 Seller Performance Benchmarking

/*
SELECT
    fo.order_status,
    COUNT(*) AS orders_without_items
FROM fact_orders fo
LEFT JOIN fact_order_items foi
    ON fo.order_id = foi.order_id
WHERE foi.order_id IS NULL
GROUP BY fo.order_status
ORDER BY orders_without_items DESC; **/

SELECT
    foi.seller_id,
    COUNT(DISTINCT foi.order_id) AS total_orders_handled,
    ROUND(
        AVG(fo.delivery_days), 2) AS avg_delivery_days,
    ROUND(
        AVG(fr.review_score), 2) AS avg_review_score
FROM fact_order_items foi
JOIN fact_orders fo
    ON foi.order_id = fo.order_id
LEFT JOIN fact_reviews fr
    ON foi.order_id = fr.order_id
GROUP BY foi.seller_id
ORDER BY total_orders_handled DESC
LIMIT 10;

-- Task 6: Customer Distribution and Demand Analysis

SELECT
    dc.customer_state,
    COUNT(fo.order_id) AS total_orders
FROM fact_orders fo
JOIN dim_customer dc
    ON fo.customer_id = dc.customer_id
GROUP BY dc.customer_state
ORDER BY total_orders DESC;

SELECT
    customer_city,
    COUNT(*) AS customers
FROM dim_customer
GROUP BY customer_city
ORDER BY customers DESC
LIMIT 10;

/*SELECT
    dc.customer_city,
    count(dc.customer_id) as total_customers,
    COUNT(fo.order_id) AS total_orders
FROM fact_orders fo
JOIN dim_customer dc
    ON fo.customer_id = dc.customer_id
GROUP BY dc.customer_city
ORDER BY total_orders desc; 1 customer_id = 1 order**/

-- Task 7: Product Category Performance

SELECT
    dp.product_category_name,
    COUNT(foi.order_id) AS order_volume,
    ROUND(
        SUM(foi.price), 2) AS revenue
FROM fact_order_items foi
JOIN dim_product dp
    ON foi.product_id = dp.product_id
GROUP BY dp.product_category_name
ORDER BY revenue DESC;

-- Task 8: Payment Behavior Analysis

SELECT
    payment_type,
    COUNT(*) AS transactions,
    ROUND(SUM(payment_value),2) AS revenue
FROM fact_payments
GROUP BY payment_type
ORDER BY revenue DESC;

-- Task 9: Customer Satisfaction Analysis ( against delivered orders)

/*SELECT
    review_score,
    COUNT(*) AS reviews
FROM fact_reviews
GROUP BY review_score
ORDER BY review_score; **/

SELECT
    fr.review_score,
    COUNT(*) AS total_reviews
FROM fact_reviews fr
JOIN fact_orders fo
    ON fr.order_id = fo.order_id
WHERE fo.order_status = 'delivered'
GROUP BY fr.review_score
ORDER BY fr.review_score;

-- Task 10: Delivery vs Review Relationship

SELECT
    delivery_days,
    ROUND(
        AVG(fr.review_score), 2) AS avg_review_score
FROM fact_orders fo
JOIN fact_reviews fr
    ON fo.order_id = fr.order_id
WHERE delivery_days IS NOT NULL
GROUP BY delivery_days
ORDER BY delivery_days;

-- Task 11: Order Value & Revenue Analysis (average order value across different product categories and it's revenue)

SELECT
    dp.product_category_name,
	count(distinct foi.order_id) as total_orders,
	round(sum(foi.price),2) as total_revenue,
    ROUND(AVG(foi.price), 2) AS avg_order_value
FROM fact_order_items foi
JOIN dim_product dp
    ON foi.product_id = dp.product_id
GROUP BY dp.product_category_name
ORDER BY avg_order_value DESC;

-- Task 12: Time-Based Order Trends

SELECT
    dd.year,
    dd.month_name,
    COUNT(*) AS total_orders

FROM fact_orders fo
JOIN dim_date dd
    ON fo.purchase_date = dd.date_key
GROUP BY
    dd.year,
    dd.month_num,
    dd.month_name
ORDER BY
    dd.year,
	dd.month_num;

-- Task 13: Customer Retention Analysis

WITH customer_orders AS
(
    SELECT
        dc.customer_unique_id,
        COUNT(DISTINCT fo.order_id) AS total_orders
    FROM fact_orders fo
    JOIN dim_customer dc
        ON fo.customer_id = dc.customer_id
    GROUP BY dc.customer_unique_id
)

SELECT
    CASE
        WHEN total_orders > 1
        THEN 'Repeat Customer'
        ELSE 'One-Time Customer'
    END AS customer_type,
    COUNT(*) AS customer_count,
    ROUND(
        COUNT(*) * 100.0 /
        SUM(COUNT(*)) OVER(), 2) AS percentage
FROM customer_orders
GROUP BY customer_type;

--Task 14: High-Risk Order Identification (orders having long delivery times and low review scores)

SELECT
    fo.order_id,
    fo.delivery_days,
    fr.review_score
FROM fact_orders fo
JOIN fact_reviews fr
    ON fo.order_id = fr.order_id
WHERE
    fo.delivery_days > 20
    AND fr.review_score <= 2
ORDER by fo.delivery_days DESC;

--KPI Queries for Average Review Score and On-time Delivery Rate

--Average Review Score

SELECT
ROUND(AVG(review_score),2) AS avg_review_score
FROM fact_reviews;

-- On-time delivery Rate

SELECT
ROUND(
COUNT(*) FILTER (WHERE delay_days <= 0) * 100.0
/
COUNT(*), 2) AS on_time_delivery_rate
FROM fact_orders
WHERE delay_days IS NOT NULL;

SELECT
COUNT(*) AS delivered_orders_with_delivery_data,

COUNT(*) FILTER (
    WHERE delay_days <= 0
) AS on_time_orders

FROM fact_orders
WHERE delay_days IS NOT NULL;

-- Seller Performance Table

CREATE TABLE seller_performance AS

SELECT
    foi.seller_id,
    COUNT(DISTINCT foi.order_id) AS total_orders_handled,

    ROUND(
        AVG(fo.delivery_days),
        2
    ) AS avg_delivery_days,

    ROUND(
        AVG(fr.review_score),
        2
    ) AS avg_review_score

FROM fact_order_items foi

JOIN fact_orders fo
    ON foi.order_id = fo.order_id

LEFT JOIN fact_reviews fr
    ON foi.order_id = fr.order_id

WHERE fo.delivery_days IS NOT NULL

GROUP BY foi.seller_id;

select *
from seller_performance;

drop table seller_performance;

-- High Risk Orders

CREATE VIEW high_risk_orders AS

SELECT
    fo.order_id,
    fo.delivery_days,
    fr.review_score
FROM fact_orders fo
JOIN fact_reviews fr
    ON fo.order_id = fr.order_id
WHERE fo.delivery_days > 20
AND fr.review_score <= 2;

SELECT
    order_status,
    COUNT(review_id)
FROM fact_reviews fr
JOIN fact_orders fo
    ON fr.order_id = fo.order_id
GROUP BY order_status
ORDER BY 2 DESC;