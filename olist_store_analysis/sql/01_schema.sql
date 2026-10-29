-- =============================================================================
-- Olist Store Analysis - MySQL schema (tables, primary keys, foreign keys)
-- Target: MySQL 8.0. Creates an empty database; load the data with 02_load_data.sql
-- Schema taken from my MySQL export of the project database (10 tables, 9 foreign keys).
-- =============================================================================

CREATE DATABASE IF NOT EXISTS olist_store DEFAULT CHARACTER SET utf8mb4;
USE olist_store;

-- product_category_name_translation: Category name (Portuguese -> English). A row for "unknown" is added for products with a blank category.
DROP TABLE IF EXISTS `product_category_name_translation`;
CREATE TABLE `product_category_name_translation` (
  `product_category_name` varchar(100) NOT NULL,
  `product_category_name_english` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`product_category_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- geo_zip_lookup: One row per zip-code prefix (average lat/lng). Built from the raw geolocation table so customers and sellers can reference a unique zip key.
DROP TABLE IF EXISTS `geo_zip_lookup`;
CREATE TABLE `geo_zip_lookup` (
  `zip_code_prefix` int NOT NULL,
  `geolocation_lat` decimal(10,8) DEFAULT NULL,
  `geolocation_lng` decimal(10,8) DEFAULT NULL,
  `geolocation_city` varchar(100) DEFAULT NULL,
  `geolocation_state` varchar(2) DEFAULT NULL,
  PRIMARY KEY (`zip_code_prefix`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- olist_customers_dataset: One row per customer_id (a customer_id is created per order).
DROP TABLE IF EXISTS `olist_customers_dataset`;
CREATE TABLE `olist_customers_dataset` (
  `customer_id` varchar(32) NOT NULL,
  `customer_unique_id` varchar(32) DEFAULT NULL,
  `customer_zip_code_prefix` int DEFAULT NULL,
  `customer_city` varchar(100) DEFAULT NULL,
  `customer_state` varchar(2) DEFAULT NULL,
  PRIMARY KEY (`customer_id`),
  KEY `fk_customer_zip` (`customer_zip_code_prefix`),
  CONSTRAINT `fk_customer_zip` FOREIGN KEY (`customer_zip_code_prefix`) REFERENCES `geo_zip_lookup` (`zip_code_prefix`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- olist_sellers_dataset: One row per seller.
DROP TABLE IF EXISTS `olist_sellers_dataset`;
CREATE TABLE `olist_sellers_dataset` (
  `seller_id` varchar(32) NOT NULL,
  `seller_zip_code_prefix` int DEFAULT NULL,
  `seller_city` varchar(100) DEFAULT NULL,
  `seller_state` varchar(2) DEFAULT NULL,
  PRIMARY KEY (`seller_id`),
  KEY `fk_seller_zip` (`seller_zip_code_prefix`),
  CONSTRAINT `fk_seller_zip` FOREIGN KEY (`seller_zip_code_prefix`) REFERENCES `geo_zip_lookup` (`zip_code_prefix`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- olist_products_dataset: One row per product. Blank categories are stored as "unknown".
DROP TABLE IF EXISTS `olist_products_dataset`;
CREATE TABLE `olist_products_dataset` (
  `product_id` varchar(32) NOT NULL,
  `product_category_name` varchar(100) DEFAULT NULL,
  `product_name_lenght` int DEFAULT NULL,
  `product_description_lenght` int DEFAULT NULL,
  `product_photos_qty` int DEFAULT NULL,
  `product_weight_g` int DEFAULT NULL,
  `product_length_cm` int DEFAULT NULL,
  `product_height_cm` int DEFAULT NULL,
  `product_width_cm` int DEFAULT NULL,
  PRIMARY KEY (`product_id`),
  KEY `product_category_name` (`product_category_name`),
  CONSTRAINT `olist_products_dataset_ibfk_1` FOREIGN KEY (`product_category_name`) REFERENCES `product_category_name_translation` (`product_category_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- olist_orders_dataset: One row per order. Delivery timestamps are NULL for orders that were never delivered (kept, not filled).
DROP TABLE IF EXISTS `olist_orders_dataset`;
CREATE TABLE `olist_orders_dataset` (
  `order_id` varchar(32) NOT NULL,
  `customer_id` varchar(32) DEFAULT NULL,
  `order_status` varchar(20) DEFAULT NULL,
  `order_purchase_timestamp` datetime DEFAULT NULL,
  `order_approved_at` datetime DEFAULT NULL,
  `order_delivered_carrier_date` datetime DEFAULT NULL,
  `order_delivered_customer_date` datetime DEFAULT NULL,
  `order_estimated_delivery_date` datetime DEFAULT NULL,
  PRIMARY KEY (`order_id`),
  KEY `customer_id` (`customer_id`),
  CONSTRAINT `olist_orders_dataset_ibfk_1` FOREIGN KEY (`customer_id`) REFERENCES `olist_customers_dataset` (`customer_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- olist_order_items_dataset: One row per item in an order (an order can have several items).
DROP TABLE IF EXISTS `olist_order_items_dataset`;
CREATE TABLE `olist_order_items_dataset` (
  `order_id` varchar(32) NOT NULL,
  `order_item_id` int NOT NULL, 
  `product_id` varchar(32) DEFAULT NULL,
  `seller_id` varchar(32) DEFAULT NULL,
  `shipping_limit_date` datetime DEFAULT NULL,
  `price` decimal(10,2) DEFAULT NULL,
  `freight_value` decimal(10,2) DEFAULT NULL,
  PRIMARY KEY (`order_id`,`order_item_id`),
  KEY `product_id` (`product_id`),
  KEY `seller_id` (`seller_id`),
  CONSTRAINT `olist_order_items_dataset_ibfk_1` FOREIGN KEY (`order_id`) REFERENCES `olist_orders_dataset` (`order_id`),
  CONSTRAINT `olist_order_items_dataset_ibfk_2` FOREIGN KEY (`product_id`) REFERENCES `olist_products_dataset` (`product_id`),
  CONSTRAINT `olist_order_items_dataset_ibfk_3` FOREIGN KEY (`seller_id`) REFERENCES `olist_sellers_dataset` (`seller_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- olist_order_payments_dataset: One row per payment record (an order can have several because of installments / split payments).
DROP TABLE IF EXISTS `olist_order_payments_dataset`;
CREATE TABLE `olist_order_payments_dataset` (
  `order_id` varchar(32) NOT NULL,
  `payment_sequential` int NOT NULL,
  `payment_type` varchar(20) DEFAULT NULL,
  `payment_installments` int DEFAULT NULL,
  `payment_value` decimal(10,2) DEFAULT NULL,
  PRIMARY KEY (`order_id`,`payment_sequential`),
  CONSTRAINT `olist_order_payments_dataset_ibfk_1` FOREIGN KEY (`order_id`) REFERENCES `olist_orders_dataset` (`order_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- olist_order_reviews_dataset: One row per review (a few orders have more than one review).
DROP TABLE IF EXISTS `olist_order_reviews_dataset`;
CREATE TABLE `olist_order_reviews_dataset` (
  `review_id` varchar(32) NOT NULL,
  `order_id` varchar(32) NOT NULL,
  `review_score` int DEFAULT NULL,
  `review_comment_title` text,
  `review_comment_message` text,
  `review_creation_date` datetime DEFAULT NULL,
  `review_answer_timestamp` datetime DEFAULT NULL,
  PRIMARY KEY (`review_id`,`order_id`),
  KEY `order_id` (`order_id`),
  CONSTRAINT `olist_order_reviews_dataset_ibfk_1` FOREIGN KEY (`order_id`) REFERENCES `olist_orders_dataset` (`order_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- olist_geolocation_dataset: Raw geolocation table (~1M rows, many rows per zip prefix). Not used by the KPIs.
DROP TABLE IF EXISTS `olist_geolocation_dataset`;
CREATE TABLE `olist_geolocation_dataset` (
  `geolocation_zip_code_prefix` int DEFAULT NULL,
  `geolocation_lat` decimal(10,8) DEFAULT NULL,
  `geolocation_lng` decimal(10,8) DEFAULT NULL,
  `geolocation_city` varchar(100) DEFAULT NULL,
  `geolocation_state` varchar(2) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
