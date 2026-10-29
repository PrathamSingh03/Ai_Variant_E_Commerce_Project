-- =============================================================================
-- Olist Store Analysis - load the 9 Kaggle CSV files into MySQL
-- Run AFTER 01_schema.sql.
--
-- Before running:
--   1. Download the dataset from Kaggle (see ../data/README.md) and unzip it.
--   2. Replace /path/to/olist_csv/ below with the folder that holds the 9 CSV files.
--   3. Enable LOCAL INFILE on the server and the client:
--        SET GLOBAL local_infile = 1;
--        mysql --local-infile=1 -u <user> -p < 02_load_data.sql
--      (In MySQL Workbench add  OPT_LOCAL_INFILE=1  to the connection's advanced options.)
--
-- Cleaning decisions applied while loading (same as in the Excel / Power BI stages):
--   * Blank product_category_name  -> 'unknown'   (610 products). A matching 'unknown'
--     row is added to product_category_name_translation so the foreign key is valid.
--   * Blank numeric / date fields  -> NULL         (never filled with 0 or a fake date).
--     Orders that were never delivered keep NULL delivery dates.
--   * review_comment_title / review_comment_message are loaded as-is.
-- =============================================================================

USE olist_store;

-- Foreign keys are switched off for the bulk load and switched back on at the end.
SET FOREIGN_KEY_CHECKS = 0;

-- ---- 1. product_category_name_translation ----------------------------------
LOAD DATA LOCAL INFILE '/path/to/olist_csv/product_category_name_translation.csv'
INTO TABLE product_category_name_translation
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

INSERT IGNORE INTO product_category_name_translation VALUES ('unknown', 'unknown');

-- ---- 2. customers -----------------------------------------------------------
LOAD DATA LOCAL INFILE '/path/to/olist_csv/olist_customers_dataset.csv'
INTO TABLE olist_customers_dataset
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

-- ---- 3. sellers ---------------------------------------------------------------
LOAD DATA LOCAL INFILE '/path/to/olist_csv/olist_sellers_dataset.csv'
INTO TABLE olist_sellers_dataset
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

-- ---- 4. products (blank category -> 'unknown', blank numbers -> NULL) ---------
LOAD DATA LOCAL INFILE '/path/to/olist_csv/olist_products_dataset.csv'
INTO TABLE olist_products_dataset
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(product_id, @cat, @name_len, @desc_len, @photos, @weight, @length, @height, @width)
SET product_category_name       = IF(@cat = '', 'unknown', @cat),
    product_name_lenght         = NULLIF(@name_len, ''),
    product_description_lenght  = NULLIF(@desc_len, ''),
    product_photos_qty          = NULLIF(@photos, ''),
    product_weight_g            = NULLIF(@weight, ''),
    product_length_cm           = NULLIF(@length, ''),
    product_height_cm           = NULLIF(@height, ''),
    product_width_cm            = NULLIF(@width, '');

-- ---- 5. orders (blank timestamps -> NULL) --------------------------------------
LOAD DATA LOCAL INFILE '/path/to/olist_csv/olist_orders_dataset.csv'
INTO TABLE olist_orders_dataset
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(order_id, customer_id, order_status, order_purchase_timestamp, @approved,
 @carrier, @delivered, @estimated)
SET order_approved_at             = NULLIF(@approved, ''),
    order_delivered_carrier_date  = NULLIF(@carrier, ''),
    order_delivered_customer_date = NULLIF(@delivered, ''),
    order_estimated_delivery_date = NULLIF(@estimated, '');

-- ---- 6. order items ------------------------------------------------------------
LOAD DATA LOCAL INFILE '/path/to/olist_csv/olist_order_items_dataset.csv'
INTO TABLE olist_order_items_dataset
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

-- ---- 7. order payments ---------------------------------------------------------
LOAD DATA LOCAL INFILE '/path/to/olist_csv/olist_order_payments_dataset.csv'
INTO TABLE olist_order_payments_dataset
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

-- ---- 8. order reviews ----------------------------------------------------------
LOAD DATA LOCAL INFILE '/path/to/olist_csv/olist_order_reviews_dataset.csv'
INTO TABLE olist_order_reviews_dataset
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

-- ---- 9. raw geolocation (~1M rows, not used by the KPIs) -----------------------
LOAD DATA LOCAL INFILE '/path/to/olist_csv/olist_geolocation_dataset.csv'
INTO TABLE olist_geolocation_dataset
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

-- ---- 10. geo_zip_lookup: one row per zip prefix --------------------------------
-- lat / lng = average of the raw rows for that zip prefix; city / state = most
-- frequent value for that zip prefix.
-- [TODO] My shipped database used a slightly different city rule: this statement
--        reproduces all lat/lng and state values and 18,930 of 19,015 city values.
INSERT INTO geo_zip_lookup (zip_code_prefix, geolocation_lat, geolocation_lng, geolocation_city, geolocation_state)
WITH zip_avg AS (
    SELECT geolocation_zip_code_prefix AS zip_code_prefix,
           AVG(geolocation_lat) AS lat,
           AVG(geolocation_lng) AS lng
    FROM olist_geolocation_dataset
    GROUP BY geolocation_zip_code_prefix
),
city_rank AS (
    SELECT geolocation_zip_code_prefix AS zip_code_prefix,
           geolocation_city  AS city,
           geolocation_state AS state,
           ROW_NUMBER() OVER (PARTITION BY geolocation_zip_code_prefix
                              ORDER BY COUNT(*) DESC, geolocation_city, geolocation_state) AS rn
    FROM olist_geolocation_dataset
    GROUP BY geolocation_zip_code_prefix, geolocation_city, geolocation_state
)
SELECT a.zip_code_prefix, a.lat, a.lng, c.city, c.state
FROM zip_avg a
JOIN city_rank c ON c.zip_code_prefix = a.zip_code_prefix AND c.rn = 1;

-- Zip prefixes used by customers / sellers that do not exist in the raw geolocation
-- table (162 in my data) are added with NULL coordinates so the foreign keys hold.
INSERT IGNORE INTO geo_zip_lookup (zip_code_prefix)
SELECT customer_zip_code_prefix FROM olist_customers_dataset
UNION
SELECT seller_zip_code_prefix FROM olist_sellers_dataset;

SET FOREIGN_KEY_CHECKS = 1;

-- ---- Sanity checks (expected values in the comments) ---------------------------
SELECT 'orders'          AS tbl, COUNT(*) AS row_count FROM olist_orders_dataset              -- 99,441
UNION ALL SELECT 'customers',   COUNT(*) FROM olist_customers_dataset                         -- 99,441
UNION ALL SELECT 'order_items', COUNT(*) FROM olist_order_items_dataset                       -- 112,650
UNION ALL SELECT 'payments',    COUNT(*) FROM olist_order_payments_dataset                    -- 103,886
UNION ALL SELECT 'reviews',     COUNT(*) FROM olist_order_reviews_dataset                     -- 99,224 in the Kaggle CSV (99,223 in my database export)
UNION ALL SELECT 'products',    COUNT(*) FROM olist_products_dataset                          -- 32,951
UNION ALL SELECT 'sellers',     COUNT(*) FROM olist_sellers_dataset                           -- 3,095
UNION ALL SELECT 'geolocation (raw)', COUNT(*) FROM olist_geolocation_dataset;                -- 1,000,163
