-- ============================================
-- Project #3 - BigQuery Analytics
-- Day 6 - Data Mart Creation & Validation
--
-- Source:
-- bigquery-public-data.new_york_citibike.citibike_trips
--
-- Target:
-- bigquery-analytics-study.bigquery_learning.station_monthly_summary
--
-- Grain:
-- 1 row = 1 Month x 1 Start Station
--
-- Note:
-- CREATE TABLE is intended for initial creation.
-- Re-running it requires handling the existing table.
-- ============================================

-- ============================================
-- Day 6 - Create Station Monthly Data Mart
-- ============================================

CREATE TABLE
    `bigquery-analytics-study.bigquery_learning.station_monthly_summary`
AS

SELECT
    DATE_TRUNC(
        DATE(starttime),
        MONTH
    ) AS trip_month,

    start_station_id AS station_id,

    COUNT(*) AS trip_count

FROM
    `bigquery-public-data.new_york_citibike.citibike_trips`

WHERE
    starttime IS NOT NULL
    AND start_station_id IS NOT NULL

GROUP BY
    trip_month,
    station_id;

-- ============================================
-- 1. Validate Station Monthly Data Mart
-- ============================================

-- ============================================
-- 1.1 Validate Row Count, Unique Months, Unique Stations, First Month, Last Month, Total Trips
-- ============================================

SELECT
    COUNT(*) AS total_rows,

    COUNT(DISTINCT trip_month) AS unique_months,

    COUNT(DISTINCT station_id) AS unique_stations,

    MIN(trip_month) AS first_month,

    MAX(trip_month) AS last_month,

    SUM(trip_count) AS total_trips

FROM
    `bigquery-analytics-study.bigquery_learning.station_monthly_summary`;

-- ============================================
-- 1.2 Validate Duplicate Rows
-- ============================================

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

-- ============================================
-- 1.3 Validate Nulls and Invalid Trip Counts
-- ============================================


SELECT
    COUNTIF(
        trip_month IS NULL
    ) AS null_month_count,

    COUNTIF(
        station_id IS NULL
    ) AS null_station_count,

    COUNTIF(
        trip_count IS NULL
    ) AS null_trip_count,

    COUNTIF(
        trip_count <= 0
    ) AS invalid_trip_count

FROM
    `bigquery-analytics-study.bigquery_learning.station_monthly_summary`;


-- ============================================
-- Day 6 - Source to Target Validation
-- 1. Total Trip Count Comparison
-- ============================================

WITH source_count AS (

    SELECT
        COUNT(*) AS total_trips

    FROM
        `bigquery-public-data.new_york_citibike.citibike_trips`

    WHERE
        starttime IS NOT NULL
        AND start_station_id IS NOT NULL
),

mart_count AS (

    SELECT
        SUM(trip_count) AS total_trips

    FROM
        `bigquery-analytics-study.bigquery_learning.station_monthly_summary`
)

SELECT
    s.total_trips AS source_trips,

    m.total_trips AS mart_trips,

    s.total_trips - m.total_trips AS trip_difference

FROM
    source_count s

CROSS JOIN
    mart_count m;


-- ============================================
-- 2. Monthly Trip Count Comparison
-- ============================================

WITH source_monthly AS (

    SELECT
        DATE_TRUNC(
            DATE(starttime),
            MONTH
        ) AS trip_month,

        COUNT(*) AS source_trips

    FROM
        `bigquery-public-data.new_york_citibike.citibike_trips`

    WHERE
        starttime IS NOT NULL
        AND start_station_id IS NOT NULL

    GROUP BY
        trip_month
),

mart_monthly AS (

    SELECT
        trip_month,

        SUM(trip_count) AS mart_trips

    FROM
        `bigquery-analytics-study.bigquery_learning.station_monthly_summary`

    GROUP BY
        trip_month
)

SELECT
    COALESCE(
        s.trip_month,
        m.trip_month
    ) AS trip_month,

    s.source_trips,
    m.mart_trips,

    COALESCE(s.source_trips, 0)
        - COALESCE(m.mart_trips, 0)
        AS trip_difference

FROM
    source_monthly s

FULL OUTER JOIN
    mart_monthly m

    ON s.trip_month = m.trip_month

WHERE
    s.trip_month IS NULL
    OR m.trip_month IS NULL
    OR s.source_trips != m.mart_trips

ORDER BY
    trip_month;

-- ============================================
-- Day 6 - Grain Level Validation
-- ============================================

WITH source_summary AS (

    SELECT
        DATE_TRUNC(
            DATE(starttime),
            MONTH
        ) AS trip_month,

        start_station_id AS station_id,

        COUNT(*) AS source_trips

    FROM
        `bigquery-public-data.new_york_citibike.citibike_trips`

    WHERE
        starttime IS NOT NULL
        AND start_station_id IS NOT NULL

    GROUP BY
        trip_month,
        station_id
),

mart_summary AS (

    SELECT
        trip_month,
        station_id,
        trip_count AS mart_trips

    FROM
        `bigquery-analytics-study.bigquery_learning.station_monthly_summary`
),

comparison AS (

    SELECT
        COALESCE(
            s.trip_month,
            m.trip_month
        ) AS trip_month,

        COALESCE(
            s.station_id,
            m.station_id
        ) AS station_id,

        s.source_trips,
        m.mart_trips

    FROM
        source_summary s

    FULL OUTER JOIN
        mart_summary m

        ON s.trip_month = m.trip_month
        AND s.station_id = m.station_id
)

SELECT
    COUNT(*) AS compared_rows,

    COUNTIF(
        source_trips IS NULL
    ) AS missing_in_source,

    COUNTIF(
        mart_trips IS NULL
    ) AS missing_in_mart,

    COUNTIF(
        source_trips != mart_trips
    ) AS mismatched_count

FROM
    comparison;