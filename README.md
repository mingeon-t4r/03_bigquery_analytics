# NYC Citi Bike Analytics — BigQuery & Python

## 프로젝트 개요

NYC Citi Bike의 공개 운행 데이터를 활용하여 이용 패턴, Station별 수요, 출발·도착 흐름 및 월별 수요 변동성을 분석한 데이터 분석 프로젝트다.

Google BigQuery를 이용해 대규모 원본 데이터를 탐색하고, SQL 기반 데이터 품질 검증과 Data Mart 구축을 수행했다.
이후 Python과 pandas를 활용하여 집계 결과를 교차 검증하고, 수요 규모와 변동성을 기준으로 추가 운영 분석이 필요한 Station을 선정했다.

**최종 분석 결과, 전체 881개 출발 Station 중 29개를 운영 우선 검토 후보로 선정했다.**

이 프로젝트의 목적은 실제 자전거 배치량을 결정하는 것이 아니라, 관측 데이터에 근거하여 추가 조사가 필요한 대상을 식별하고 분석 결과의 정확성과 한계를 검증하는 것이다.

## 핵심 분석 결과

| 지표 | 결과 |
|---|---:|
| 원본 Trip | 58,937,715건 |
| Data Mart 분석 대상 Trip | 53,108,721건 |
| 월별 Station Data Mart | 24,876행 |
| 출발 Station 수 | 881개 |
| 관측 월 24개월 이상 Station | 461개 |
| 고수요 Station | 116개 |
| 최종 운영 검토 후보 | 29개 |
| 최종 후보 누적 이용량 | 5,993,530건 |
| 전체 대비 후보 이용량 비중 | 11.29% |
| 최종 후보 CV 단순 평균 | 49.96% |

최종 후보 29개는 전체 출발 Station의 약 3.3%에 해당하며, 전체 관측 출발 이용량의 11.29%를 차지했다.

이 비중은 Station별 관측 기간이 다를 수 있는 누적 이용량 기준이므로, 동일 기간의 운영 효율이나 공급 부족 수준을 의미하지 않는다.

## 분석 질문

1. Citi Bike 이용량은 월, 요일, 시간대에 따라 어떤 차이를 보이는가?
2. 출발량과 도착량이 집중되는 Station은 어디이며, 시간대에 따라 구성이 달라지는가?
3. 원본 데이터에서 분석 결과에 영향을 줄 수 있는 품질 문제는 무엇인가?
4. BigQuery에서 재사용 가능한 Data Mart와 분석 계층을 어떻게 구성할 수 있는가?
5. SQL과 Python의 집계 결과가 동일한지 어떻게 검증할 수 있는가?
6. 수요 규모와 상대적 변동성이 높은 Station을 어떻게 선별할 수 있는가?

## 데이터 및 분석 범위

| 항목 | 내용 |
|---|---|
| 원본 데이터 | `bigquery-public-data.new_york_citibike.citibike_trips` |
| 데이터 기간 | 2013년 7월 ~ 2018년 5월 |
| 원본 Grain | Trip 1건 |
| Data Mart | `bigquery-analytics-study.bigquery_learning.station_monthly_summary` |
| Data Mart Grain | Month × Start Station |
| 주요 지표 | Trip Count, Net Departure, 월평균 이용량, 표준편차, CV |

월별 Station Data Mart는 출발 시간과 출발 Station ID가 유효한 Trip을 대상으로 구성했다.
따라서 원본 전체 Trip 수와 Data Mart의 집계 Trip 수는 서로 다르다.

또한 2013년과 2018년은 연간 전체 기간이 아니므로 연도별 이용량을 단순 비교할 때 주의가 필요하다.

## 사용 기술

| 영역 | 기술 및 활용 |
|---|---|
| 데이터웨어하우스 | Google BigQuery |
| SQL | GoogleSQL, CTE, JOIN, Window Function, QUALIFY |
| 데이터 모델링 | 월별 Station Data Mart, Standard View, Materialized View |
| 저장 구조 | Partitioning, Clustering |
| Python 분석 | Python, pandas |
| 시각화 | matplotlib |
| 개발 환경 | VS Code, Jupyter Notebook |
| 버전 관리 | Git, GitHub |

