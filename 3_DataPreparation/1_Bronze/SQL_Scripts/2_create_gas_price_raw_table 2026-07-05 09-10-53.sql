DROP TABLE IF EXISTS iceberg.raw.us_gas_prices;

CREATE TABLE IF NOT EXISTS iceberg.raw.us_gas_prices (
    date VARCHAR,
    gasoline_regular DOUBLE,
    diesel DOUBLE
) WITH (format = 'PARQUET');