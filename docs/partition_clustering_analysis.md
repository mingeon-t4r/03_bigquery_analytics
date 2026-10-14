# Day 7 — BigQuery Partitioning & Clustering Analysis

## 1. Objective

BigQuery Data Mart에 Partitioning과 Clustering을 적용하고, 데이터 정확성과 쿼리 처리량에 미치는 영향을 검증한다.

## 2. Source Data

- Source: `bigquery-analytics-study.bigquery_learning.station_monthly_summary`
- Grain: Month × Start Station
- Total rows: 24,876
- Total trips: 53,108,721

## 3. Table Design

| Table | Partitioning | Clustering |
|---|---|---|
| `station_monthly_summary` | 없음 | 없음 |
| `station_monthly_partitioned` | `trip_month` (DAY) | 없음 |
| `station_monthly_integer_partitioned` | `station_id` (정수 범위) | 없음 |
| `station_monthly_partitioned_clustered` | `station_id` (정수 범위) | `trip_month` |

정수 범위 Partitioning은 0부터 10,000까지 100 간격으로 설정했다.

## 4. Sandbox Limitation

최초 날짜 기반 Partitioned Table은 생성되었지만, 조회 결과 행 수가 0이었다.

BigQuery Sandbox에서는 Partition 만료 기간을 해제할 수 없었으며, 해당 작업에서 결제 미설정에 따른 제한 오류가 발생했다.

원본 데이터의 날짜가 2013~2018년이므로 과거 날짜 Partition의 만료가 원인으로 추정된다.

이에 따라 `station_id` 기반 정수 범위 Partitioning으로 실습을 변경했다.

## 5. Partition Validation

| Metric | Result |
|---|---:|
| Partition count | 14 |
| Partition total rows | 24,876 |
| Total logical bytes | 597,024 |
| Original total trips | 53,108,721 |
| Partitioned total trips | 53,108,721 |

정수 범위 Partition이 정상적으로 생성되었고 전체 행 수 및 Trip 합계가 보존되었다.

## 6. Clustering Data Validation

| Metric | Result |
|---|---:|
| Compared rows | 24,876 |
| Missing in original | 0 |
| Missing in clustered | 0 |
| Mismatched counts | 0 |

Partitioning과 Clustering을 함께 적용한 테이블에서 원본과의 집계 불일치는 발견되지 않았다.

## 7. Query Performance Comparison

### 7.1 Partition Pruning

Station 519를 조회하는 실험에서 일반 Data Mart의 보고된 처리량은 약 583KB, 정수 범위 Partitioned Table의 보고된 처리량은 약 48KB였다.

두 수치의 단위가 동일하다는 전제에서 처리량 감소율은 약 91.8%다.

Station 519의 53개 월별 집계 행을 비교한 결과 누락과 집계값 불일치는 모두 0건이었다.

이 비교의 Job 상세 정보는 별도로 기록하지 않았으므로 실행 후 처리량과 예상 처리량을 구분하는 데 한계가 있다.

### 7.2 Clustering

Query filter: `station_id = 519 AND trip_month = DATE '2017-01-01'`

| Metric | Partitioning Only | Partitioning + Clustering |
|---|---:|---:|
| Bytes processed | 47.95 KB | 47.95 KB |
| Bytes billed | 10 MB | 10 MB |
| Duration | 360 ms | 202 ms |
| Slot milliseconds | 3 | 8 |

Clustering을 추가했지만 이번 쿼리에서 처리된 바이트는 감소하지 않았다.

두 쿼리의 청구된 바이트 역시 동일하게 표시되었다.

실행 시간은 각각 한 번만 측정했으므로 성능 개선의 근거로 사용하지 않는다.

## 8. Interpretation

Partitioning은 조회 조건과 일치하는 Partition만 읽도록 하여 데이터 처리량을 줄일 수 있다.

Clustering은 지정한 컬럼을 기준으로 데이터 블록을 구성하지만, 데이터 규모와 블록 구성에 따라 추가적인 처리량 감소가 발생하지 않을 수 있다.

이번 실험에서는 Clustering에 따른 추가적인 처리량 감소가 관측되지 않았다.

## 9. Limitations

1. 실험 데이터는 약 583KB로 규모가 작다.
2. 성능 비교는 제한된 Station과 날짜 조건에서 수행했다.
3. 실행 시간을 반복 측정하지 않았다.
4. 처리된 바이트와 청구된 바이트는 서로 다른 지표다.
5. Sandbox 환경의 제한으로 날짜 기반 Partitioning을 충분히 실험하지 못했다.

## 10. Conclusion

BigQuery에서 정수 범위 Partitioning과 Clustering을 적용하고, 데이터 정확성을 검증했다.

정수 범위 Partitioning은 데이터가 보존된 상태에서 정상적으로 구성되었으며, 14개의 Partition이 확인되었다.

Clustering을 추가한 조회에서는 실제 처리량 감소가 관측되지 않았다.

이번 학습을 통해 저장 구조 최적화 기능은 적용 여부뿐 아니라 실제 처리량과 데이터 정확성을 함께 검증해야 한다는 점을 확인했다.