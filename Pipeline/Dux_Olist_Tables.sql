CREATE DATABASE DUX_olist

DROP TABLE IF EXISTS dbo.olist_orders;
DROP TABLE IF EXISTS dbo.olist_customers;
DROP TABLE IF EXISTS dbo.olist_sellers;
DROP TABLE IF EXISTS dbo.olist_order_items;
DROP TABLE IF EXISTS dbo.olist_geolocation;
DROP TABLE IF EXISTS dbo.olist_products;
DROP TABLE IF EXISTS dbo.olist_category_name_translation;
DROP TABLE IF EXISTS dbo.olist_order_payments;
DROP TABLE IF EXISTS dbo.olist_order_reviews;

CREATE TABLE dbo.olist_orders (
    order_id VARCHAR(50),
    customer_id VARCHAR(50),
    order_status VARCHAR(30),
    order_purchase_timestamp DATETIME2,
    order_approved_at DATETIME2,
    order_delivered_carrier_date DATETIME2,
    order_delivered_customer_date DATETIME2,
    order_estimated_delivery_date DATETIME2
)

CREATE TABLE dbo.olist_customers (
    customer_id VARCHAR(50),
    customer_unique_id VARCHAR(50),
    customer_zip_code_prefix VARCHAR(10),
    customer_city VARCHAR(100),
    customer_state VARCHAR(10)
)

CREATE TABLE dbo.olist_sellers (
    seller_id VARCHAR(50),
    seller_zip_code_prefix VARCHAR(10),
    seller_city VARCHAR(100),
    seller_state VARCHAR(10)
)

CREATE TABLE dbo.olist_order_items (
    order_id VARCHAR(50),
    order_item_id INT,
    product_id VARCHAR(50),
    seller_id VARCHAR(50),
    shipping_limit_date DATETIME2,
    price DECIMAL(18,2),
    freight_value DECIMAL(18,2)
)

CREATE TABLE dbo.olist_geolocation (
    geolocation_zip_code_prefix VARCHAR(10),
    geolocation_lat VARCHAR(30),
    geolocation_lng VARCHAR(30),
    geolocation_city VARCHAR(100),
    geolocation_state VARCHAR(10)
)

CREATE TABLE dbo.olist_products (
    product_id VARCHAR(50),
    product_category_name VARCHAR(100),
    product_name_lenght INT,
    product_description_lenght INT,
    product_photos_qty INT,
    product_weight_g DECIMAL(10,2),
    product_length_cm DECIMAL(10,2),
    product_height_cm DECIMAL(10,2),
    product_width_cm DECIMAL(10,2)
)

CREATE TABLE dbo.olist_category_name_translation (
    product_category_name VARCHAR(100),
    product_category_name_english VARCHAR(100)
)

CREATE TABLE dbo.olist_order_payments (
    order_id VARCHAR(50),
    payment_sequential INT,
    payment_type VARCHAR(30),
    payment_installments INT,
    payment_value DECIMAL(18,2)
)

CREATE TABLE dbo.olist_order_reviews (
    review_id VARCHAR(50),
    order_id VARCHAR(50),
    review_score INT,
    review_comment_title VARCHAR(500),
    review_comment_message VARCHAR(2000),
    review_creation_date DATETIME2,
    review_answer_timestamp DATETIME2
)