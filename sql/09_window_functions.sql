-- ============================================
-- Project #3 - BigQuery Analytics
-- Day 9 - Window Functions
--
-- Source:
-- bigquery-analytics-study.bigquery_learning.vw_station_monthly_usage
--
-- Grain:
-- Month x Start Station
--
-- Source Rows: 24,876
-- Source Months: 53
-- Source Stations: 881
--
-- Topics:
-- ROW_NUMBER, RANK, DENSE_RANK
-- LAG, LEAD
-- Monthly growth analysis
-- Missing-month validation
-- Independent reconciliation
-- ============================================


-- ============================================
-- 0. Diagnose Available Months
-- ============================================

-- Initial ranking query returned no rows
-- for 2017-01-01.
--
-- Available months were checked.
-- 2017-04-01 was selected for ranking exercises.

SELECT
    trip_month,
    COUNT(*) AS station_count,
    SUM(trip_count) AS total_trips

FROM
    `bigquery-analytics-study.bigquery_learning.vw_station_monthly_usage`

GROUP BY
    trip_month

ORDER BY
    trip_month DESC

LIMIT 15;


-- ============================================
-- 1. Monthly Station Ranking
-- ============================================

-- Month: 2017-04-01
-- Station count: 613
-- Total trips: 1,315,404
--
-- Top station:
-- station_id = 519
-- trip_count = 12,408
-- monthly_rank = 1

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

ORDER BY
    monthly_rank,
    station_id

LIMIT 20;


-- ============================================
-- 2. Compare Three Ranking Functions
-- ============================================

-- ROW_NUMBER:
-- Assigns a unique sequential number.
--
-- RANK:
-- Assigns tied ranks and skips positions.
--
-- DENSE_RANK:
-- Assigns tied ranks without skipping positions.
--
-- station_id is used as a tie-breaker
-- only for ROW_NUMBER.
--
-- Adding station_id to RANK or DENSE_RANK
-- would remove ties between different stations.

SELECT
    trip_month,
    station_id,
    trip_count,

    ROW_NUMBER() OVER (
        PARTITION BY trip_month
        ORDER BY
            trip_count DESC,
            station_id
    ) AS row_num,

    RANK() OVER (
        PARTITION BY trip_month
        ORDER BY trip_count DESC
    ) AS rank_num,

    DENSE_RANK() OVER (
        PARTITION BY trip_month
        ORDER BY trip_count DESC
    ) AS dense_rank_num

FROM
    `bigquery-analytics-study.bigquery_learning.vw_station_monthly_usage`

WHERE
    trip_month = '2017-04-01'

ORDER BY
    trip_count DESC,
    station_id

LIMIT 20;


-- ============================================
-- 3. Find Tied Station Counts
-- ============================================

-- Observed examples:
-- trip_count = 5,224: 2 stations
-- trip_count = 3,484: 2 stations
-- trip_count = 3,449: 2 stations
-- trip_count = 3,039: 2 stations

SELECT
    trip_month,
    trip_count,
    COUNT(*) AS tied_stations

FROM
    `bigquery-analytics-study.bigquery_learning.vw_station_monthly_usage`

WHERE
    trip_month = '2017-04-01'

GROUP BY
    trip_month,
    trip_count

HAVING
    COUNT(*) > 1

ORDER BY
    trip_count DESC

LIMIT 10;


-- ============================================
-- 4. Validate Ranking on Actual Ties
-- ============================================

-- Rankings are calculated before filtering.
--
-- Observed:
-- station_id 327:
-- row_num = 40
-- rank_num = 40
-- dense_rank_num = 40
--
-- station_id 3435:
-- row_num = 41
-- rank_num = 40
-- dense_rank_num = 40

WITH station_ranking AS (
    SELECT
        trip_month,
        station_id,
        trip_count,

        ROW_NUMBER() OVER (
            PARTITION BY trip_month
            ORDER BY
                trip_count DESC,
                station_id
        ) AS row_num,

        RANK() OVER (
            PARTITION BY trip_month
            ORDER BY trip_count DESC
        ) AS rank_num,

        DENSE_RANK() OVER (
            PARTITION BY trip_month
            ORDER BY trip_count DESC
        ) AS dense_rank_num

    FROM
        `bigquery-analytics-study.bigquery_learning.vw_station_monthly_usage`

    WHERE
        trip_month = '2017-04-01'
)

