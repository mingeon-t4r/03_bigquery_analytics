-- ============================================
-- Project #3 BigQuery Analytics
-- Day 4 - Station Demand Analysis
-- ============================================


-- ============================================
-- 1. Overall Start Station Top 10
-- ============================================
-- 전체 기간에서 출발 Trip이 많은 Station 확인
-- Grain: 1 row = Start Station

SELECT
    start_station_id,
    start_station_name,
    COUNT(*) AS start_count

FROM
    `bigquery-public-data.new_york_citibike.citibike_trips`

WHERE
    starttime IS NOT NULL

GROUP BY
    start_station_id,
    start_station_name

ORDER BY
    start_count DESC

LIMIT 10;


-- ============================================
-- 2. Overall End Station Top 10
-- ============================================
-- 전체 기간에서 도착 Trip이 많은 Station 확인
-- Grain: 1 row = End Station

SELECT
    end_station_id,
    end_station_name,
    COUNT(*) AS end_count

FROM
    `bigquery-public-data.new_york_citibike.citibike_trips`

WHERE
    stoptime IS NOT NULL

GROUP BY
    end_station_id,
    end_station_name

ORDER BY
    end_count DESC

LIMIT 10;


-- ============================================
-- 3. Peak Hour Top 5 Start Stations
-- ============================================
-- Day 3에서 이용량이 높았던 08시, 17시, 18시를 대상으로
-- 각 시간별 출발 Trip이 많은 Station Top 5 확인
-- Grain: 1 row = Hour × Start Station

WITH station_hourly_count AS (

    SELECT
        EXTRACT(
            HOUR
            FROM starttime
        ) AS trip_hour,

        start_station_id,
        start_station_name,

        COUNT(*) AS trip_count

    FROM
        `bigquery-public-data.new_york_citibike.citibike_trips`

    WHERE
        starttime IS NOT NULL

        AND EXTRACT(
            HOUR
            FROM starttime
        ) IN (8, 17, 18)

    GROUP BY
        trip_hour,
        start_station_id,
        start_station_name
)

SELECT
    trip_hour,
    start_station_id,
    start_station_name,
    trip_count,

    ROW_NUMBER() OVER (
        PARTITION BY trip_hour
        ORDER BY trip_count DESC
    ) AS station_rank

FROM
    station_hourly_count

QUALIFY
    station_rank <= 5

ORDER BY
    trip_hour,
    station_rank;


-- ============================================
-- 4. Weekend Afternoon Top 5 Start Stations
-- ============================================
-- 주말(Sunday, Saturday) 12~17시 Trip을 모두 합산하여
-- 출발량이 많은 Station Top 5 확인
-- Grain: 1 row = Start Station

WITH weekend_afternoon_count AS (

    SELECT
        start_station_id,
        start_station_name,

        COUNT(*) AS trip_count

    FROM
        `bigquery-public-data.new_york_citibike.citibike_trips`

    WHERE
        starttime IS NOT NULL

        AND EXTRACT(
            DAYOFWEEK
            FROM starttime
        ) IN (1, 7)

        AND EXTRACT(
            HOUR
            FROM starttime
        ) BETWEEN 12 AND 17

    GROUP BY
        start_station_id,
        start_station_name
)

SELECT
    start_station_id,
    start_station_name,
    trip_count,

    ROW_NUMBER() OVER (
        ORDER BY trip_count DESC
    ) AS station_rank

FROM
    weekend_afternoon_count

QUALIFY
    station_rank <= 5

ORDER BY
    station_rank;


-- ============================================
-- 5. Compare Start / End Top 10 Stations
-- ============================================
-- 출발 Top 10과 도착 Top 10에 모두 포함된 Station을 비교
-- trip_difference = 출발 Trip - 도착 Trip
--
-- 양수: 출발 Trip이 더 많음
-- 음수: 도착 Trip이 더 많음
--
-- 주의:
-- 전체 Station을 대상으로 한 Net Flow 분석이 아니라
-- Start Top 10과 End Top 10의 공통 Station 비교임
-- Grain: 1 row = Station

WITH start_top_10 AS (

    SELECT
        start_station_id AS station_id,
        start_station_name AS station_name,

        COUNT(*) AS start_count

    FROM
        `bigquery-public-data.new_york_citibike.citibike_trips`

    WHERE
        starttime IS NOT NULL

    GROUP BY
        start_station_id,
        start_station_name

    ORDER BY
        start_count DESC

    LIMIT 10
),

end_top_10 AS (

    SELECT
        end_station_id AS station_id,
        end_station_name AS station_name,

        COUNT(*) AS end_count

    FROM
        `bigquery-public-data.new_york_citibike.citibike_trips`

    WHERE
        stoptime IS NOT NULL

    GROUP BY
        end_station_id,
        end_station_name

    ORDER BY
        end_count DESC

    LIMIT 10
)

SELECT
    s.station_id,
    s.station_name,
    s.start_count,
    e.end_count,

    s.start_count
        - e.end_count
        AS trip_difference

FROM
    start_top_10 s

INNER JOIN
    end_top_10 e

    ON s.station_id = e.station_id

ORDER BY
    trip_difference DESC;