P
CREATE SCHEMA IF NOT EXISTS iceberg.datamart;


DROP TABLE IF EXISTS iceberg.datamart.dim_users;

CREATE TABLE iceberg.datamart.dim_users (
    user_id BIGINT,
    age BIGINT,
    gender VARCHAR,
    country VARCHAR,
    state VARCHAR,
    city VARCHAR,
    traffic_source VARCHAR,
    registered_at TIMESTAMP(6) WITH TIME ZONE
)
WITH (
    format = 'PARQUET'
);


DROP TABLE IF EXISTS iceberg.datamart.dim_products;

CREATE TABLE iceberg.datamart.dim_products (
    product_id BIGINT,
    product_name VARCHAR,
    category VARCHAR,
    brand VARCHAR,
    department VARCHAR,
    retail_price DOUBLE,
    dc_id INT,
    dc_city VARCHAR,
    dc_latitude DOUBLE,
    dc_longitude DOUBLE
)
WITH (
    format = 'PARQUET'
);



DROP TABLE IF EXISTS iceberg.datamart.dim_date;

CREATE TABLE iceberg.datamart.dim_date (
    date_key VARCHAR,
    year INT,
    quarter INT,
    month INT,
    week INT,
    day INT,
    day_of_week INT,
    is_weekend BOOLEAN,
    holiday_name VARCHAR,
    is_public_holiday BOOLEAN,
    us_gas_price_regular_avg DOUBLE,
    us_gas_price_diesel_avg DOUBLE
)
WITH (
    format = 'PARQUET'
);

DROP TABLE IF EXISTS iceberg.datamart.fact_sales;

CREATE TABLE iceberg.datamart.fact_sales (
    order_item_id BIGINT,
    order_id BIGINT,
    user_id BIGINT,
    product_id BIGINT,
    date_key VARCHAR,
    created_at TIMESTAMP(6) WITH TIME ZONE,
    status VARCHAR,
    sale_price DOUBLE,
    inventory_cost DOUBLE,
    gross_margin DOUBLE,
    is_returned INT
)
WITH (
    format = 'PARQUET',
    partitioning = ARRAY['month(created_at)']
);


DROP TABLE IF EXISTS iceberg.datamart.fact_events;

CREATE TABLE iceberg.datamart.fact_events (
    user_id BIGINT,
    session_id VARCHAR,
    sequence_number BIGINT,
    date_key VARCHAR,
    created_at TIMESTAMP(6) WITH TIME ZONE,
    event_type VARCHAR,
    browser VARCHAR,
    traffic_source VARCHAR,
    uri VARCHAR,
    state VARCHAR
)
WITH (
    format = 'PARQUET',
    partitioning = ARRAY['month(created_at)']
);




DROP TABLE IF EXISTS iceberg.datamart.dim_geography;

CREATE TABLE iceberg.datamart.dim_geography (
    user_id BIGINT,
    state VARCHAR,
    latitude DOUBLE,
    longitude DOUBLE
)
WITH (
    format = 'PARQUET'
);