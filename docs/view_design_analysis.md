# Day 8 — BigQuery Views & Reusable Analytics Layer

## 1. Objective

BigQuery의 Standard View와 Materialized View를 활용하여 재사용 가능한 분석 계층을 설계하고 데이터 정확성, 쿼리 처리량 및 갱신 설정을 검증한다.

## 2. Source Data

- Source: `bigquery-analytics-study.bigquery_learning.station_monthly_summary`
- Grain: Month × Start Station
- Total rows: 24,876
- Total trips: 53,108,721
- Total months: 53
- Total start stations: 881

Day 6에서 구축한 월별 Station 출발량 Data Mart를 기반으로 분석을 수행했다.

## 3. View Architecture

| Object | Type | Grain | Purpose |
|---|---|---|---|
| `station_monthly_summary` | Table | Month × Station | 월별 출발량 집계 데이터 저장 |
| `vw_station_monthly_usage` | Standard View | Month × Station | 월별 Station 데이터 조회 인터페이스 |
| `vw_station_total_usage` | Standard View | Station | 전체 기간 Station별 출발량 집계 로직 재사용 |
| `mv_station_total_usage` | Materialized View | Station | 집계 결과 저장 및 재사용 |

`vw_station_monthly_usage`는 원본 Data Mart의 세 컬럼을 그대로 노출한다.

`vw_station_total_usage`는 `SUM(trip_count)`와 `GROUP BY station_id`를 정의하여 전체 기간의 Station별 출발량을 제공한다.

`mv_station_total_usage`는 원본 Data Mart를 직접 참조하여 동일한 Station별 집계를 Materialized View로 구성한다.

## 4. Standard View Validation

### 4.1 Monthly View Aggregate Validation

| Metric | Original Table | Standard View |
|---|---:|---:|
| Total rows | 24,876 | 24,876 |
| Total trips | 53,108,721 | 53,108,721 |
| Total months | 53 | 53 |
| Total stations | 881 | 881 |

원본 테이블과 월별 View의 네 가지 집계 지표가 모두 일치했다.

### 4.2 Monthly View Row-Level Validation

| Metric | Result |
|---|---:|
| Compared rows | 24,876 |
| Missing in original | 0 |
| Missing in view | 0 |
| Mismatched counts | 0 |

Month × Station을 JOIN Key로 사용하여 원본과 View의 집계값을 비교했다.

누락 및 불일치가 발견되지 않았다.

### 4.3 Reusable Station Aggregation View

기존에는 Station별 전체 출발량을 조회할 때마다 `SUM(trip_count)`와 `GROUP BY station_id`를 작성해야 했다.

`vw_station_total_usage`를 생성한 후에는 저장된 집계 로직을 조회하여 동일한 결과를 재사용할 수 있게 되었다.

Station TOP 10 조회에서 기존 집계 SQL과 새 View의 결과가 모두 일치했다.

전체 Station 검증 결과는 다음과 같다.

| Metric | Result |
|---|---:|
| Compared stations | 881 |
| Missing in original | 0 |
| Missing in view | 0 |
| Mismatched counts | 0 |

전체 881개 Station에서 집계값 불일치가 발견되지 않았다.

## 5. Materialized View Design

`mv_station_total_usage`는 `station_monthly_summary`를 기반으로 `station_id`별 `SUM(trip_count)`를 저장하는 Materialized View이다.

일반 View와 달리 Materialized View는 집계 결과를 물리적으로 저장하고 재사용할 수 있다.

BigQuery는 저장된 결과와 기반 데이터의 변경 상태를 고려하여 쿼리를 처리할 수 있으므로, 모든 조회에서 동일한 성능 개선이 보장되는 것은 아니다.

### 5.1 Data Validation

| Metric | Result |
|---|---:|
| Compared stations | 881 |
| Missing in original | 0 |
| Missing in materialized | 0 |
| Mismatched counts | 0 |

일반 집계 View와 Materialized View의 Station별 집계값이 모두 일치했다.

## 6. Query Performance Comparison

동일한 조회 조건 `station_id = 519`를 적용하여 두 View의 Job Information을 비교했다.

