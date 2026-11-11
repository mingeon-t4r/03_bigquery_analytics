
-- Day 13: Final Station Analysis
-- Source: station_monthly_summary
-- Grain: Month x Station

-- 1. Station summary and final priority candidates
WITH station_summary AS (
    SELECT
        station_id,
        COUNT(*) AS month_count,
        SUM(trip_count) AS total_trips,
        AVG(trip_count) AS avg_monthly_trips,
        STDDEV_POP(trip_count) AS std_monthly_trips,
        SAFE_DIVIDE(
            STDDEV_POP(trip_count),
            AVG(trip_count)
        ) * 100 AS cv
    FROM
        `bigquery-analytics-study.bigquery_learning.station_monthly_summary`
    GROUP BY
        station_id
),

eligible_stations AS (
    SELECT
        *
    FROM
        station_summary
    WHERE
        month_count >= 24
),

average_threshold AS (
    SELECT DISTINCT
        PERCENTILE_CONT(
            avg_monthly_trips,
            0.75
        ) OVER () AS threshold
    FROM
        eligible_stations
),

high_demand_stations AS (
    SELECT
        e.*
    FROM
        eligible_stations e
    CROSS JOIN
        average_threshold a
    WHERE
        e.avg_monthly_trips >= a.threshold
),

cv_threshold AS (
    SELECT DISTINCT
        PERCENTILE_CONT(
            cv,
            0.75
        ) OVER () AS threshold
    FROM
        high_demand_stations
),

priority_stations AS (
    SELECT
        h.*
    FROM
        high_demand_stations h
    CROSS JOIN
        cv_threshold c
    WHERE
        h.cv >= c.threshold
)

SELECT
    station_id,
    month_count,
    total_trips,
    ROUND(avg_monthly_trips, 2) AS avg_monthly_trips,
    ROUND(std_monthly_trips, 2) AS std_monthly_trips,
    ROUND(cv, 2) AS cv
FROM
    priority_stations
ORDER BY
    cv DESC,
    avg_monthly_trips DESC,
    station_id;


-- 2. Station 514 vs Station 2006
SELECT
    station_id,
    COUNT(*) AS month_count,
    SUM(trip_count) AS total_trips,
    AVG(trip_count) AS avg_monthly_trips,
    STDDEV_POP(trip_count) AS std_monthly_trips,
    SAFE_DIVIDE(
        STDDEV_POP(trip_count),
        AVG(trip_count)
    ) * 100 AS cv
FROM
    `bigquery-analytics-study.bigquery_learning.station_monthly_summary`
WHERE
    station_id IN (514, 2006)
GROUP BY
    station_id
ORDER BY
    station_id;


-- 3. Monthly history for comparison
SELECT
    trip_month,
    station_id,
    trip_count
FROM
    `bigquery-analytics-study.bigquery_learning.station_monthly_summary`
WHERE
    station_id IN (514, 2006)
ORDER BY
    trip_month,
    station_id;


-- 4. Final data mart validation
SELECT
    COUNT(*) AS row_count,
    COUNT(DISTINCT station_id) AS station_count,
    SUM(trip_count) AS total_trips,
    COUNTIF(trip_month IS NULL) AS null_month_count,
    COUNTIF(station_id IS NULL) AS null_station_count,
    COUNTIF(trip_count IS NULL) AS null_trip_count,
    COUNTIF(trip_count < 0) AS negative_trip_count
FROM
    `bigquery-analytics-study.bigquery_learning.station_monthly_summary`;
