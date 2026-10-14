-- ============================================
-- Project #3 - BigQuery Analytics
-- Day 8 - Views & Reusable Analytics Layer
--
-- Source:
-- bigquery-analytics-study.bigquery_learning.station_monthly_summary
--
-- Grain:
-- Month x Start Station
--
-- Source Rows: 24,876
-- Source Trips: 53,108,721
-- Source Stations: 881
--
-- Note:
-- CREATE VIEW and CREATE MATERIALIZED VIEW
-- statements are for initial setup only.
-- Existing objects must be handled before
-- re-running creation statements.
-- ============================================


-- ============================================
-- 1. Create Monthly Station View
-- ============================================

-- Standard View:
-- Does not store query result data.
-- Provides a reusable interface to the Data Mart.

CREATE VIEW
    `bigquery-analytics-study.bigquery_learning.vw_station_monthly_usage`

AS

SELECT
    trip_month,
    station_id,
    trip_count

FROM
    `bigquery-analytics-study.bigquery_learning.station_monthly_summary`;


-- ============================================
-- 2. Validate Monthly View Aggregates
-- ============================================

-- Expected:
-- Both rows = 24,876
-- Both trips = 53,108,721
-- Both months = 53
-- Both stations = 881

SELECT
    'original' AS source_type,
    COUNT(*) AS total_rows,
    SUM(trip_count) AS total_trips,
    COUNT(DISTINCT trip_month) AS total_months,
    COUNT(DISTINCT station_id) AS total_stations

FROM
    `bigquery-analytics-study.bigquery_learning.station_monthly_summary`

UNION ALL

SELECT
    'view' AS source_type,
    COUNT(*) AS total_rows,
    SUM(trip_count) AS total_trips,
    COUNT(DISTINCT trip_month) AS total_months,
    COUNT(DISTINCT station_id) AS total_stations

FROM
    `bigquery-analytics-study.bigquery_learning.vw_station_monthly_usage`;


-- ============================================
-- 3. Validate Monthly View Row-Level Data
-- ============================================

-- Expected:
-- compared_rows = 24,876
-- missing_in_original = 0
-- missing_in_view = 0
-- mismatched_count = 0

WITH original AS (
    SELECT
        trip_month,
        station_id,
        trip_count

    FROM
        `bigquery-analytics-study.bigquery_learning.station_monthly_summary`
),

view_data AS (
    SELECT
        trip_month,
        station_id,
        trip_count

    FROM
        `bigquery-analytics-study.bigquery_learning.vw_station_monthly_usage`
)

SELECT
    COUNT(*) AS compared_rows,

    COUNTIF(
        o.trip_month IS NULL
    ) AS missing_in_original,

    COUNTIF(
        v.trip_month IS NULL
    ) AS missing_in_view,

    COUNTIF(
        o.trip_count IS DISTINCT FROM v.trip_count
    ) AS mismatched_count

FROM
    original o

FULL OUTER JOIN
    view_data v

    ON o.trip_month = v.trip_month
    AND o.station_id = v.station_id;


-- ============================================
-- 4. Station TOP 10 Using Monthly View
-- ============================================

-- Aggregation logic is written in the query.

SELECT
    station_id,
    SUM(trip_count) AS total_trips

FROM
    `bigquery-analytics-study.bigquery_learning.vw_station_monthly_usage`

GROUP BY
    station_id

ORDER BY
    total_trips DESC,
    station_id

LIMIT 10;


-- ============================================
-- 5. Create Reusable Station Aggregation View
-- ============================================

-- Stores aggregation SQL definition.
-- Does not physically store aggregated results.

CREATE VIEW
    `bigquery-analytics-study.bigquery_learning.vw_station_total_usage`

AS

SELECT
    station_id,
    SUM(trip_count) AS total_trips

FROM
    `bigquery-analytics-study.bigquery_learning.vw_station_monthly_usage`

GROUP BY
    station_id;


-- ============================================
-- 6. Station TOP 10 Using Aggregation View
-- ============================================

-- No SUM() or GROUP BY required in this query.

SELECT
    station_id,
    total_trips

FROM
    `bigquery-analytics-study.bigquery_learning.vw_station_total_usage`

ORDER BY
    total_trips DESC,
    station_id

LIMIT 10;


