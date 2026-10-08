# Day 5 - Station Flow Analysis

## 1. Business Question

Station별 출발 Trip과 도착 Trip은 얼마나 차이가 나며, 시간대에 따라 출발과 도착의 상대적인 크기가 달라지는가?

## 2. Analysis Overview

- Data Source: `bigquery-public-data.new_york_citibike.citibike_trips`
- Analysis Tool: Google BigQuery
- Original Grain: 1 row = 1 Trip
- Overall Flow Grain: 1 row = Station
- Hourly Flow Grain: 1 row = Hour × Station
- Overall Join Key: `station_id`
- Hourly Join Key: `trip_hour`, `station_id`
- Primary Metrics: `start_count`, `end_count`, `net_departure`

### Metric Definition

`net_departure = start_count - end_count`

- Positive: 출발 Trip이 도착 Trip보다 많음.
- Negative: 도착 Trip이 출발 Trip보다 많음.
- Zero: 출발 Trip과 도착 Trip 수가 동일함.

Net Departure는 분석 기간에 관측된 출발·도착 Trip 수의 차이를 의미하며, 실제 자전거 재고량이나 부족 대수를 의미하지 않는다.

## 3. Data Quality and Aggregation Decision

### Station ID and Name Validation

Station ID별 고유 Station Name 개수를 확인한 결과, 47개의 출발 Station ID에서 두 개 이상의 Station Name이 관찰되었다.

따라서 Station ID와 Station Name이 항상 1:1 관계를 유지한다고 가정할 수 없으며, 동일한 Station ID가 이름별로 분리 집계될 가능성이 확인되었다.

### Aggregation Decision

Day 4에서는 Station ID와 Station Name을 함께 GROUP BY에 사용했으나, Day 5에서는 Station ID만을 기준으로 집계하도록 변경하였다.

Station Name은 향후 대표 이름을 결정하거나 별도의 매핑 관계를 검증한 뒤 결과 표시용으로 추가할 예정이다.

Station ID의 재사용 여부와 물리적 Station의 동일성은 아직 확인되지 않았으므로 분석 기간 전체에서 동일 ID가 동일한 물리적 Station을 의미한다는 가정에는 한계가 있다.

## 4. Overall Station Flow

출발 Trip과 도착 Trip을 각각 Station ID 기준으로 집계한 뒤 FULL OUTER JOIN으로 결합하였다.

### Top 10 Net Departures

| Station ID | Start Count | End Count | Net Departure |
|---|---:|---:|---:|
| 519 | 551,078 | 511,019 | +40,059 |
| 521 | 268,807 | 231,151 | +37,656 |
| 517 | 208,020 | 172,675 | +35,345 |
| 3230 | 60,652 | 34,610 | +26,042 |
| 3164 | 107,694 | 84,504 | +23,190 |
| 3236 | 89,020 | 66,884 | +22,136 |
| 490 | 330,378 | 308,661 | +21,717 |
| 281 | 262,645 | 243,860 | +18,785 |
| 465 | 218,755 | 200,169 | +18,586 |
| 468 | 174,864 | 158,280 | +16,584 |

### Observation

Station 519는 전체 기간의 Net Departure가 +40,059건으로 가장 높았으며, Station 521과 Station 517이 각각 +37,656건, +35,345건으로 그 뒤를 이었다.

이들 Station에서는 분석 기간 전체에 걸쳐 도착 Trip보다 출발 Trip이 더 많이 기록되었다.

### Top 10 Net Arrivals

| Station ID | Start Count | End Count | Net Departure |
|---|---:|---:|---:|
| 324 | 72,790 | 102,766 | -29,976 |
| 492 | 249,341 | 276,269 | -26,928 |
| 497 | 423,334 | 444,460 | -21,126 |
| 514 | 273,897 | 290,100 | -16,203 |
| 510 | 97,619 | 112,830 | -15,211 |
| 459 | 308,582 | 323,647 | -15,065 |
| 426 | 384,116 | 399,033 | -14,917 |
| 304 | 159,674 | 172,864 | -13,190 |
| 432 | 226,682 | 238,874 | -12,192 |
| 415 | 96,779 | 108,524 | -11,745 |

### Observation

