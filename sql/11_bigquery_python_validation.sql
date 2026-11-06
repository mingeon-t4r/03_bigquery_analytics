
-- Day 11: BigQuery and Python Validation
-- Source: station_monthly_summary

-- 1. Station 519 - April 2017
SELECT
    trip_month,
    station_id,
    trip_count
FROM
    `bigquery-analytics-study.bigquery_learning.station_monthly_summary`
WHERE
    station_id = 519
    AND trip_month = '2017-04-01';


-- 2. Station 519 - Monthly Detail
SELECT
    trip_month,
    station_id,
    trip_count
FROM
    `bigquery-analytics-study.bigquery_learning.station_monthly_summary`
WHERE
    station_id = 519
ORDER BY
    trip_month;


-- 3. Station 519 - SQL Summary
SELECT
    station_id,
    COUNT(*) AS month_count,
    SUM(trip_count) AS total_trips,
    ROUND(
        AVG(trip_count),
        2
    ) AS avg_monthly_trips
FROM
    `bigquery-analytics-study.bigquery_learning.station_monthly_summary`
WHERE
    station_id = 519
GROUP BY
    station_id;