-- ============================================
-- 7. Validate All Station Aggregates
-- ============================================

-- Expected:
-- compared_stations = 881
-- missing_in_original = 0
-- missing_in_view = 0
-- mismatched_count = 0

WITH original AS (
    SELECT
        station_id,
        SUM(trip_count) AS total_trips

    FROM
        `bigquery-analytics-study.bigquery_learning.station_monthly_summary`

    GROUP BY
        station_id
),

view_data AS (
    SELECT
        station_id,
        total_trips

    FROM
        `bigquery-analytics-study.bigquery_learning.vw_station_total_usage`
)

SELECT
    COUNT(*) AS compared_stations,

    COUNTIF(
        o.station_id IS NULL
    ) AS missing_in_original,

    COUNTIF(
        v.station_id IS NULL
    ) AS missing_in_view,

    COUNTIF(
        o.total_trips IS DISTINCT FROM v.total_trips
    ) AS mismatched_count

FROM
    original o

FULL OUTER JOIN
    view_data v

    ON o.station_id = v.station_id;


-- ============================================
-- 8. Standard View Performance Query
-- ============================================

-- Filter: station_id = 519
--
-- Observed Job Information:
-- Bytes processed: 388.69 KB
-- Bytes billed: 10 MB
-- Duration: 195 ms
-- Slot milliseconds: 5
--
-- Measurements are from one execution.

SELECT
    station_id,
    total_trips

FROM
    `bigquery-analytics-study.bigquery_learning.vw_station_total_usage`

WHERE
    station_id = 519;


-- ============================================
-- 9. Create Materialized View
-- ============================================

-- Materialized View:
-- Stores aggregated results.
-- Can reuse stored results during queries.
-- Automatic refresh is supported.

CREATE MATERIALIZED VIEW
    `bigquery-analytics-study.bigquery_learning.mv_station_total_usage`

AS

SELECT
    station_id,
    SUM(trip_count) AS total_trips

FROM
    `bigquery-analytics-study.bigquery_learning.station_monthly_summary`

GROUP BY
    station_id;


-- ============================================
-- 10. Validate Materialized View
-- ============================================

-- Expected:
-- compared_stations = 881
-- missing_in_original = 0
-- missing_in_materialized = 0
-- mismatched_count = 0

WITH original AS (
    SELECT
        station_id,
        total_trips

    FROM
        `bigquery-analytics-study.bigquery_learning.vw_station_total_usage`
),

materialized AS (
    SELECT
        station_id,
        total_trips

    FROM
        `bigquery-analytics-study.bigquery_learning.mv_station_total_usage`
)

SELECT
    COUNT(*) AS compared_stations,

    COUNTIF(
        o.station_id IS NULL
    ) AS missing_in_original,

    COUNTIF(
        m.station_id IS NULL
    ) AS missing_in_materialized,

    COUNTIF(
        o.total_trips IS DISTINCT FROM m.total_trips
    ) AS mismatched_count

FROM
    original o

FULL OUTER JOIN
    materialized m

    ON o.station_id = m.station_id;


-- ============================================
-- 11. Materialized View Performance Query
-- ============================================

-- Filter: station_id = 519
--
-- Observed Job Information:
-- Bytes processed: 13.77 KB
-- Bytes billed: 10 MB
-- Duration: 278 ms
-- Slot milliseconds: 32
--
-- Processed bytes reduction: approximately 96.5%
-- Billed bytes were identical in both queries.
-- Single-run durations do not prove
-- a latency improvement.

SELECT
    station_id,
    total_trips

FROM
    `bigquery-analytics-study.bigquery_learning.mv_station_total_usage`

WHERE
    station_id = 519;


-- ============================================
-- 12. Materialized View Refresh Metadata
-- ============================================

-- Observed:
-- last_refresh_time:
-- 2026-10-14 02:05:02.362 UTC
--
-- refresh_watermark:
-- 2026-10-14 02:05:02.362 UTC
--
-- last_refresh_status: NULL

SELECT
    table_name,
    last_refresh_time,
    refresh_watermark,
    last_refresh_status

FROM
    `bigquery-analytics-study.bigquery_learning.INFORMATION_SCHEMA.MATERIALIZED_VIEWS`

WHERE
    table_name = 'mv_station_total_usage';