# Day 10 — BigQuery Advanced Analytics

## 1. Analysis Overview

### Objective

BigQuery의 Window Function과 통계 집계 함수를 활용하여 NYC Citi Bike Station별 이용 점유율, 평균 이용량, 이동평균 및 변동성을 분석한다.
월별 관측 공백이 이동평균에 미치는 영향을 검증하고, 분석 지표의 집계 일관성을 확인한다.

### Data Source

- Project: `bigquery-analytics-study`
- Dataset: `bigquery_learning`
- Source View: `vw_station_monthly_usage`
- Data Grain: `trip_month × station_id`
- Main Analysis Month: `2017-04-01`
- Time-Series Analysis Station: `519`

## 2. Monthly Station Usage Share

### Method

`SUM(trip_count) OVER (PARTITION BY trip_month)`를 사용하여 월별 전체 출발량을 계산했다.
각 Station의 출발량을 해당 월 전체 출발량으로 나누어 점유율을 산출했다.
0으로 나누는 오류를 방지하기 위해 `SAFE_DIVIDE()`를 사용했다.

### Results

2017년 4월 전체 출발량은 1,315,404건이며, 분석 대상 Station은 613개다.

| Rank | Station ID | Trip Count | Share |
|---|---|---:|---:|
| 1 | 519 | 12,408 | 0.94% |
| 2 | 497 | 9,716 | 0.74% |
| 3 | 2006 | 9,194 | 0.70% |
| 4 | 426 | 9,180 | 0.70% |
| 5 | 402 | 8,935 | 0.68% |

### Interpretation

Station 519는 2017년 4월에 가장 많은 출발량을 기록했지만, 전체 출발량에서 차지하는 비중은 약 0.94%였다.
월별 점유율은 단순 출발량과 달리 전체 이용 규모를 고려하여 Station 간 상대적 기여도를 비교할 수 있는 지표다.

## 3. Station Average Monthly Usage

### Method

`AVG(trip_count) OVER (PARTITION BY station_id)`를 사용하여 Station별 관측 월평균 출발량을 계산했다.
각 월의 출발량에서 월평균 출발량을 차감하여 평균 대비 차이를 산출했다.

### Results

Station 519의 관측 기록은 53개월이며, 월평균 출발량은 10,397.70건이다.

| Month | Trip Count | Difference from Average |
|---|---:|---:|
| 2013-07 | 7,290 | -3,107.70 |
| 2013-10 | 11,169 | +771.30 |
| 2014-02 | 2,719 | -7,678.70 |
| 2015-09 | 14,063 | +3,665.30 |

### Interpretation

Station 519의 월별 출발량은 전체 관측 월평균보다 높거나 낮은 시기가 반복적으로 나타났다.
월평균 대비 차이만으로 비정상적인 운영 상태를 판단할 수는 없다.
계절성이나 운영 환경 변화를 추가로 분석해야 한다.

## 4. Three-Row Moving Average

### Method

`AVG() OVER (ORDER BY trip_month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW)`를 사용하여 현재 행을 포함한 최근 3개 관측값의 평균을 계산했다.

### Results

| Month | Trip Count | Moving Average |
|---|---:|---:|
| 2013-07 | 7,290 | 7,290.00 |
| 2013-08 | 9,721 | 8,505.50 |
| 2013-09 | 10,288 | 9,099.67 |
| 2013-10 | 11,169 | 10,392.67 |
| 2013-11 | 7,235 | 9,564.00 |

### Interpretation

이동평균은 월별 출발량의 단기적인 변동을 완화하여 추세를 파악하는 데 도움을 준다.
그러나 `ROWS BETWEEN`은 달력상 개월 수가 아닌 행 개수를 기준으로 계산한다.
따라서 관측 월이 누락된 경우 최근 3개 관측값의 평균과 연속 3개월 평균은 달라질 수 있다.

## 5. Consecutive Three-Month Moving Average

### Method

`LAG(trip_month, 1)`과 `LAG(trip_month, 2)`를 사용하여 이전 두 관측 월을 조회했다.
`DATE_SUB()`로 이전 관측 월이 실제로 1개월 전과 2개월 전인지 검증했다.
연속된 3개월의 기록이 존재하는 경우에만 이동평균을 반환하고, 그렇지 않은 경우에는 `NULL`을 반환했다.

### Results

| Month | Three-Row Average | Consecutive Three-Month Average |
|---|---:|---:|
| 2013-07 | 7,290.00 | NULL |
| 2013-08 | 8,505.50 | NULL |
| 2013-09 | 9,099.67 | 9,099.67 |
| 2017-04 | 15,116.33 | NULL |
| 2017-05 | 14,830.00 | NULL |
| 2017-06 | 14,766.00 | 14,766.00 |

### Interpretation

