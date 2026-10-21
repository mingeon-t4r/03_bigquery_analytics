# Day 9 — BigQuery Window Function Analysis

## 1. Objective

BigQuery Window Function을 활용하여 Station별 월간 이용량 순위를 계산하고, 월별 출발량 변화와 데이터 누락 구간을 분석한다.

`ROW_NUMBER()`, `RANK()`, `DENSE_RANK()`의 동점 처리 방식을 실제 데이터로 비교한다.

`LAG()`와 `LEAD()`를 활용하여 이전 및 다음 관측값을 조회하고, 연속된 월에 대해서만 전월 대비 증감량과 증감률을 계산한다.

마지막으로 서로 다른 계산 방법을 이용하여 분석 결과의 정확성을 검증한다.

## 2. Data Source

- BigQuery Project: `bigquery-analytics-study`
- Dataset: `bigquery_learning`
- Source View: `vw_station_monthly_usage`
- Grain: Month × Start Station
- Source Rows: 24,876
- Source Months: 53
- Source Stations: 881
- Source Trips: 53,108,721

Day 8에서 생성한 Standard View를 Day 9의 분석 데이터 소스로 사용하였다.

## 3. Monthly Station Ranking

### 3.1 Analysis Scope

2017년 1월을 기준으로 순위 분석을 시도했으나 해당 월의 데이터가 없어 결과가 반환되지 않았다.

월별 데이터 존재 여부를 확인한 후 2017년 4월을 분석 기준으로 변경하였다.

2017년 4월에는 613개 Station에서 총 1,315,404건의 출발 기록이 집계되어 있었다.

### 3.2 Top 5 Stations

| Rank | Station ID | Monthly Trips |
|---:|---:|---:|
| 1 | 519 | 12,408 |
| 2 | 497 | 9,716 |
| 3 | 2006 | 9,194 |
| 4 | 426 | 9,180 |
| 5 | 402 | 8,935 |

Station 519는 2017년 4월 기준 출발 횟수가 가장 많은 Station이었다.

이 결과는 해당 월의 출발 수요 규모를 나타내며, Station의 운영 효율이나 실제 자전거 재고 상태를 직접 의미하지 않는다.

## 4. Ranking Function Comparison

### 4.1 Function Differences

`ROW_NUMBER()`는 정렬된 각 행에 서로 다른 번호를 부여한다.

`RANK()`는 동점에 동일한 순위를 부여하고, 다음 순위에서 동점 수만큼 순위를 건너뛴다.

`DENSE_RANK()`는 동점에 동일한 순위를 부여하지만 다음 순위를 건너뛰지 않는다.

`ROW_NUMBER()`에는 `station_id`를 추가 정렬 기준으로 사용하여 동일한 출발 횟수에 대해 결정적인 행 순서를 만들었다.

`RANK()`와 `DENSE_RANK()`에는 `station_id`를 추가하지 않아 동일한 출발 횟수가 공동 순위로 처리되도록 하였다.

### 4.2 Actual Tie Validation

2017년 4월에는 출발 횟수가 5,224회인 Station이 두 개 존재했다.

| Station ID | Trips | ROW_NUMBER | RANK | DENSE_RANK |
|---:|---:|---:|---:|---:|
| 327 | 5,224 | 40 | 40 | 40 |
| 3435 | 5,224 | 41 | 40 | 40 |
| 446 | 5,218 | 42 | 42 | 41 |

Station 327과 3435는 출발 횟수가 같으므로 `RANK()`와 `DENSE_RANK()`에서 공동 40위를 받았다.

그다음 Station 446은 `RANK()`에서 42위, `DENSE_RANK()`에서 41위를 받았다.

이를 통해 세 함수의 동점 처리 차이를 실제 데이터로 검증하였다.

### 4.3 Business Interpretation

정확히 N개의 Station을 선정해야 하는 경우에는 `ROW_NUMBER()`를 사용할 수 있다.

동점 Station에 동일한 순위를 부여해야 하는 경우에는 `RANK()` 또는 `DENSE_RANK()`를 사용할 수 있다.

동점자를 모두 포함하는 상위 순위 선정에서는 최종 반환 행 수가 N개보다 많아질 수 있으므로 업무 규칙을 먼저 정의해야 한다.

## 5. Previous and Next Observation Analysis

Station 519를 대상으로 `LAG()`와 `LEAD()`를 적용하였다.

`LAG()`는 현재 행의 이전 관측값을 반환한다.

`LEAD()`는 현재 행의 다음 관측값을 반환한다.

두 함수는 달력상 이전 달이나 다음 달이 아니라 Window Function의 정렬 기준에 따른 이전 행과 다음 행을 반환한다.

따라서 월별 기록에 공백이 있는 경우에는 날짜 연속성을 별도로 확인해야 한다.

## 6. Month-over-Month Growth Analysis

연속된 월인지 확인한 후 다음 지표를 계산하였다.

- `trip_difference`: 현재 월 출발 횟수 - 이전 월 출발 횟수
- `growth_rate_pct`: 전월 대비 증감률(%)
- `previous_month`: 이전 관측 월
- `previous_trip_count`: 이전 관측 월의 출발 횟수

`DATE_SUB()`를 사용하여 이전 관측 월이 실제 전월인지 확인하였다.

`SAFE_DIVIDE()`를 사용하여 분모가 0인 상황에서 쿼리 오류가 발생하지 않도록 처리하였다.

### 6.1 Selected Results

| Month | Trips | Difference | Growth Rate |
|---|---:|---:|---:|
| 2013-08 | 9,721 | +2,431 | +33.35% |
| 2013-11 | 7,235 | -3,934 | -35.22% |
| 2014-03 | 5,208 | +2,489 | +91.54% |
| 2014-11 | 5,779 | -3,685 | -38.94% |

