
-- ============================================================
-- Day 10: BigQuery Advanced Analytics
-- Project: 03_bigquery_analytics
-- Dataset: bigquery-analytics-study.bigquery_learning
-- Source: vw_station_monthly_usage
--
-- Topics:
-- 1. Monthly station usage share
-- 2. Station average usage
-- 3. Three-row moving average
-- 4. Consecutive three-month moving average
-- 5. Station usage variability
-- 6. QUALIFY with RANK
-- 7. Monthly share validation
-- ============================================================


-- ============================================================
-- 01. Monthly Station Usage Share
-- ============================================================

SELECT
    trip_month,
    station_id,
    trip_count,

    SUM(trip_count) OVER (
        PARTITION BY trip_month
    ) AS monthly_total_trips,

    ROUND(
        SAFE_DIVIDE(
            trip_count,
            SUM(trip_count) OVER (
                PARTITION BY trip_month
            )
        ) * 100,
        2
    ) AS station_share_pct

FROM
    `bigquery-analytics-study.bigquery_learning.vw_station_monthly_usage`

WHERE
    trip_month = '2017-04-01'

ORDER BY
    station_share_pct DESC,
    trip_count DESC,
    station_id

LIMIT 20;


-- ============================================================
-- 02. Station Average Monthly Usage
-- ============================================================

SELECT
    trip_month,
    station_id,
    trip_count,

    ROUND(
        AVG(trip_count) OVER (
            PARTITION BY station_id
        ),
        2
    ) AS avg_monthly_trips,

    ROUND(
        trip_count
        - AVG(trip_count) OVER (
            PARTITION BY station_id
        ),
        2
    ) AS difference_from_avg

FROM
    `bigquery-analytics-study.bigquery_learning.vw_station_monthly_usage`

WHERE
    station_id = 519

ORDER BY
    trip_month;


-- ============================================================
-- 03. Three-Row Moving Average
--
-- ROWS counts observations, not calendar months.
-- Missing months can cause nonconsecutive periods
-- to be included in the same moving average.
-- ============================================================

SELECT
    trip_month,
    station_id,
    trip_count,

    ROUND(
        AVG(trip_count) OVER (
            PARTITION BY station_id
            ORDER BY trip_month
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ),
        2
    ) AS moving_avg_3rows

FROM
    `bigquery-analytics-study.bigquery_learning.vw_station_monthly_usage`

WHERE
    station_id = 519

ORDER BY
    trip_month;


-- ============================================================
-- 04. Consecutive Three-Month Moving Average
--
-- The result is NULL when the current month and
-- the previous two observed months are not consecutive.
-- ============================================================

WITH monthly_history AS (
    SELECT
        trip_month,
        station_id,
        trip_count,

        LAG(trip_month, 1) OVER (
            PARTITION BY station_id
            ORDER BY trip_month
        ) AS previous_month_1,

        LAG(trip_month, 2) OVER (
            PARTITION BY station_id
            ORDER BY trip_month
        ) AS previous_month_2,

        AVG(trip_count) OVER (
            PARTITION BY station_id
            ORDER BY trip_month
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ) AS moving_avg_3rows

    FROM
        `bigquery-analytics-study.bigquery_learning.vw_station_monthly_usage`

    WHERE
        station_id = 519
)

SELECT
    trip_month,
    station_id,
    trip_count,

    ROUND(
        moving_avg_3rows,
        2
    ) AS moving_avg_3rows,

    CASE
        WHEN previous_month_1 = DATE_SUB(
            trip_month,
            INTERVAL 1 MONTH
        )

        AND previous_month_2 = DATE_SUB(
            trip_month,
            INTERVAL 2 MONTH
        )

        THEN ROUND(
            moving_avg_3rows,
            2
        )

        ELSE NULL
    END AS moving_avg_3months

FROM
    monthly_history

ORDER BY
    trip_month;


-- ============================================================
-- 05. Station Usage Variability
--
-- Population standard deviation and coefficient
-- of variation across observed months.
--
-- Minimum observation threshold: 24 months.
-- This does not guarantee 24 consecutive months.
-- ============================================================

SELECT
    station_id,

    COUNT(*) AS observed_months,

    SUM(trip_count) AS total_trips,

    ROUND(
        AVG(trip_count),
        2
    ) AS avg_monthly_trips,

    ROUND(
        STDDEV_POP(trip_count),
        2
    ) AS stddev_monthly_trips,

    ROUND(
        SAFE_DIVIDE(
            STDDEV_POP(trip_count),
            AVG(trip_count)
        ) * 100,
        2
    ) AS coefficient_of_variation_pct

FROM
    `bigquery-analytics-study.bigquery_learning.vw_station_monthly_usage`

GROUP BY
    station_id

HAVING
    COUNT(*) >= 24

ORDER BY
    coefficient_of_variation_pct DESC,
    station_id

LIMIT 20;


-- ============================================================
-- 06. Monthly Top Five Stations Using QUALIFY
--
-- RANK assigns the same rank to tied values.
-- A top-five query may return more than five rows
-- if there are ties at rank five.
-- ============================================================

SELECT
    trip_month,
    station_id,
    trip_count,

    RANK() OVER (
        PARTITION BY trip_month
        ORDER BY trip_count DESC
    ) AS monthly_rank

FROM
    `bigquery-analytics-study.bigquery_learning.vw_station_monthly_usage`

WHERE
    trip_month = '2017-04-01'

QUALIFY
    monthly_rank <= 5

ORDER BY
    monthly_rank,
    station_id;


-- ============================================================
-- 07. Monthly Share and Aggregate Validation
--
-- Expected:
-- station_count       = 613
-- sum_station_trips   = 1315404
-- monthly_total_trips = 1315404
-- trip_difference     = 0
-- total_share_pct     = 100.0
--
-- Share values are summed before rounding.
-- ============================================================

WITH station_share AS (
    SELECT
        trip_month,
        station_id,
        trip_count,

        SUM(trip_count) OVER (
            PARTITION BY trip_month
        ) AS monthly_total_trips,

        SAFE_DIVIDE(
            trip_count,
            SUM(trip_count) OVER (
                PARTITION BY trip_month
            )
        ) * 100 AS station_share_pct

    FROM
        `bigquery-analytics-study.bigquery_learning.vw_station_monthly_usage`

    WHERE
        trip_month = '2017-04-01'
)

SELECT
    trip_month,

    COUNT(*) AS station_count,

    SUM(trip_count) AS sum_station_trips,

    MAX(monthly_total_trips) AS monthly_total_trips,

    SUM(trip_count)
        - MAX(monthly_total_trips) AS trip_difference,

    ROUND(
        SUM(station_share_pct),
        6
    ) AS total_share_pct

FROM
    station_share

GROUP BY
    trip_month;
