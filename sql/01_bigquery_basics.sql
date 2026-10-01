-- ============================================
-- Project #3 BigQuery Analytics
-- Day 1 - BigQuery Basics
-- ============================================


-- 1. Sample rows

SELECT
    *
FROM
    `bigquery-public-data.new_york_citibike.citibike_trips`
LIMIT 10;


-- 2. Selected columns

SELECT
	starttime,
	start_station_name,
	end_station_name,
FROM
	`bigquery-public-data.new_york_citibike.citibike_trips`
LIMIT 10;

-- 3. Top 10 start stations

SELECT
	start_station_name,
	count(*) AS trip_count
FROM
	`bigquery-public-data.new_york_citibike.citibike_trips`
GROUP BY
	start_station_name
ORDER BY
	trip_count DESC
LIMIT 10;