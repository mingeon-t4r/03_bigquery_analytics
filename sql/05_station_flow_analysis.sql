-- ============================================
-- Project #3 BigQuery Analytics
-- Day 5 - Station Flow Analysis
-- ============================================


-- ============================================
-- 1. Station ID / Name Validation
-- ============================================

SELECT
    start_station_id AS station_id,

    COUNT(
        DISTINCT start_station_name
    ) AS station_name_count

FROM
    `bigquery-public-data.new_york_citibike.citibike_trips`

WHERE
    start_station_id IS NOT NULL

GROUP BY
    station_id

HAVING
    station_name_count > 1

ORDER BY
    station_id;


-- ============================================
-- 2. Overall Station Flow
-- ============================================

WITH start_station_count AS (

    SELECT
        start_station_id AS station_id,
        COUNT(*) AS start_count

    FROM
        `bigquery-public-data.new_york_citibike.citibike_trips`

    WHERE
        starttime IS NOT NULL
        AND start_station_id IS NOT NULL

    GROUP BY
        station_id
),

end_station_count AS (

    SELECT
        end_station_id AS station_id,
        COUNT(*) AS end_count

    FROM
        `bigquery-public-data.new_york_citibike.citibike_trips`

    WHERE
        stoptime IS NOT NULL
        AND end_station_id IS NOT NULL

    GROUP BY
        station_id
),

station_flow AS (

    SELECT
        COALESCE(
            s.station_id,
            e.station_id
        ) AS station_id,

        COALESCE(
            s.start_count,
            0
        ) AS start_count,

        COALESCE(
            e.end_count,
            0
        ) AS end_count,

        COALESCE(s.start_count, 0)
            - COALESCE(e.end_count, 0)
            AS net_departure

    FROM
        start_station_count s

    FULL OUTER JOIN
        end_station_count e

        ON s.station_id = e.station_id
)

SELECT
    station_id,
    start_count,
    end_count,
    net_departure

FROM
    station_flow

ORDER BY
    net_departure DESC,
    station_id

LIMIT 10;

-- Net Departure 하위 TOP 10은 위 쿼리의
-- ORDER BY를 net_departure ASC로 변경하여 실행한다.


-- ============================================
-- 3. Hourly Station Flow - Top 5
-- ============================================

WITH start_station_hourly AS (

    SELECT
        EXTRACT(
            HOUR
            FROM starttime
        ) AS trip_hour,

        start_station_id AS station_id,

        COUNT(*) AS start_count

    FROM
        `bigquery-public-data.new_york_citibike.citibike_trips`

    WHERE
        starttime IS NOT NULL
        AND start_station_id IS NOT NULL

    GROUP BY
        trip_hour,
        station_id
),

end_station_hourly AS (

    SELECT
        EXTRACT(
            HOUR
            FROM stoptime
        ) AS trip_hour,

        end_station_id AS station_id,

        COUNT(*) AS end_count

    FROM
        `bigquery-public-data.new_york_citibike.citibike_trips`

    WHERE
        stoptime IS NOT NULL
        AND end_station_id IS NOT NULL

    GROUP BY
        trip_hour,
        station_id
),

station_flow AS (

    SELECT
        COALESCE(
            s.trip_hour,
            e.trip_hour
        ) AS trip_hour,

        COALESCE(
            s.station_id,
            e.station_id
        ) AS station_id,

        COALESCE(
            s.start_count,
            0
        ) AS start_count,

        COALESCE(
            e.end_count,
            0
        ) AS end_count

    FROM
        start_station_hourly s

    FULL OUTER JOIN
        end_station_hourly e

        ON s.station_id = e.station_id
        AND s.trip_hour = e.trip_hour
)

SELECT
    trip_hour,
    station_id,
    start_count,
    end_count,

    start_count - end_count AS net_departure,

    ROW_NUMBER() OVER (
        PARTITION BY trip_hour
        ORDER BY
            start_count - end_count DESC,
            station_id
    ) AS station_rank

FROM
    station_flow

WHERE
    trip_hour IN (8, 17, 18)
    AND station_id IS NOT NULL

QUALIFY
    station_rank <= 5

ORDER BY
    trip_hour,
    station_rank;


-- ============================================
-- 4. Overall Station Flow Validation
-- ============================================

WITH start_station_count AS (

    SELECT
        start_station_id AS station_id,
        COUNT(*) AS start_count

    FROM
        `bigquery-public-data.new_york_citibike.citibike_trips`

    WHERE
        starttime IS NOT NULL
        AND start_station_id IS NOT NULL

    GROUP BY
        station_id
),

end_station_count AS (

    SELECT
        end_station_id AS station_id,
        COUNT(*) AS end_count

    FROM
        `bigquery-public-data.new_york_citibike.citibike_trips`

    WHERE
        stoptime IS NOT NULL
        AND end_station_id IS NOT NULL

    GROUP BY
        station_id
),

station_flow AS (

    SELECT
        COALESCE(
            s.station_id,
            e.station_id
        ) AS station_id,

        COALESCE(
            s.start_count,
            0