SELECT
    trip_month,
    station_id,
    trip_count,
    row_num,
    rank_num,
    dense_rank_num

FROM
    station_ranking

WHERE
    trip_count = 5224

ORDER BY
    row_num;


-- ============================================
-- 5. Validate Rank Gaps
-- ============================================

-- Observed:
-- row_num 40: rank 40, dense rank 40
-- row_num 41: rank 40, dense rank 40
-- row_num 42: rank 42, dense rank 41
--
-- RANK skips rank 41 after a tie.
-- DENSE_RANK does not skip rank 41.

WITH station_ranking AS (
    SELECT
        trip_month,
        station_id,
        trip_count,

        ROW_NUMBER() OVER (
            PARTITION BY trip_month
            ORDER BY
                trip_count DESC,
                station_id
        ) AS row_num,

        RANK() OVER (
            PARTITION BY trip_month
            ORDER BY trip_count DESC
        ) AS rank_num,

        DENSE_RANK() OVER (
            PARTITION BY trip_month
            ORDER BY trip_count DESC
        ) AS dense_rank_num

    FROM
        `bigquery-analytics-study.bigquery_learning.vw_station_monthly_usage`

    WHERE
        trip_month = '2017-04-01'
)

SELECT
    trip_month,
    station_id,
    trip_count,
    row_num,
    rank_num,
    dense_rank_num

FROM
    station_ranking

WHERE
    row_num BETWEEN 38 AND 45

ORDER BY
    row_num;


-- ============================================
-- 6. LAG - Previous Observation
-- ============================================

-- Station: 519
--
-- LAG returns the previous row,
-- not necessarily the previous calendar month.

SELECT
    trip_month,
    station_id,
    trip_count,

    LAG(trip_count) OVER (
        PARTITION BY station_id
        ORDER BY trip_month
    ) AS previous_trip_count

FROM
    `bigquery-analytics-study.bigquery_learning.vw_station_monthly_usage`

WHERE
    station_id = 519

ORDER BY
    trip_month

LIMIT 20;


-- ============================================
-- 7. Month-over-Month Change
-- ============================================

-- Compare only consecutive calendar months.
--
-- DATE_SUB validates month continuity.
-- SAFE_DIVIDE handles zero denominators.
--
-- Observed:
-- 2013-08: +2,431 / +33.35%
-- 2013-11: -3,934 / -35.22%
-- 2014-03: +2,489 / +91.54%

WITH monthly_comparison AS (
    SELECT
        trip_month,
        station_id,
        trip_count,

        LAG(trip_month) OVER (
            PARTITION BY station_id
            ORDER BY trip_month
        ) AS previous_month,

        LAG(trip_count) OVER (
            PARTITION BY station_id
            ORDER BY trip_month
        ) AS previous_trip_count

    FROM
        `bigquery-analytics-study.bigquery_learning.vw_station_monthly_usage`

    WHERE
        station_id = 519
)

SELECT
    trip_month,
    station_id,
    trip_count,
    previous_month,
    previous_trip_count,

    CASE
        WHEN previous_month = DATE_SUB(
            trip_month,
            INTERVAL 1 MONTH
        )
        THEN trip_count - previous_trip_count
        ELSE NULL
    END AS trip_difference,

    CASE
        WHEN previous_month = DATE_SUB(
            trip_month,
            INTERVAL 1 MONTH
        )
        THEN ROUND(
            SAFE_DIVIDE(
                trip_count - previous_trip_count,
                previous_trip_count
            ) * 100,
            2
        )
        ELSE NULL
    END AS growth_rate_pct

FROM
    monthly_comparison

ORDER BY
    trip_month

LIMIT 20;


-- ============================================
-- 8. Detect Missing Calendar Months
-- ============================================

-- Observed for station 519:
--
-- previous_month = 2016-09-01
-- trip_month = 2017-04-01
-- month_gap = 7
--
-- Missing observations:
-- 2016-10 through 2017-03 (6 months)

