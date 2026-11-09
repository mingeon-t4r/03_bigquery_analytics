
-- Day 12: BigQuery Station Analysis Pipeline
-- Source: station_monthly_summary

-- 1. Data Quality Validation
SELECT
    COUNT(*) AS row_count,
    COUNTIF(trip_month IS NULL) AS null_month_count,
    COUNTIF(station_id IS NULL) AS null_station_count,
    COUNTIF(trip_count IS NULL) AS null_trip_count,
    COUNTIF(trip_count < 0) AS negative_trip_count,
    SUM(trip_count) AS total_trips
FROM
    `bigquery-analytics-study.bigquery_learning.station_monthly_summary`;


-- 2. Duplicate Grain Validation
SELECT
    trip_month,
    station_id,
    COUNT(*) AS duplicate_count
FROM
    `bigquery-analytics-study.bigquery_learning.station_monthly_summary`
GROUP BY
    trip_month,
    station_id
HAVING
    COUNT(*) > 1;


-- 3. Station Summary
SELECT
    station_id,
    COUNT(*) AS month_count,
    SUM(trip_count) AS total_trips,
    AVG(trip_count) AS avg_monthly_trips
FROM
    `bigquery-analytics-study.bigquery_learning.station_monthly_summary`
GROUP BY
    station_id
ORDER BY
    station_id;


-- 4. Top 10 by Total Trips
SELECT
    station_id,
    COUNT(*) AS month_count,
    SUM(trip_count) AS total_trips,
    AVG(trip_count) AS avg_monthly_trips
FROM
    `bigquery-analytics-study.bigquery_learning.station_monthly_summary`
GROUP BY
    station_id
ORDER BY
    total_trips DESC,
    station_id
LIMIT 10;


-- 5. Top 10 by Monthly Average
SELECT
    station_id,
    COUNT(*) AS month_count,
    SUM(trip_count) AS total_trips,
    AVG(trip_count) AS avg_monthly_trips
FROM
    `bigquery-analytics-study.bigquery_learning.station_monthly_summary`
GROUP BY
    station_id
ORDER BY
    avg_monthly_trips DESC,
    station_id
LIMIT 10;