| Metric | Standard View | Materialized View |
|---|---:|---:|
| Query result (`total_trips`) | 551,078 | 551,078 |
| Bytes processed | 388.69 KB | 13.77 KB |
| Bytes billed | 10 MB | 10 MB |
| Duration | 195 ms | 278 ms |
| Slot milliseconds | 5 | 32 |

처리량 감소율은 `(388.69 - 13.77) / 388.69 × 100`으로 계산했으며 약 96.5%다.

이번 실행에서 Materialized View의 처리량은 Standard View보다 작았다.

그러나 Bytes billed는 모두 10MB로 표시되었으므로, 이 결과만으로 실제 청구 비용이 감소했다고 판단할 수 없다.

Materialized View의 실행 시간과 Slot milliseconds는 오히려 크게 측정되었다.

각 쿼리를 한 번씩 측정했으므로 실행 시간의 우열을 판단하지 않는다.

Materialized View의 저장 공간 및 갱신 유지 비용도 이번 비교에는 포함되지 않았다.

## 7. Materialized View Refresh Metadata

`INFORMATION_SCHEMA.MATERIALIZED_VIEWS`에서 다음 정보를 확인했다.

| Metric | Observed Value |
|---|---|
| Last refresh time | 2026-10-14 02:05:02.362 UTC |
| Refresh watermark | 2026-10-14 02:05:02.362 UTC |
| Last refresh status | NULL |

갱신 시각과 워터마크가 동일하게 표시되었다.

마지막 자동 갱신 오류는 메타데이터에 보고되지 않았다.

`INFORMATION_SCHEMA.TABLE_OPTIONS`에서 다음 설정을 확인했다.

| Option | Value |
|---|---|
| `enable_refresh` | `true` |
| `refresh_interval_minutes` | `30.0` |

자동 갱신이 활성화되어 있으며 갱신 간격 설정은 30분이다.

이는 정확히 30분마다 갱신이 완료된다는 보장을 의미하지 않는다.

## 8. Design Decisions

### 8.1 Why Use Standard Views?

반복되는 집계 SQL을 공통 정의로 관리하여 분석 로직의 일관성과 재사용성을 높이기 위해 사용했다.

단순 컬럼 조회 View는 원본 테이블 직접 조회에 비해 이점이 제한적일 수 있다.

### 8.2 Why Use a Materialized View?

반복 조회되는 Station별 전체 출발량 집계의 처리량을 줄일 수 있는지 검증하기 위해 사용했다.

이번 실험에서는 처리된 바이트가 약 96.5% 감소했지만, 청구된 바이트와 실행 시간의 개선은 확인되지 않았다.

### 8.3 Why Validate Both?

View는 SQL 정의를 재사용하고 Materialized View는 계산 결과를 저장할 수 있지만, 어느 방식이든 데이터 정확성을 별도로 확인해야 한다.

따라서 전체 집계 지표, Grain별 불일치, Station별 집계값을 단계적으로 검증했다.

## 9. Limitations

1. 기반 Data Mart의 크기는 약 583KB로 비교적 작다.
2. 성능 비교는 Station 519의 단일 조회 조건을 사용했다.
3. 각 쿼리의 실행 시간은 한 번만 측정했다.
4. 쿼리 캐시 사용 여부는 별도로 확인하지 않았다.
5. Materialized View의 저장 및 갱신 유지 비용은 측정하지 않았다.
6. 원본 데이터 변경 후 자동 갱신 동작은 실험하지 않았다.
7. 실제 Job Information은 확인했지만 장기간의 성능 안정성은 검증하지 않았다.

## 10. Conclusion

BigQuery Standard View 두 개와 Materialized View 한 개를 생성하여 재사용 가능한 분석 계층을 구축했다.

월별 View의 24,876행과 Station 집계 View의 881개 Station에 대해 원본과의 불일치가 없음을 확인했다.

Materialized View는 동일한 Station 조회에서 처리된 바이트를 약 96.5% 줄였지만, 청구된 바이트는 동일했으며 실행 시간 개선도 확인되지 않았다.

이번 학습을 통해 View 설계에서는 SQL 재사용성, 데이터 정확성, 실제 쿼리 처리량, 갱신 정책 및 유지 비용을 함께 고려해야 한다는 점을 확인했다.