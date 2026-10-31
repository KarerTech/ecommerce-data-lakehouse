DROP TABLE IF EXISTS iceberg.raw.us_holidays;

CREATE TABLE IF NOT EXISTS iceberg.raw.us_holidays (
    date VARCHAR,
    holiday_name VARCHAR,
    type VARCHAR
) WITH (format = 'PARQUET');