## 분석 과정 및 주요 성과

### 1. 데이터 탐색 및 품질 검증 — Day 1~2

원본 데이터의 Grain, 기간, 주요 컬럼 및 쿼리 처리량을 확인했다.

`SELECT *`와 필요한 컬럼만 선택한 조회의 처리량을 비교하여 컬럼 기반 데이터 처리 특성을 확인했다.

주요 품질 검증 결과는 다음과 같다.

- 원본 Trip: 58,937,715건
- `starttime` NULL: 5,828,994건
- `stoptime` NULL: 5,828,994건
- 종료 시간이 시작 시간보다 빠른 Trip: 119건
- `tripduration` 최댓값: 19,510,049초

이상값을 무조건 삭제하지 않고 분석 목적에 따라 제외 여부를 판단하도록 기준을 정리했다.

관련 문서: [데이터 탐색](docs/data_exploration.md) · [데이터 품질 보고서](docs/data_quality_report.md)

### 2. 이용 패턴 및 Station 수요 분석 — Day 3~5

월별, 요일별, 시간대별 이용량을 비교했다.

전체 이용량은 평일에 더 많았고, 08시와 17~18시에 상대적으로 높은 이용량이 관찰됐다.
주말에는 낮~오후 시간대의 이용 패턴이 상대적으로 두드러졌다.

Station별 출발·도착 이용량과 Net Departure를 분석했다.

`net_departure = start_count - end_count`

- 전체 기간 Net Departure 최댓값: Station 519, +40,059건
- 전체 기간 Net Departure 최솟값: Station 324, -29,976건
- 전체 Station Flow 집계 대상: 927개 Station ID
- 전체 출발량과 도착량: 각각 53,108,721건

시간대별 주요 Station 구성이 서로 다름을 확인했다.

Net Departure는 관측된 출발·도착 Trip 수의 차이이며 실제 자전거 재고량이나 부족 대수를 의미하지 않는다.

관련 문서: [이용 패턴 분석](docs/analysis_plan.md) · [Station 수요 분석](docs/station_analysis.md) · [Station Flow 분석](docs/station_flow_analysis.md)

### 3. BigQuery Data Mart 및 분석 계층 구축 — Day 6~8

원본 Trip을 Month × Start Station 단위로 집계한 `station_monthly_summary` 테이블을 생성했다.

- Data Mart: 24,876행
- 관측 월: 53개월
- 출발 Station: 881개
- 전체 출발량: 53,108,721건
- Grain 중복: 0건
- 원본 대비 집계 합계 차이: 0건

Partitioning과 Clustering을 적용하고 데이터 정확성과 쿼리 처리량을 비교했다.

정수 범위 Partitioning 실습에서 특정 조회의 보고된 처리량 감소를 확인했지만, 일부 비교에는 측정 방식의 한계가 있었다.
별도로 수행한 Clustering 비교에서는 추가적인 처리량 감소가 관측되지 않았다.

Standard View와 Materialized View를 구성하여 분석 로직을 재사용하고 처리량을 비교했다.

특정 조회에서 Materialized View의 처리량이 감소했지만, 청구 바이트는 동일했고 실행 시간 개선도 입증되지 않았다.

관련 문서: [Data Mart 설계](docs/data_mart_design.md) · [Partitioning 및 Clustering](docs/partition_clustering_analysis.md) · [View 설계](docs/view_design_analysis.md)

### 4. SQL 기반 추세 및 통계 분석 — Day 9~10

Window Function을 활용하여 Station 순위, 전월 대비 이용량 변화, 이동평균 및 상대적 변동성을 분석했다.

Station 519에서 2016년 10월부터 2017년 3월까지 6개월의 관측 공백을 확인했다.
누락된 기간을 실제 연속 월의 변화로 잘못 계산하지 않도록 비교 조건을 검증했다.