Station 324는 전체 기간의 Net Departure가 -29,976건으로 가장 낮았으며, Station 492와 Station 497이 각각 -26,928건, -21,126건을 기록하였다.

이들 Station에서는 분석 기간 전체에 걸쳐 출발 Trip보다 도착 Trip이 더 많이 기록되었다.

### Interpretation

전체 기간의 출발량과 도착량은 Station별로 차이가 있으며, 일부 Station에서는 출발량이 더 많고 다른 Station에서는 도착량이 더 많은 패턴이 관찰되었다.

전체 기간을 합산한 결과만으로는 특정 시간대에 발생하는 이동 흐름의 차이를 확인하기 어려우므로 시간대별 분석을 추가로 수행하였다.

## 5. Hourly Station Flow

Day 3에서 이용량이 높게 나타난 08시, 17시, 18시를 대상으로 시간대별 Net Departure TOP 5를 분석하였다.

출발 Trip은 `starttime`, 도착 Trip은 `stoptime`을 기준으로 시간을 추출하였으며, `trip_hour`와 `station_id`를 함께 JOIN Key로 사용하였다.

### 08:00 - Top 5 Net Departures

| Station ID | Start Count | End Count | Net Departure |
|---|---:|---:|---:|
| 521 | 43,431 | 11,478 | +31,953 |
| 432 | 31,100 | 3,563 | +27,537 |
| 511 | 28,574 | 2,162 | +26,412 |
| 445 | 27,047 | 5,152 | +21,895 |
| 3230 | 20,841 | 949 | +19,892 |

08시에는 Station 521이 +31,953건으로 가장 높은 Net Departure를 기록하였으며, Station 432와 Station 511이 그 뒤를 이었다.

### 17:00 - Top 5 Net Departures

| Station ID | Start Count | End Count | Net Departure |
|---|---:|---:|---:|
| 359 | 51,364 | 15,047 | +36,317 |
| 520 | 33,711 | 7,504 | +26,207 |
| 402 | 54,004 | 28,298 | +25,706 |
| 281 | 38,013 | 15,868 | +22,145 |
| 3443 | 23,082 | 2,294 | +20,788 |

17시에는 Station 359가 +36,317건으로 가장 높은 Net Departure를 기록하였으며, 08시와는 다른 Station들이 상위권에 나타났다.

### 18:00 - Top 5 Net Departures

| Station ID | Start Count | End Count | Net Departure |
|---|---:|---:|---:|
| 402 | 54,698 | 29,112 | +25,586 |
| 377 | 24,819 | 7,294 | +17,525 |
| 519 | 81,963 | 66,731 | +15,232 |
| 359 | 23,252 | 8,652 | +14,600 |
| 281 | 26,302 | 13,702 | +12,600 |

18시에는 Station 402가 +25,586건으로 가장 높은 Net Departure를 기록하였으며, Station 519도 +15,232건으로 TOP 5에 포함되었다.

## 6. Hourly Comparison

08시와 17시의 Net Departure TOP 5에는 공통 Station이 없었으며, 17시와 18시에는 Station 359, 402, 281이 공통으로 포함되었다.

Station 519는 전체 기간의 Net Departure가 가장 높았지만 08시와 17시의 TOP 5에는 포함되지 않았으며, 18시에는 3위를 기록하였다.

### Interpretation

Station별 출발량과 도착량의 차이는 시간대에 따라 다르게 나타나며, 전체 기간에서 차이가 큰 Station이 모든 시간대에서 동일하게 높은 차이를 보이는 것은 아니다.

시간대별 Flow는 여러 날짜의 동일한 시간을 합산한 결과이므로 특정 날짜의 실제 Station 상태를 나타내지는 않는다.

## 7. SQL Design

### FULL OUTER JOIN

출발 집계와 도착 집계 중 한쪽에만 존재하는 Station도 결과에 포함하기 위해 FULL OUTER JOIN을 사용하였다.

### COALESCE

한쪽 집계에 출발량 또는 도착량이 존재하지 않는 경우 NULL을 0으로 변환하여 Net Departure를 계산하였다.

### Join Key

전체 Station Flow는 Station ID를 기준으로 JOIN하였으며, 시간대별 Station Flow는 Hour와 Station ID를 함께 사용하여 서로 다른 시간대의 데이터가 연결되지 않도록 하였다.

### Grain