WITH monthly_history AS (
    SELECT
        trip_month,
        station_id,
        trip_count,

        LAG(trip_month) OVER (
            PARTITION BY station_id
            ORDER BY trip_month
        ) AS previous_month,

        LAG(trip_count) OVER (
            PARTITION BY station_id
            ORDER BY trip_month
        ) AS previous_trip_count

    FROM
        `bigquery-analytics-study.bigquery_learning.vw_station_monthly_usage`

    WHERE
        station_id = 519
)

SELECT
    trip_month,
    station_id,
    trip_count,
    previous_month,
    previous_trip_count,

    DATE_DIFF(
        trip_month,
        previous_month,
        MONTH
    ) AS month_gap

FROM
    monthly_history

WHERE
    previous_month IS NOT NULL

    AND DATE_DIFF(
        trip_month,
        previous_month,
        MONTH
    ) > 1

ORDER BY
    trip_month;


-- ============================================
-- 9. Compare LAG and LEAD
-- ============================================

-- LAG: previous observation
-- LEAD: next observation
--
-- Both operate on rows, not calendar intervals.

SELECT
    trip_month,
    station_id,
    trip_count,

    LAG(trip_count) OVER (
        PARTITION BY station_id
        ORDER BY trip_month
    ) AS previous_trip_count,

    LEAD(trip_count) OVER (
        PARTITION BY station_id
        ORDER BY trip_month
    ) AS next_trip_count,

    LAG(trip_month) OVER (
        PARTITION BY station_id
        ORDER BY trip_month
    ) AS previous_month,

    LEAD(trip_month) OVER (
        PARTITION BY station_id
        ORDER BY trip_month
    ) AS next_month

FROM
    `bigquery-analytics-study.bigquery_learning.vw_station_monthly_usage`

WHERE
    station_id = 519

ORDER BY
    trip_month;


-- ============================================
-- 10. Classify Monthly Trends
-- ============================================

-- increase: current count > previous count
-- decrease: current count < previous count
-- stable: current count = previous count
-- no_comparison: no valid previous calendar month
--
-- 2017-04 is no_comparison due to missing months.

WITH monthly_history AS (
    SELECT
        trip_month,
        station_id,
        trip_count,

        LAG(trip_month) OVER (
            PARTITION BY station_id
            ORDER BY trip_month
        ) AS previous_month,

        LAG(trip_count) OVER (
            PARTITION BY station_id
            ORDER BY trip_month
        ) AS previous_trip_count,

        LEAD(trip_month) OVER (
            PARTITION BY station_id
            ORDER BY trip_month
        ) AS next_month,

        LEAD(trip_count) OVER (
            PARTITION BY station_id
            ORDER BY trip_month
        ) AS next_trip_count

    FROM
        `bigquery-analytics-study.bigquery_learning.vw_station_monthly_usage`

    WHERE
        station_id = 519
)

SELECT
    trip_month,
    station_id,
    trip_count,
    previous_trip_count,
    next_trip_count,

    CASE
        WHEN previous_month IS NULL
            THEN 'no_comparison'

        WHEN DATE_DIFF(
            trip_month,
            previous_month,
            MONTH
        ) != 1
            THEN 'no_comparison'

        WHEN trip_count > previous_trip_count
            THEN 'increase'

        WHEN trip_count < previous_trip_count
            THEN 'decrease'

        ELSE 'stable'
    END AS monthly_trend

FROM
    monthly_history

ORDER BY
    trip_month;


-- ============================================
-- 11. Count Monthly Trend Types
-- ============================================

-- Observed for station 519:
-- increase = 30
-- decrease = 21
-- no_comparison = 2
-- stable = 0
--
-- Total observations = 53
-- Valid comparisons = 51

WITH monthly_history AS (
    SELECT
        trip_month,
        station_id,
        trip_count,

        LAG(trip_month) OVER (
            PARTITION BY station_id
            ORDER BY trip_month
        ) AS previous_month,

        LAG(trip_count) OVER (
            PARTITION BY station_id
            ORDER BY trip_month
        ) AS previous_trip_count

    FROM
        `bigquery-analytics-study.bigquery_learning.vw_station_monthly_usage`

    WHERE
        station_id = 519
),