- Station 519 관측 월: 53개월
- 전월 비교 가능 월: 51개월
- 연속 관측 구간별 순변화 합계: +13,587건
- 2017년 4월 전체 출발량: 1,315,404건
- 2017년 4월 Station 519 출발량: 12,408건

월별 Station 점유율의 합계가 100%인지 검산하고, 행 기준 이동평균과 달력상 연속 월 기준 이동평균을 구분했다.

관련 문서: [Window Function 분석](docs/window_function_analysis.md) · [고급 SQL 분석](docs/advanced_analytics.md)

### 5. BigQuery와 Python 교차 검증 — Day 11~12

BigQuery 조회 결과를 pandas DataFrame으로 변환하여 SQL과 Python의 집계 결과를 비교했다.

Station 519의 관측 월 수, 누적 이용량, 월평균 이용량이 두 환경에서 일치함을 확인했다.

전체 881개 Station에 대해서도 집계 결과를 비교했다.

- 분석 행 수: 24,876건
- Station 수: 881개
- NULL·중복·음수 이용량: 0건
- 집계 전후 전체 이용량 차이: 0건
- SQL과 Python의 반올림된 평균 표시값 차이: 18개 Station
- 정수 기반 평균 검산: 881개 Station 전체 일치

`validate_data()` 함수를 작성하고 오류 데이터를 의도적으로 주입하여 음수 이용량과 합계 오류를 감지하는지 확인했다.

Windows 애플리케이션 제어 정책으로 `pyarrow` DLL이 차단된 환경에서는 BigQuery 결과를 Python 객체로 가져온 뒤 pandas DataFrame으로 구성하는 방식을 사용했다.

관련 문서: [Python 연동 분석](docs/bigquery_python_analysis.md) · [데이터 분석 파이프라인](docs/bigquery_pipeline_analysis.md)

### 6. 최종 Station 후보 선정 — Day 13

월별 Station 출발량을 기준으로 관측 기간, 월평균 이용량, 변동계수(CV)를 결합한 후보 선정 규칙을 적용했다.

**후보 선정 기준**

1. 관측 월 수 24개월 이상
2. 해당 Station 그룹에서 월평균 이용량 상위 25%
3. 고수요 그룹에서 CV 상위 25%

**선정 결과**

| 단계 | Station 수 |
|---|---:|
| 전체 | 881개 |
| 관측 월 기준 충족 | 461개 |
| 월평균 이용량 기준 충족 | 116개 |
| 최종 후보 | 29개 |

CV가 가장 높은 후보는 Station 514였다.

| 지표 | Station 514 | Station 2006 |
|---|---:|---:|
| 관측 월 수 | 53 | 53 |
| 월평균 이용량 | 5,167.87 | 5,034.94 |
| 모집단 표준편차 | 3,441.51 | 2,981.51 |
| CV | 66.59% | 59.22% |

두 Station의 관측 월은 동일했고 월평균 이용량도 비슷했지만 Station 514의 상대적 변동성이 더 높았다.

최종 후보 29개에 대한 선정 조건, 누락, 잘못된 포함 및 중복 검증을 모두 통과했다.

**운영 관점의 결론**

29개 Station은 자전거를 즉시 추가 배치할 대상이 아니라 추가 운영 분석을 위한 우선 검토 후보로 제안한다.
실제 배치 결정에는 시간대별 대여·반납량, 자전거 재고, 대여 실패 및 재배치 기록이 필요하다.

관련 문서: [최종 Station 분석 보고서](docs/final_station_analysis.md)

## 데이터 검증 및 분석의 한계

본 프로젝트는 분석 결과의 재현성과 집계 정확성을 확인하기 위해 여러 단계의 검산을 수행했다.

- 원본과 Data Mart의 전체 이용량 및 집계 단위 비교
- JOIN 전후 집계 합계 보존 확인
- Station별 NULL 및 중복 검증
- SQL과 pandas의 집계 결과 교차 검증
- 누락된 관측 월 식별
- 최종 후보 선정 조건 및 집합 일치 검증
- 오류 데이터 주입을 통한 검증 함수 테스트

다만 다음과 같은 한계가 있다.