2014년 3월에는 전월 대비 출발 횟수가 91.54% 증가하였다.

그러나 증감률이 높다는 사실만으로 장기적인 이용량 증가나 운영 개선을 단정할 수는 없다.

월별 이용량은 계절, 날씨, 서비스 운영 상황 등 다양한 요인의 영향을 받을 수 있으며, 해당 요인들은 이번 분석에서 직접 검증하지 않았다.

## 7. Missing-Month Detection

### 7.1 Observed Data Gap

Station 519에서 다음 데이터 공백을 확인하였다.

| Item | Value |
|---|---|
| Previous Month | 2016-09-01 |
| Current Month | 2017-04-01 |
| Month Gap | 7 |
| Missing Months | 6 |
| Previous Trips | 16,556 |
| Current Trips | 12,408 |

2016년 10월부터 2017년 3월까지 6개월의 월별 관측 기록이 존재하지 않았다.

2016년 9월과 2017년 4월의 출발량을 직접 비교하면 약 -25.05%의 변화율이 계산된다.

그러나 두 관측값은 7개월 간격이므로 이 값을 전월 대비 감소율로 해석해서는 안 된다.

따라서 해당 구간을 `no_comparison`으로 분류하였다.

이 공백은 분석 대상 View에서 관측된 데이터 누락이며, 실제 자전거 이용이 없었다는 사실을 의미하지는 않는다.

## 8. Monthly Trend Classification

연속된 월끼리 비교한 결과를 다음과 같이 분류하였다.

- `increase`: 전월보다 출발 횟수가 증가한 경우
- `decrease`: 전월보다 출발 횟수가 감소한 경우
- `stable`: 전월과 출발 횟수가 같은 경우
- `no_comparison`: 이전 관측값이 없거나 월이 연속되지 않는 경우

### 8.1 Actual Results

| Trend | Months |
|---|---:|
| increase | 30 |
| decrease | 21 |
| no_comparison | 2 |
| stable | 0 |
| Total | 53 |

비교 가능한 월은 총 51개월이었다.

증가한 달의 비율은 약 58.82%였으며, 감소한 달의 비율은 약 41.18%였다.

`no_comparison` 2개월은 최초 관측 월인 2013년 7월과 데이터 공백 직후인 2017년 4월이었다.

증가한 달이 더 많다는 사실만으로 전체 관측 기간의 이용량이 증가했다고 판단할 수는 없다.

## 9. Magnitude of Monthly Changes

증가 및 감소 횟수뿐 아니라 변화량의 합계도 계산하였다.

| Metric | Result |
|---|---:|
| Increase Months | 30 |
| Decrease Months | 21 |
| Total Increase | +53,061 |
| Total Decrease | -39,474 |
| Net Change | +13,587 |

증가한 달의 평균 증가량은 약 1,768.7회였다.

감소한 달의 평균 감소량은 약 -1,879.7회였다.

감소한 달의 평균 변화 폭이 더 컸지만, 증가한 달의 수가 더 많아 유효한 월별 증감량의 합계는 +13,587회로 나타났다.

이 값은 연속된 월끼리 비교한 증감량의 합계이며, 데이터 공백을 가로지르는 변화량은 제외한다.

## 10. Independent Reconciliation

월별 증감량 합계의 정확성을 검증하기 위해 관측 기간을 연속된 월 단위의 두 구간으로 분리하였다.

각 구간의 마지막 달 출발량에서 첫 달 출발량을 빼는 방식으로 변화량을 다시 계산하였다.

| Period | Start Month | End Month | Start Trips | End Trips | Change |
|---|---|---|---:|---:|---:|
| 1 | 2013-07 | 2016-09 | 7,290 | 16,556 | +9,266 |
| 2 | 2017-04 | 2018-05 | 12,408 | 16,729 | +4,321 |
| **Total** | | | | | **+13,587** |

검산 결과는 다음과 같다.

`9,266 + 4,321 = 13,587`

이는 월별 `LAG()` 기반 증감량 합계와 정확히 일치하였다.

따라서 연속된 월에 대한 증감량 계산과 데이터 공백 제외 처리가 서로 일관되게 작동했음을 확인하였다.

## 11. Key Findings

1. 2017년 4월 기준 Station 519의 출발량은 12,408회로 분석 대상 Station 중 가장 많았다.
2. 실제 동점 데이터에서 `ROW_NUMBER()`, `RANK()`, `DENSE_RANK()`의 순위 처리 차이를 확인하였다.
3. `LAG()`와 `LEAD()`는 이전 달과 다음 달이 아니라 이전 행과 다음 행을 참조하므로 날짜 연속성 검증이 필요하다.
4. Station 519에서 2016년 10월부터 2017년 3월까지 6개월의 관측 공백을 확인하였다.
5. 비교 가능한 51개월 중 증가한 달은 30개월, 감소한 달은 21개월이었다.
6. 유효한 연속 월 증감량 합계는 +13,587회였으며, 독립적인 기간별 계산에서도 동일한 결과가 나왔다.

## 12. Limitations

분석은 전체 Citi Bike 시스템이 아닌 Station 519의 월별 변화에 집중하였다.

출발량의 증가와 감소는 실제 자전거 재고, 수요 충족률 또는 운영 효율을 직접 측정하지 않는다.

데이터 공백의 원인은 이번 분석만으로 확정할 수 없다.

계절성과 날씨 등 외부 요인의 영향은 별도로 검증하지 않았다.

따라서 분석 결과는 관측된 출발 횟수의 변화와 SQL 계산 정확성에 관한 결론으로 제한한다.

## 13. Deliverable

- `sql/09_window_functions.sql`

**Status:** Window Function 실습 13개, 데이터 공백 검증 및 독립 검산 완료.