전체 Station Flow의 Grain은 Station이며, 시간대별 Station Flow의 Grain은 Hour × Station으로 정의하였다.

## 8. Validation Results

### Station Flow Validation

| Validation Metric | Result |
|---|---:|
| Total Rows | 927 |
| Unique Stations | 927 |
| Duplicate Count | 0 |
| Total Start Trips | 53,108,721 |
| Total End Trips | 53,108,721 |
| Total Net Departure | 0 |
| NULL Station ID Count | 0 |
| Calculation Error Count | 0 |

### JOIN Aggregate Preservation

| Metric | Before JOIN | After JOIN |
|---|---:|---:|
| Start Trips | 53,108,721 | 53,108,721 |
| End Trips | 53,108,721 | 53,108,721 |

### Validation Interpretation

전체 Station Flow는 927행으로 구성되었으며, 고유 Station ID 역시 927개로 확인되어 Station ID 기준 중복이 발견되지 않았다.

전체 출발 Trip과 도착 Trip은 각각 53,108,721건으로 동일하였으며, 전체 Net Departure 합계는 0건이었다.

JOIN 전후 출발 Trip 합계와 도착 Trip 합계가 각각 동일하게 유지되어 JOIN으로 인한 집계 합계의 증가나 감소가 발견되지 않았다.

NULL Station ID와 Net Departure 계산 오류는 모두 0건으로 확인되었다.

따라서 현재 분석에서 정의한 전체 Station Flow의 키 유일성, 계산 일관성, JOIN 전후 합계 보존 검증을 통과하였다.

단, 이 검증 결과는 전체 Station Flow에 대한 것이며, 시간대별 Station Flow의 JOIN 결과는 별도로 합계 보존을 검증하지 않았다.

## 9. Operational Interpretation

전체 기간과 시간대별로 Station의 출발량과 도착량 차이가 서로 다르게 나타나는 것이 확인되었다.

이러한 결과는 Station별 이동 흐름의 방향성과 시간대별 차이를 이해하기 위한 기초 자료로 활용할 수 있다.

다만 Net Departure는 Trip 기록에서 계산한 출발·도착 차이이므로 실제 자전거 재고 상태나 부족 여부를 직접 나타내지는 않는다.

실제 운영상의 문제나 재배치 필요성을 판단하려면 Station 수용량, 시간대별 재고량, 재배치 기록 등의 추가 데이터가 필요하다.

## 10. Limitations

- 분석 데이터는 2013년 7월부터 2018년 5월까지의 과거 Trip 기록이며, 첫해와 마지막 해는 부분 기간이다.
- 47개 Station ID에서 복수의 Station Name이 확인되었으나 이름 차이의 원인은 검증되지 않았다.
- Station ID가 분석 기간 전체에서 동일한 물리적 Station을 의미하는지는 추가 검증이 필요하다.
- Station ID 또는 분석 기준 시간이 NULL인 Trip은 해당 방향의 집계에서 제외하였다.
- 시간대별 Flow는 여러 날짜의 동일한 시간을 합산한 결과이며 특정 날짜의 상태를 의미하지 않는다.
- 시간대별 분석에서는 Net Departure가 큰 양수인 Station을 중심으로 TOP 5를 확인하였다.
- 전체 Station Flow의 JOIN 검증은 완료했으나 시간대별 Flow의 집계 보존 검증은 수행하지 않았다.
- Trip 데이터만으로 실제 Station 재고, 이용 목적, 운영상 문제의 발생 여부를 판단할 수 없다.

## 11. Conclusion

전체 927개 Station의 출발·도착 Trip을 비교한 결과, 전체 출발량과 도착량은 동일하지만 개별 Station에서는 서로 다른 출발·도착 차이가 나타났다.

08시, 17시, 18시의 Net Departure 상위 Station 구성이 달라지는 것을 확인하여 Station Flow 분석에서는 시간 Dimension을 함께 고려해야 한다는 결론을 얻었다.

전체 Station Flow는 Station ID 중복, NULL, 계산 오류, JOIN 전후 집계 합계 보존 검증을 통과하였다.

현재 분석은 Station별 Trip 흐름을 설명하는 탐색적 분석이며 실제 운영상 문제나 원인을 확인하려면 추가 데이터가 필요하다.