Station 519의 데이터에는 2016년 10월부터 2017년 3월까지 관측 공백이 존재한다.
2017년 4월과 5월은 연속 3개월 조건을 충족하지 못하므로 이동평균을 계산하지 않았다.
2017년 6월부터는 4월, 5월, 6월의 데이터가 연속적으로 존재하므로 이동평균을 계산할 수 있었다.
`NULL`은 출발량이 0이라는 뜻이 아니라 계산에 필요한 연속 관측 기록이 부족하다는 의미다.

## 6. Station Usage Variability

### Method

`STDDEV_POP()`를 사용하여 Station별 월간 출발량의 모집단 표준편차를 계산했다.
표준편차를 평균으로 나눈 변동계수(CV)를 활용하여 이용량 규모가 다른 Station의 상대적 변동성을 비교했다.
관측 월이 24개월 이상인 Station만 분석 대상으로 선정했다.

### Results

| Rank | Station ID | Observed Months | Average Trips | Standard Deviation | CV |
|---|---|---:|---:|---:|---:|
| 1 | 279 | 53 | 2,058.25 | 1,493.14 | 72.54% |
| 2 | 321 | 50 | 1,079.88 | 761.11 | 70.48% |
| 3 | 460 | 53 | 1,400.96 | 977.58 | 69.78% |
| 4 | 3180 | 29 | 939.21 | 632.96 | 67.39% |
| 5 | 217 | 53 | 1,839.94 | 1,238.75 | 67.33% |

### Interpretation

Station 279는 분석 대상 중 가장 높은 변동계수인 72.54%를 기록했다.
이는 월별 출발량의 표준편차가 평균 대비 크다는 의미다.
다만 변동계수가 높다는 사실만으로 운영상의 문제를 확정할 수는 없다.
계절성, Station 운영 기간, 지역 특성 등을 함께 고려해야 한다.
24개월 이상 관측됐다는 조건은 연속된 24개월의 기록을 보장하지 않는다.

## 7. Monthly Top Stations Using QUALIFY

### Method

`RANK()`로 2017년 4월 Station별 출발량 순위를 계산했다.
`QUALIFY monthly_rank <= 5`를 사용하여 상위 5위 이내의 Station을 선정했다.

### Results

| Rank | Station ID | Trip Count |
|---|---|---:|
| 1 | 519 | 12,408 |
| 2 | 497 | 9,716 |
| 3 | 2006 | 9,194 |
| 4 | 426 | 9,180 |
| 5 | 402 | 8,935 |

### Interpretation

`QUALIFY`를 사용하면 Window Function의 결과를 별도 CTE 없이 필터링할 수 있다.
`RANK()`는 동점에 같은 순위를 부여하므로, 공동 5위가 존재하는 경우 결과 행 수가 5개를 초과할 수 있다.

## 8. Validation

### Validation Method

2017년 4월의 Station별 출발량 합계와 Window Function으로 계산한 월 전체 출발량을 비교했다.
반올림하지 않은 Station별 점유율을 합산하여 전체 점유율이 100%인지 검증했다.

### Validation Results

| Metric | Actual Result | Status |
|---|---:|---|
| Station Count | 613 | PASS |
| Sum of Station Trips | 1,315,404 | PASS |
| Monthly Total Trips | 1,315,404 | PASS |
| Trip Difference | 0 | PASS |
| Total Share | 100.0% | PASS |

### Interpretation

Station별 출발량 합계와 월 전체 출발량이 일치했다.
출발량 차이는 0건이며, 전체 점유율 합계도 100%로 검증됐다.
다만 동일한 View에서 계산한 지표끼리 비교한 검산이므로, 원천 데이터 자체의 누락이나 중복 여부까지 독립적으로 검증한 것은 아니다.

## 9. Key Findings

- Window Function은 원래 행을 유지하면서 전체 합계와 평균을 계산할 수 있다.
- Station 점유율은 월 전체 출발량을 고려한 상대적 이용 지표다.
- 이동평균 계산에서는 행의 연속성과 날짜의 연속성을 구분해야 한다.
- 관측 공백이 존재하면 연속 3개월 이동평균을 별도로 검증해야 한다.
- 표준편차와 변동계수는 이용량의 절대적·상대적 변동성을 구분하는 데 활용할 수 있다.
- `QUALIFY`는 Window Function 결과를 간결하게 필터링하는 데 유용하다.
- 분석 결과는 출발량 합계와 점유율 합계를 통해 검산해야 한다.

## 10. Limitations

이번 분석은 2013년부터 2018년까지의 과거 Citi Bike 데이터를 사용했다.
Station별 관측 기간이 서로 다르며, 일부 기간에는 데이터 공백이 존재한다.
이동평균과 변동계수는 계절성을 제거하지 않은 지표다.
따라서 분석 결과를 현재 운영 상황이나 실제 수요 예측에 직접 적용하기 위해서는 추가적인 데이터 검증과 모델링이 필요하다.

## 11. Deliverables

- `sql/10_advanced_analytics.sql`
- `docs/advanced_analytics.md`

**Status:** Day 10 SQL 실습 및 검산 완료.