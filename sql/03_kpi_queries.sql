-- =============================================================================
-- Olist Store Analysis - the 5 business KPIs in MySQL 8.0
-- Database: olist_store (see 01_schema.sql and 02_load_data.sql)
--
-- The same 5 KPIs were answered in Excel, SQL, Power BI and Tableau.
-- KPI 2 (query below) is my own query; the queries for KPIs 1, 3, 4 and 5 were
-- Results in the comments are the outputs on the project database.
-- =============================================================================
USE olist_store;


-- =============================================================================
-- KPI 1: Weekday vs Weekend payment statistics
-- Weekend = Saturday and Sunday (DAYOFWEEK: 1 = Sunday, 7 = Saturday).
-- Orders are counted with COUNT(DISTINCT order_id) because one order can have
-- several payment rows (installments / split payments).
-- Result: Weekday 76,593 orders, avg payment 154.44 | Weekend 22,847 orders, avg payment 152.95
-- =============================================================================
SELECT
    CASE
        WHEN DAYOFWEEK(o.order_purchase_timestamp) IN (1, 7) THEN 'Weekend'
        ELSE 'Weekday'
    END                                 AS Day_Type,
    COUNT(DISTINCT p.order_id)          AS Distinct_Orders,
    COUNT(p.payment_value)              AS Total_Payment_Records,
    ROUND(AVG(p.payment_value), 2)      AS Average_Payment_Value,
    ROUND(SUM(p.payment_value), 2)      AS Total_Payment_Value
FROM olist_orders_dataset o
JOIN olist_order_payments_dataset p
    ON o.order_id = p.order_id
GROUP BY Day_Type;


-- =============================================================================
-- KPI 2: Orders with review score 5 paid by credit card 
-- COUNT(DISTINCT order_id): an order can have several payment rows and, in a few
-- cases, several reviews, so counting rows would overstate the result.
-- Result: 43,981 orders
-- (The first Excel version reported 42,581; see the README, "Data quality lessons".)
-- =============================================================================
SELECT
    COUNT(DISTINCT r.order_id) AS Matching_Orders
FROM olist_order_reviews_dataset r
JOIN olist_order_payments_dataset p
    ON r.order_id = p.order_id
WHERE r.review_score = 5
  AND p.payment_type = 'credit_card';

-- KPI 2 (extra breakdown): 5-star orders by payment type.
-- An order paid with more than one payment type appears once per type.
-- Result: credit_card 43,981 | boleto 11,282 | voucher 2,150 | debit_card 922
-- Distinct 5-star orders with a payment record: 57,075 (43,981 / 57,075 = 77.06%).
SELECT
    p.payment_type,
    COUNT(DISTINCT r.order_id) AS orders
FROM olist_order_reviews_dataset r
JOIN olist_order_payments_dataset p
    ON r.order_id = p.order_id
WHERE r.review_score = 5
GROUP BY p.payment_type
ORDER BY orders DESC;


-- =============================================================================
-- KPI 3: Average delivery days, pet_shop category
-- Delivery days = DATEDIFF(delivered date, purchase date) in whole calendar days.
-- Only delivered orders with a delivery date are used; the ~2,965 never-delivered
-- orders have a NULL delivery date and are excluded here, not deleted.
-- An order counts once even if it contains several pet_shop items (IN subquery).
-- =============================================================================

-- Overall average for comparison (NULL delivery dates are ignored by AVG).
-- Result: 12.4973 days
SELECT
    AVG(DATEDIFF(order_delivered_customer_date, order_purchase_timestamp)) AS Average_Delivery_Days
FROM olist_orders_dataset;

-- pet_shop average (1,688 delivered orders)
-- Result: 11.3146 days (11.31)
SELECT
    AVG(DATEDIFF(order_delivered_customer_date, order_purchase_timestamp)) AS Pet_Shop_Avg_Delivery_Days
FROM olist_orders_dataset
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NOT NULL
  AND order_id IN (
        SELECT oi.order_id
        FROM olist_order_items_dataset oi
        JOIN olist_products_dataset p
            ON oi.product_id = p.product_id
        WHERE p.product_category_name = 'pet_shop'
  );


-- =============================================================================
-- KPI 4: Average price and payment value, customers of sao paulo city
-- Both measures are averaged per order first (an order has several items and may
-- have several payment rows) and then averaged across orders, so each order has
-- the same weight. Population: sao paulo orders that have both items and payments.
-- Result: average price 112.58 | average payment value 138.74
-- (Excel and Tableau average over item / payment rows instead: 107.53 and 135.83.)
-- =============================================================================
WITH item_avg AS (
    SELECT order_id,
           AVG(price) AS avg_price
    FROM olist_order_items_dataset
    GROUP BY order_id
),
payment_avg AS (
    SELECT order_id,
           AVG(payment_value) AS avg_payment
    FROM olist_order_payments_dataset
    GROUP BY order_id
)
SELECT
    ROUND(AVG(i.avg_price), 2)   AS average_price,
    ROUND(AVG(p.avg_payment), 2) AS average_payment_value
FROM olist_customers_dataset c
JOIN olist_orders_dataset o
    ON c.customer_id = o.customer_id
JOIN item_avg i
    ON o.order_id = i.order_id
JOIN payment_avg p
    ON o.order_id = p.order_id
WHERE LOWER(c.customer_city) = 'sao paulo';


-- =============================================================================
-- KPI 5: Relationship between shipping days and review score
-- Shipping days = DATEDIFF(delivered date, purchase date). Undelivered orders excluded.
-- Note: an order with more than one review is counted under each of its scores.
-- Result (score: orders, avg shipping days):
--   1: 9,384, 21.25 | 2: 2,938, 16.61 | 3: 7,943, 14.20 | 4: 18,943, 12.25 | 5: 56,810, 10.63
-- =============================================================================
SELECT
    r.review_score,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(AVG(DATEDIFF(o.order_delivered_customer_date,
                       o.order_purchase_timestamp)), 2) AS average_shipping_days
FROM olist_orders_dataset AS o
JOIN olist_order_reviews_dataset AS r
    ON o.order_id = r.order_id
WHERE o.order_delivered_customer_date IS NOT NULL
  AND o.order_purchase_timestamp IS NOT NULL
  AND r.review_score IS NOT NULL
GROUP BY r.review_score
ORDER BY r.review_score;
