-- ============================================
-- Project #3 - BigQuery Analytics
-- Day 7 - Partitioning & Clustering
--
-- Source:
-- bigquery-analytics-study.bigquery_learning.station_monthly_summary
--
-- Note:
-- CREATE TABLE statements are for initial setup.
-- Re-running requires handling existing tables.
-- ============================================


-- ============================================
-- 1. Date Partitioning (Sandbox Limitation)
-- ============================================

-- Initial experiment:
-- The table was created, but no rows remained.
-- Partition expiration was set to 60 days.
-- Historical data: 2013-2018.
--
-- The following SQL is retained for reference.
-- Do not execute in the current Sandbox environment.

/*
CREATE TABLE
    `bigquery-analytics-study.bigquery_learning.station_monthly_partitioned`

PARTITION BY
    trip_month

AS

SELECT
    trip_month,
    station_id,
    trip_count

FROM
    `bigquery-analytics-study.bigquery_learning.station_monthly_summary`;
*/


-- ============================================
-- 2. Integer Range Partitioning
-- ============================================

CREATE TABLE
    `bigquery-analytics-study.bigquery_learning.station_monthly_integer_partitioned`

PARTITION BY
    RANGE_BUCKET(
        station_id,
        GENERATE_ARRAY(0, 10000, 100)
    )

AS

SELECT
    trip_month,
    station_id,
    trip_count

FROM
    `bigquery-analytics-study.bigquery_learning.station_monthly_summary`;


-- ============================================
-- 3. Validate Total Rows and Trips
-- ============================================

WITH original AS (
    SELECT
        COUNT(*) AS total_rows,
        SUM(trip_count) AS total_trips
    FROM
        `bigquery-analytics-study.bigquery_learning.station_monthly_summary`
),

partitioned AS (
    SELECT
        COUNT(*) AS total_rows,
        SUM(trip_count) AS total_trips
    FROM
        `bigquery-analytics-study.bigquery_learning.station_monthly_integer_partitioned`
)

SELECT
    o.total_rows AS original_rows,
    p.total_rows AS partitioned_rows,
    o.total_rows - p.total_rows AS row_difference,

    o.total_trips AS original_trips,
    p.total_trips AS partitioned_trips,
    o.total_trips - p.total_trips AS trip_difference

FROM
    original o

CROSS JOIN
    partitioned p;


-- ============================================
-- 4. Validate Partition Metadata
-- ============================================

SELECT
    partition_id,
    total_rows,
    total_logical_bytes

FROM
    `bigquery-analytics-study.bigquery_learning.INFORMATION_SCHEMA.PARTITIONS`

WHERE
    table_name = 'station_monthly_integer_partitioned'

ORDER BY
    SAFE_CAST(partition_id AS INT64);


-- ============================================
-- 5. Validate Partition Count and Total Rows
-- ============================================

SELECT
    COUNT(*) AS partition_count,
    SUM(total_rows) AS partition_total_rows,
    SUM(total_logical_bytes) AS total_logical_bytes

FROM
    `bigquery-analytics-study.bigquery_learning.INFORMATION_SCHEMA.PARTITIONS`

WHERE
    table_name = 'station_monthly_integer_partitioned';


-- ============================================
-- 6. Partition Pruning Comparison
-- ============================================

-- 6.1 Original Data Mart

SELECT
    trip_month,
    station_id,
    trip_count

FROM
    `bigquery-analytics-study.bigquery_learning.station_monthly_summary`

WHERE
    station_id = 519;


-- 6.2 Integer Partitioned Data Mart

SELECT
    trip_month,
    station_id,
    trip_count

FROM
    `bigquery-analytics-study.bigquery_learning.station_monthly_integer_partitioned`

WHERE
    station_id = 519;


-- ============================================
-- 7. Validate Station 519 Data
-- ============================================

WITH original AS (
    SELECT
        trip_month,
        station_id,
        trip_count

    FROM
        `bigquery-analytics-study.bigquery_learning.station_monthly_summary`

    WHERE
        station_id = 519
),

partitioned AS (
    SELECT
        trip_month,
        station_id,
        trip_count

    FROM
        `bigquery-analytics-study.bigquery_learning.station_monthly_integer_partitioned`

    WHERE
        station_id = 519
)

SELECT
    COUNT(*) AS compared_rows,

    COUNTIF(
        o.trip_month IS NULL
    ) AS missing_in_original,

    COUNTIF(
        p.trip_month IS NULL
    ) AS missing_in_partitioned,

    COUNTIF(
        o.trip_count != p.trip_count
    ) AS mismatched_count

FROM
    original o

FULL OUTER JOIN
    partitioned p

    ON o.trip_month = p.trip_month
    AND o.station_id = p.station_id;


-- ============================================
-- 8. Partitioning + Clustering
-- ============================================

CREATE TABLE
    `bigquery-analytics-study.bigquery_learning.station_monthly_partitioned_clustered`

PARTITION BY
    RANGE_BUCKET(
        station_id,
        GENERATE_ARRAY(0, 10000, 100)
    )

CLUSTER BY
    trip_month

AS

SELECT
    trip_month,
    station_id,
    trip_count

FROM
    `bigquery-analytics-study.bigquery_learning.station_monthly_summary`;


-- ============================================
-- 9. Validate Clustered Table
-- ============================================

WITH original AS (
    SELECT
        trip_month,
        station_id,
        trip_count
    FROM
        `bigquery-analytics-study.bigquery_learning.station_monthly_summary`
),

clustered AS (
    SELECT
        trip_month,
        station_id,
        trip_count
    FROM
        `bigquery-analytics-study.bigquery_learning.station_monthly_partitioned_clustered`
),

comparison AS (
    SELECT
        o.trip_month AS original_month,
        c.trip_month AS clustered_month,
        o.trip_count AS original_trips,
        c.trip_count AS clustered_trips

    FROM
        original o

    FULL OUTER JOIN
        clustered c

        ON o.trip_month = c.trip_month
        AND o.station_id = c.station_id
)

SELECT
    COUNT(*) AS compared_rows,

    COUNTIF(
        original_month IS NULL
    ) AS missing_in_original,

    COUNTIF(
        clustered_month IS NULL
    ) AS missing_in_clustered,

    COUNTIF(
        original_trips != clustered_trips
    ) AS mismatched_count

FROM
    comparison;


-- ============================================
-- 10. Clustering Performance Comparison
-- ============================================

-- 10.1 Partitioning Only

SELECT
    trip_month,
    station_id,
    trip_count

FROM
    `bigquery-analytics-study.bigquery_learning.station_monthly_integer_partitioned`

WHERE
    station_id = 519
    AND trip_month = DATE '2017-01-01';


-- 10.2 Partitioning + Clustering

SELECT
    trip_month,
    station_id,
    trip_count

FROM
    `bigquery-analytics-study.bigquery_learning.station_monthly_partitioned_clustered`

WHERE
    station_id = 519
    AND trip_month = DATE '2017-01-01';