monthly_trend_analysis AS (
    SELECT
        trip_month,
        station_id,
        trip_count,

        CASE
            WHEN previous_month IS NULL
                THEN 'no_comparison'

            WHEN DATE_DIFF(
                trip_month,
                previous_month,
                MONTH
            ) != 1
                THEN 'no_comparison'

            WHEN trip_count > previous_trip_count
                THEN 'increase'

            WHEN trip_count < previous_trip_count
                THEN 'decrease'

            ELSE 'stable'
        END AS monthly_trend

    FROM
        monthly_history
)

SELECT
    monthly_trend,
    COUNT(*) AS month_count

FROM
    monthly_trend_analysis

GROUP BY
    monthly_trend

ORDER BY
    month_count DESC;


-- ============================================
-- 12. Analyze Magnitude of Monthly Changes
-- ============================================

-- Observed for station 519:
-- increase_months = 30
-- decrease_months = 21
-- total_increase = 53,061
-- total_decrease = -39,474
-- net_change = 13,587
--
-- net_change excludes nonconsecutive comparisons.
-- It is not the full-period endpoint difference.

WITH monthly_history AS (
    SELECT
        trip_month,
        station_id,
        trip_count,

        LAG(trip_month) OVER (
            PARTITION BY station_id
            ORDER BY trip_month
        ) AS previous_month,

        LAG(trip_count) OVER (
            PARTITION BY station_id
            ORDER BY trip_month
        ) AS previous_trip_count

    FROM
        `bigquery-analytics-study.bigquery_learning.vw_station_monthly_usage`

    WHERE
        station_id = 519
),

monthly_changes AS (
    SELECT
        trip_month,
        station_id,
        trip_count,

        CASE
            WHEN previous_month = DATE_SUB(
                trip_month,
                INTERVAL 1 MONTH
            )
            THEN trip_count - previous_trip_count
            ELSE NULL
        END AS trip_difference

    FROM
        monthly_history
)

SELECT
    COUNTIF(
        trip_difference > 0
    ) AS increase_months,

    COUNTIF(
        trip_difference < 0
    ) AS decrease_months,

    SUM(
        CASE
            WHEN trip_difference > 0
            THEN trip_difference
            ELSE 0
        END
    ) AS total_increase,

    SUM(
        CASE
            WHEN trip_difference < 0
            THEN trip_difference
            ELSE 0
        END
    ) AS total_decrease,

    SUM(trip_difference) AS net_change

FROM
    monthly_changes;


-- ============================================
-- 13. Independent Net Change Reconciliation
-- ============================================

-- Divide the history into consecutive-month periods.
--
-- Period 1:
-- 2013-07 to 2016-09
-- 16,556 - 7,290 = 9,266
--
-- Period 2:
-- 2017-04 to 2018-05
-- 16,729 - 12,408 = 4,321
--
-- Reconciliation:
-- 9,266 + 4,321 = 13,587
--
-- Matches the net_change from Exercise 12.

WITH monthly_history AS (
    SELECT
        trip_month,
        station_id,
        trip_count,

        LAG(trip_month) OVER (
            PARTITION BY station_id
            ORDER BY trip_month
        ) AS previous_month

    FROM
        `bigquery-analytics-study.bigquery_learning.vw_station_monthly_usage`

    WHERE
        station_id = 519
),

monthly_groups AS (
    SELECT
        trip_month,
        station_id,
        trip_count,

        SUM(
            CASE
                WHEN previous_month IS NULL
                    THEN 1

                WHEN DATE_DIFF(
                    trip_month,
                    previous_month,
                    MONTH
                ) > 1
                    THEN 1

                ELSE 0
            END
        ) OVER (
            PARTITION BY station_id
            ORDER BY trip_month
        ) AS period_group

    FROM
        monthly_history
),

period_boundaries AS (
    SELECT
        period_group,

        MIN(trip_month) AS start_month,
        MAX(trip_month) AS end_month,

        ARRAY_AGG(
            trip_count
            ORDER BY trip_month
            LIMIT 1
        )[OFFSET(0)] AS start_trips,

        ARRAY_AGG(
            trip_count
            ORDER BY trip_month DESC
            LIMIT 1
        )[OFFSET(0)] AS end_trips

    FROM
        monthly_groups

    GROUP BY
        period_group
)

SELECT
    period_group,
    start_month,
    end_month,
    start_trips,
    end_trips,

    end_trips - start_trips AS period_change

FROM
    period_boundaries

ORDER BY
    period_group;