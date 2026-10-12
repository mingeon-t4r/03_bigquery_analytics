# Day 6 — BigQuery Data Mart 설계 및 검증

## 1. Business Objective

NYC Citi Bike 원본 Trip 데이터를 매번 직접 집계하지 않고, 월별 Station 출발량을 재사용할 수 있도록 BigQuery Data Mart를 구축한다.

이번 Data Mart는 출발 Station의 월별 이용량을 분석하기 위한 집계 테이블이다.

## 2. Data Source

- **Source:** `bigquery-public-data.new_york_citibike.citibike_trips`
- **Target:** `bigquery-analytics-study.bigquery_learning.station_monthly_summary`
- **Platform:** Google BigQuery
- **Transformation:** `CREATE TABLE AS SELECT` (CTAS)

원본 데이터에서 `starttime`과 `start_station_id`가 NULL이 아닌 Trip만 집계 대상으로 사용한다.

## 3. Data Mart Design

**Grain: 1 row = 1 Month × 1 Start Station**

| Column | Description |
|---|---|
| `trip_month` | 출발 일시를 월 단위로 변환한 날짜 |
| `station_id` | 출발 Station ID |
| `trip_count` | 해당 월과 Station의 출발 Trip 수 |

`DATE_TRUNC(DATE(starttime), MONTH)`를 사용하여 출발 일시를 월 단위로 변환하고, `trip_month`와 `station_id`를 기준으로 집계한다.

이번 테이블에는 출발량만 포함하며, 도착량과 Net Departure는 포함하지 않는다.

## 4. Implementation

BigQuery에서 `CREATE TABLE AS SELECT`를 사용하여 집계 결과를 영구 테이블로 생성했다.

생성된 테이블은 `bigquery_learning` Dataset에 저장되며, 후속 SQL에서 원본 데이터 대신 참조할 수 있다.

테이블 생성 SQL과 검증 SQL은 `sql/06_create_data_mart.sql`에 관리한다.

## 5. Data Mart Profile

| Metric | Result |
|---|---:|
| Total rows | 24,876 |
| Unique months | 53 |
| Unique stations | 881 |
| First month | 2013-07-01 |
| Last month | 2018-05-01 |
| Total trips | 53,108,721 |

총 24,876개의 Month × Station 조합이 생성되었다.

53개월은 실제 집계 데이터가 존재하는 월의 수이며, 시작 월과 종료 월 사이의 모든 달에 데이터가 존재한다는 의미는 아니다.

## 6. Data Quality Validation

| Validation | Result | Status |
|---|---:|---|
| Duplicate Month × Station combinations | 0 | PASS |
| NULL trip_month | 0 | PASS |
| NULL station_id | 0 | PASS |
| NULL trip_count | 0 | PASS |
| trip_count ≤ 0 | 0 | PASS |

집계 테이블 내부에서 Grain 중복, NULL 및 비정상 집계값은 발견되지 않았다.

## 7. Source-to-Target Reconciliation

### 7.1 Total Trip Comparison

| Metric | Result |
|---|---:|
| Source trips | 53,108,721 |
| Data Mart trips | 53,108,721 |
| Difference | 0 |

원본과 Data Mart의 전체 Trip 수가 일치했다.

### 7.2 Monthly Comparison

월별 Trip 수를 비교한 결과 불일치하는 월은 0개였다.

### 7.3 Grain-Level Comparison

| Metric | Result |
|---|---:|
| Compared Month × Station combinations | 24,876 |
| Missing in source | 0 |
| Missing in Data Mart | 0 |
| Mismatched trip counts | 0 |

원본과 Data Mart의 Month × Station 조합 및 Trip 수가 모두 일치했다.

## 8. BigQuery Concepts Learned

- **Dataset:** BigQuery 테이블을 관리하는 논리적 컨테이너
- **CTAS:** SELECT 결과를 새로운 테이블로 저장하는 방식
- **Schema:** 테이블 컬럼과 자료형의 정의
- **Grain:** 테이블 한 행이 나타내는 데이터의 단위
- **Source-to-Target Reconciliation:** 원본과 대상 테이블의 집계 정확성을 비교하는 검증 방법

## 9. Limitations

1. 출발 Station 기준 집계이므로 도착량이나 Net Departure를 직접 분석할 수 없다.
2. 월별 집계 과정에서 개별 Trip 수준의 정보가 제거된다.
3. 원본 데이터가 변경되어도 저장된 Data Mart가 자동으로 갱신되지는 않는다.
4. Station ID가 기간 전체에서 동일한 물리적 Station을 의미하는지는 별도 검증이 필요하다.
5. 이번 단계에서는 Partitioning, Clustering 및 쿼리 성능 최적화를 적용하거나 측정하지 않았다.
6. BigQuery Sandbox 환경에서는 저장 용량과 테이블 만료 정책에 제약이 있을 수 있다.

## 10. Conclusion

BigQuery CTAS를 활용하여 NYC Citi Bike 원본 데이터를 Month × Station 단위의 Data Mart로 구축했다.

생성된 24,876개 집계 행에 대해 내부 품질 검증과 원본 대조 검증을 수행했으며, 검사한 모든 항목에서 불일치가 발견되지 않았다.

이번 단계에서는 SQL 조회 결과를 실제 BigQuery 테이블로 저장하고 검증하는 과정을 완료했다.

비용 절감이나 성능 향상은 아직 측정하지 않았으므로 이번 결과의 성과로 주장하지 않는다.