- 과거 Trip 기록을 사용하므로 현재의 운영 상태를 나타내지 않는다.
- 관측 월 수가 실제 Station 운영 기간과 동일하다고 단정할 수 없다.
- 일부 Station ID에서 복수의 Station Name이 관찰됐으며 물리적 Station의 동일성은 별도로 검증하지 않았다.
- 월별 출발량에는 계절성, 장기 추세 및 관측 공백의 영향이 포함될 수 있다.
- 실제 자전거 재고와 대여 실패 데이터가 없어 공급 부족 여부를 판단할 수 없다.
- 후보 선정 기준은 탐색적 규칙이며 실제 운영 성과를 기준으로 최적화한 결과가 아니다.
- Day 13 최종 SQL의 Python 결과 재현 검증은 별도 확인이 필요하다.

## 프로젝트 산출물

### SQL

| 단계 | 파일 |
|---|---|
| Day 1 | [BigQuery 기초](sql/01_bigquery_basics.sql) |
| Day 2 | [데이터 품질 검증](sql/02_data_quality_check.sql) |
| Day 3 | [이용 패턴 분석](sql/03_usage_pattern_analysis.sql) |
| Day 4 | [Station 수요 분석](sql/04_station_analysis.sql) |
| Day 5 | [Station Flow 분석](sql/05_station_flow_analysis.sql) |
| Day 6 | [Data Mart 구축](sql/06_create_data_mart.sql) |
| Day 7 | [Partitioning 및 Clustering](sql/07_partition_clustering.sql) |
| Day 8 | [View 설계](sql/08_bigquery_views.sql) |
| Day 9 | [Window Function](sql/09_window_functions.sql) |
| Day 10 | [고급 SQL 분석](sql/10_advanced_analytics.sql) |
| Day 11 | [Python 연동 검증](sql/11_bigquery_python_validation.sql) |
| Day 12 | [분석 파이프라인 검증](sql/12_station_pipeline_validation.sql) |
| Day 13 | [최종 Station 분석](sql/13_final_station_analysis.sql) |

### Python Notebooks

- [BigQuery 기초 분석](notebooks/01_bigquery_analysis.ipynb)
- [Day 11 Python 연동 검증](notebooks/11_bigquery_python_validation.ipynb)
- [Day 12 분석 파이프라인](notebooks/12_bigquery_analysis_pipeline.ipynb)
- [Day 13 최종 분석](notebooks/13_bigquery_final_analysis.ipynb)

### 분석 보고서

- [분석 계획 및 이용 패턴](docs/analysis_plan.md)
- [데이터 탐색](docs/data_exploration.md)
- [데이터 품질 검증](docs/data_quality_report.md)
- [Station 수요 분석](docs/station_analysis.md)
- [Station Flow 분석](docs/station_flow_analysis.md)
- [Data Mart 설계](docs/data_mart_design.md)
- [Partitioning 및 Clustering 분석](docs/partition_clustering_analysis.md)
- [View 설계 및 검증](docs/view_design_analysis.md)
- [Window Function 분석](docs/window_function_analysis.md)
- [고급 SQL 분석](docs/advanced_analytics.md)
- [BigQuery와 Python 연동](docs/bigquery_python_analysis.md)
- [Python 분석 파이프라인](docs/bigquery_pipeline_analysis.md)
- [최종 Station 운영 검토 후보 분석](docs/final_station_analysis.md)

## 결론

BigQuery와 Python을 활용하여 대규모 공개 데이터의 탐색, 품질 검증, 집계 모델링, SQL 분석, 시각화 및 결과 검산을 수행했다.

분석 결과를 단순히 나열하는 대신 수요 규모와 변동성을 결합하여 29개 Station을 운영 우선 검토 후보로 선정했다.

또한 데이터의 관측 공백, 집계 기준 차이, 반올림 문제 및 운영 데이터의 부재를 분석 한계로 구분하여 결과를 과도하게 해석하지 않도록 했다.

본 프로젝트는 SQL 작성뿐 아니라 **분석 설계 → 데이터 검증 → 결과 해석 → 업무 의사결정 제안**의 과정을 수행한 사례다.