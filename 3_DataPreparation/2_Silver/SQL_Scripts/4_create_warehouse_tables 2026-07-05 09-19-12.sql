DROP SCHEMA IF EXISTS iceberg.warehouse;

CREATE SCHEMA IF NOT EXISTS iceberg.warehouse;


DROP TABLE IF EXISTS iceberg.warehouse.distribution_centers;

CREATE TABLE iceberg.warehouse.distribution_centers (
    id INT,
    latitude DOUBLE,
    longitude DOUBLE,
    city VARCHAR,
    state VARCHAR
)
WITH (
    format = 'PARQUET'
);

DROP TABLE IF EXISTS iceberg.warehouse.events;

CREATE TABLE iceberg.warehouse.events (
    user_id BIGINT,
    sequence_number BIGINT,
    session_id VARCHAR,
    created_at TIMESTAMP(6) WITH TIME ZONE,
    state VARCHAR,
    browser VARCHAR,
    traffic_source VARCHAR,
    uri VARCHAR,
    event_type VARCHAR
)
WITH (
    format = 'PARQUET',
    partitioning = ARRAY['month(created_at)']
);



DROP TABLE IF EXISTS iceberg.warehouse.inventory_items;

CREATE TABLE iceberg.warehouse.inventory_items (
    id BIGINT,
    product_id BIGINT,
    created_at TIMESTAMP(6) WITH TIME ZONE,
    sold_at TIMESTAMP(6) WITH TIME ZONE,
    cost DOUBLE,
    product_category VARCHAR,
    product_name VARCHAR,
    product_brand VARCHAR,
    product_retail_price DOUBLE,
    product_department VARCHAR,
    product_sku VARCHAR,
    product_distribution_center_id BIGINT
)
WITH (
    format = 'PARQUET',
    partitioning = ARRAY['month(created_at)']
);



DROP TABLE IF EXISTS iceberg.warehouse.order_items;

CREATE TABLE iceberg.warehouse.order_items (
    id BIGINT,
    order_id BIGINT,
    user_id BIGINT,
    product_id BIGINT,
    inventory_item_id BIGINT,
    status VARCHAR,
    created_at TIMESTAMP(6) WITH TIME ZONE,
    shipped_at TIMESTAMP(6) WITH TIME ZONE,
    delivered_at TIMESTAMP(6) WITH TIME ZONE,
    returned_at TIMESTAMP(6) WITH TIME ZONE,
    sale_price DOUBLE
)
WITH (
    format = 'PARQUET',
    partitioning = ARRAY['month(created_at)']
);



CREATE TABLE iceberg.warehouse.orders (
    order_id BIGINT,
    user_id BIGINT,
    status VARCHAR,
    gender VARCHAR,
    created_at TIMESTAMP(6) WITH TIME ZONE,
    returned_at TIMESTAMP(6) WITH TIME ZONE,
    shipped_at TIMESTAMP(6) WITH TIME ZONE,
    delivered_at TIMESTAMP(6) WITH TIME ZONE,
    num_of_item BIGINT
)
WITH (
    format = 'PARQUET',
    partitioning = ARRAY['month(created_at)']
);

DROP TABLE IF EXISTS iceberg.warehouse.products;

CREATE TABLE iceberg.warehouse.products (
    id BIGINT,
    cost DOUBLE,
    category VARCHAR,
    name VARCHAR,
    brand VARCHAR,
    retail_price DOUBLE,
    department VARCHAR,
    sku VARCHAR,
    distribution_center_id BIGINT
)
WITH (
    format = 'PARQUET'
);



CREATE TABLE iceberg.warehouse.users (
    id BIGINT,
    first_name VARCHAR,
    last_name VARCHAR,
    email VARCHAR,
    age BIGINT,
    gender VARCHAR,
    state VARCHAR,
    street_address VARCHAR,
    postal_code VARCHAR,
    city VARCHAR,
    country VARCHAR,
    latitude DOUBLE,
    longitude DOUBLE,
    traffic_source VARCHAR,
    created_at TIMESTAMP(6) WITH TIME ZONE
)
WITH (
    format = 'PARQUET',
    partitioning = ARRAY['month(created_at)']
);


DROP TABLE IF EXISTS iceberg.warehouse.us_gas_prices;

CREATE TABLE iceberg.warehouse.us_gas_prices (
    date DATE,
    gasoline_regular DOUBLE,
    diesel DOUBLE
)
WITH (
    format = 'PARQUET',
    partitioning = ARRAY['year(date)']
);


DROP TABLE IF EXISTS iceberg.warehouse.us_holidays;

CREATE TABLE IF NOT EXISTS iceberg.warehouse.us_holidays (
    date DATE,
    holiday_name VARCHAR,
    type VARCHAR
) WITH (format = 'PARQUET');