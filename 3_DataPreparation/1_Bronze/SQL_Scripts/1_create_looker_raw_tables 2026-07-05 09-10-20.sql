DROP SCHEMA IF EXISTS iceberg.raw;

CREATE SCHEMA IF NOT EXISTS iceberg.raw;


DROP TABLE IF EXISTS iceberg.raw.distribution_centers;

CREATE TABLE IF NOT EXISTS iceberg.raw.distribution_centers (
    id BIGINT,
    name VARCHAR,
    latitude DOUBLE,
    longitude DOUBLE
) WITH (format = 'PARQUET');



DROP TABLE IF EXISTS iceberg.raw.events;

CREATE TABLE IF NOT EXISTS iceberg.raw.events (
    id BIGINT,
    user_id BIGINT,
    sequence_number BIGINT,
    session_id VARCHAR,
    created_at TIMESTAMP(6) WITH TIME ZONE,
    ip_address VARCHAR,
    city VARCHAR,
    state VARCHAR,
    postal_code VARCHAR,
    browser VARCHAR,
    traffic_source VARCHAR,
    uri VARCHAR,
    event_type VARCHAR
)
WITH (
    format = 'PARQUET'
);




DROP TABLE IF EXISTS iceberg.raw.inventory_items;

CREATE TABLE IF NOT EXISTS iceberg.raw.inventory_items (
    id BIGINT,
    product_id BIGINT,
    created_at VARCHAR,
    sold_at VARCHAR,
    cost DOUBLE,
    product_category VARCHAR,
    product_name VARCHAR,
    product_brand VARCHAR,
    product_retail_price DOUBLE,
    product_department VARCHAR,
    product_sku VARCHAR,
    product_distribution_center_id BIGINT
) WITH (format = 'PARQUET');



DROP TABLE IF EXISTS iceberg.raw.order_items;

CREATE TABLE IF NOT EXISTS iceberg.raw.order_items (
    id BIGINT,
    order_id BIGINT,
    user_id BIGINT,
    product_id BIGINT,
    inventory_item_id BIGINT,
    status VARCHAR,
    created_at VARCHAR,
    shipped_at VARCHAR,
    delivered_at VARCHAR,
    returned_at VARCHAR,
    sale_price DOUBLE
) WITH (format = 'PARQUET');



DROP TABLE IF EXISTS iceberg.raw.orders;

CREATE TABLE IF NOT EXISTS iceberg.raw.orders (
    order_id BIGINT,
    user_id BIGINT,
    status VARCHAR,
    gender VARCHAR,
    created_at VARCHAR,
    returned_at VARCHAR,
    shipped_at VARCHAR,
    delivered_at VARCHAR,
    num_of_item INT
) WITH (format = 'PARQUET');


DROP TABLE IF EXISTS iceberg.raw.products;

CREATE TABLE IF NOT EXISTS iceberg.raw.products (
    id BIGINT,
    cost DOUBLE,
    category VARCHAR,
    name VARCHAR,
    brand VARCHAR,
    retail_price DOUBLE,
    department VARCHAR,
    sku VARCHAR,
    distribution_center_id BIGINT
) WITH (format = 'PARQUET');


DROP TABLE IF EXISTS iceberg.raw.users;

CREATE TABLE IF NOT EXISTS iceberg.raw.users (
    id BIGINT,
    first_name VARCHAR,
    last_name VARCHAR,
    email VARCHAR,
    age INT,
    gender VARCHAR,
    state VARCHAR,
    street_address VARCHAR,
    postal_code VARCHAR,
    city VARCHAR,
    country VARCHAR,
    latitude DOUBLE,
    longitude DOUBLE,
    traffic_source VARCHAR,
    created_at VARCHAR
) WITH (format = 'PARQUET');












