-- ============================================
-- Project #3 BigQuery Analytics
-- Day 2 - Data Quality Check
-- ============================================


-- 1. Total row count

SELECT
    COUNT(*) AS total_trip_count
FROM
    `bigquery-public-data.new_york_citibike.citibike_trips`;


-- 2. Data period

SELECT
    MIN(starttime) AS first_trip,
    MAX(starttime) AS last_trip
FROM
    `bigquery-public-data.new_york_citibike.citibike_trips`;


-- 3. Trips by year

SELECT
    EXTRACT(YEAR FROM starttime) AS trip_year,
    COUNT(*) AS trip_count
FROM
    `bigquery-public-data.new_york_citibike.citibike_trips`
WHERE
    starttime IS NOT NULL
GROUP BY
    trip_year
ORDER BY
    trip_year;