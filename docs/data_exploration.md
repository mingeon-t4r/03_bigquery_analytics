# Day 1 - BigQuery Data Exploration

## Dataset

NYC Citi Bike Trips

## Data Grain

1 Grain = Citi Bike 이용 1건(Trip)

테이블 1행은 한 번의 자전거 이용 여정을 의미한다.

## Key Columns

- starttime : 자전거 이용 시작 시간
- stoptime : 자전거 이용 종료 시간
- start_station_name : 출발 station 이름
- end_station_name : 도착 station 이름

## BigQuery Structure

bigquery-pulic-data
→ new_york_citibike
→ citibike_trips

## SQLite와 BigQuery의 차이

### SQLite

로컬 DB 파일을 기반으로 데이터를 조회한다.

### BigQuery

클라우드 데이터웨어하우스에서 데이터를 조회하며,
쿼리 실행 시 처리되는 데이터량을 고려해야 한다.

## Day 1 Findings

### Query 1

SELECT * 사용

처리 데이터량: 7.47GB

### Query 2

필요한 컬럼만 SELECT

처리 데이터량: 2.51GB

### 비교

Query 1은 모든 컬럼을 조회하여 7.47 GB를 처리했지만,
Query 2는 분석에 필요한 컬럼만 선택하여 2.51 GB를 처리했다.

동일한 테이블을 조회하더라도 필요한 컬럼만 SELECT하면
BigQuery가 읽어야 하는 데이터량을 줄일 수 있다는 것을 확인했다.

따라서 BigQuery에서는 습관적으로 SELECT *를 사용하는 것보다
분석에 필요한 컬럼을 명시적으로 선택하는 것이 중요하다.

## Questions

- LIMIT은 처리 데이터량을 줄이는가?
    아니다.

    LIMIT은 반환되는 결과의 행(row) 수를 제한하지만,
    이번 쿼리처럼 테이블에서 읽어야 하는 데이터 자체를
    LIMIT 숫자에 비례해서 줄여주는 것은 아니다.

    따라서 LIMIT 10을 사용하더라도
    쿼리 처리량이 단순히 10행만큼으로 감소하는 것은 아니다.

- 필요한 컬럼만 SELECT하면 왜 처리량이 감소하는가? 
    BigQuery는 컬럼 기반(Columnar)으로 데이터를 처리한다.

    따라서 SELECT *로 모든 컬럼을 조회하면
    많은 컬럼의 데이터를 읽어야 하지만,

    필요한 컬럼만 SELECT하면 해당 컬럼들만 읽을 수 있기 때문에
    처리해야 하는 데이터량을 줄일 수 있다.

    이번 실습에서도

    SELECT * : 7.47 GB

    필요한 컬럼만 SELECT : 2.51 GB

    로 처리 데이터량이 감소하는 것을 확인했다.

- 이 데이터의 grain은 무엇인가?
    Citi Bike 이용 1건(Trip)이다.

    즉, citibike_trips 테이블에서
    한 행(row)은 한 번의 자전거 이용 여정을 의미한다.