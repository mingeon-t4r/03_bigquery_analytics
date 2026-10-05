-- ============================================
-- Project #3 BigQuery Analytics
-- Day 3 - Usage Pattern Analysis
-- ============================================


-- 1. Trips by year

SELECT
    EXTRACT(
        YEAR
        FROM starttime
    ) AS trip_year,

    COUNT(*) AS trip_count

FROM
    `bigquery-public-data.new_york_citibike.citibike_trips`

WHERE
    starttime IS NOT NULL

GROUP BY
    trip_year

ORDER BY
    trip_year;


-- 2. Trips by month

SELECT
    DATE_TRUNC(
        DATE(starttime),
        MONTH
    ) AS trip_month,

    COUNT(*) AS trip_count

FROM
    `bigquery-public-data.new_york_citibike.citibike_trips`

WHERE
    starttime IS NOT NULL

GROUP BY
    trip_month

ORDER BY
    trip_month;


-- 3. Trips by day of week

SELECT
    EXTRACT(
        DAYOFWEEK
        FROM starttime
    ) AS day_of_week,

    COUNT(*) AS trip_count

FROM
    `bigquery-public-data.new_york_citibike.citibike_trips`

WHERE
    starttime IS NOT NULL

GROUP BY
    day_of_week

ORDER BY
    day_of_week;


-- 4. Trips by hour

SELECT
    EXTRACT(
        HOUR
        FROM starttime
    ) AS hour_of_day,

    COUNT(*) AS trip_count

FROM
    `bigquery-public-data.new_york_citibike.citibike_trips`

WHERE
    starttime IS NOT NULL

GROUP BY
    hour_of_day

ORDER BY
    hour_of_day;


-- 5. Trips by day of week and hour

SELECT
    EXTRACT(
        DAYOFWEEK
        FROM starttime
    ) AS day_of_week,

    EXTRACT(
        HOUR
        FROM starttime
    ) AS trip_hour,

    COUNT(*) AS trip_count

FROM
    `bigquery-public-data.new_york_citibike.citibike_trips`

WHERE
    starttime IS NOT NULL

GROUP BY
    day_of_week,
    trip_hour

ORDER BY
    day_of_week,
    trip_hour;