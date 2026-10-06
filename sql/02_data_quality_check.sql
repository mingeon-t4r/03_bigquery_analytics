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


-- 4. NULL check

SELECT
    COUNT(*) AS total_rows,

    COUNTIF(starttime IS NULL)
        AS starttime_null_count,

    COUNTIF(stoptime IS NULL)
        AS stoptime_null_count,

    COUNTIF(start_station_name IS NULL)
        AS start_station_null_count,

    COUNTIF(end_station_name IS NULL)
        AS end_station_null_count

FROM
    `bigquery-public-data.new_york_citibike.citibike_trips`;


-- 5. NULL rate

SELECT
    COUNT(*) AS total_rows,

    COUNTIF(starttime IS NULL)
        AS starttime_null_count,

    SAFE_DIVIDE(
        COUNTIF(starttime IS NULL),
        COUNT(*)
    ) AS starttime_null_rate,

    COUNTIF(stoptime IS NULL)
        AS stoptime_null_count,

    SAFE_DIVIDE(
        COUNTIF(stoptime IS NULL),
        COUNT(*)
    ) AS stoptime_null_rate,

    COUNTIF(start_station_name IS NULL)
        AS start_station_name_null_count,

    SAFE_DIVIDE(
        COUNTIF(start_station_name IS NULL),
        COUNT(*)
    ) AS start_station_name_null_rate,

    COUNTIF(end_station_name IS NULL)
        AS end_station_name_null_count,

    SAFE_DIVIDE(
        COUNTIF(end_station_name IS NULL),
        COUNT(*)
    ) AS end_station_name_null_rate


FROM
    `bigquery-public-data.new_york_citibike.citibike_trips`;


-- 6. Invalid trip time

SELECT
    COUNT(*) AS invalid_trip_count
FROM
    `bigquery-public-data.new_york_citibike.citibike_trips`
WHERE
    stoptime < starttime;