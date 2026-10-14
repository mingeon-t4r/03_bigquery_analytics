# BigQuery Analytics Project

Google BigQuery를 이용하여 대규모 공개 데이터를 탐색하고, SQL 분석부터 데이터마트 구축 및 Python 연동까지 수행하는 프로젝트입니다.

## Tech Stack

- Google BigQuery
- GoogleSQL
- Python
- pandas
- Jupyter Notebook

## Progress

### Day 1 - BigQuery Environment & Data Exploration

- Google Cloud / BigQuery 환경 구축
- BigQuery Project / Dataset 구조 이해
- NYC Citi Bike Public Dataset 탐색
- Dataset grain 및 schema 확인
- Query processing size 확인
- SELECT *와 필요한 컬럼 조회의 처리량 비교
- BigQuery의 columnar processing 특성 이해


### Day 2 - Data Quality Validation

- 전체 Trip 수 및 데이터 분석 기간 확인
- 주요 컬럼의 NULL 개수와 비율 검증
- starttime / stoptime 데이터 품질 확인
- 비정상적인 시간 순서 데이터 탐색
- tripduration의 최소·평균·최댓값 확인
- 극단값 존재 여부 탐색
- 분석 목적에 따른 데이터 제외 기준 검토
- 추가 검증이 필요한 데이터 품질 문제 정의


### Day 3 - Usage Pattern Analysis

- 분석 질문 및 분석 범위 정의
- Metric과 Dimension 정의
- 분석 기준 시간(starttime) 정의
- 월별 Citi Bike 이용량 분석
- 요일별 이용량 분석
- 시간대별 이용량 분석
- 요일 × 시간 이용 패턴 분석
- 관찰 결과와 원인 해석 구분
- 추가 검증이 필요한 분석 가설 정의

### Day 4 - Station Demand Analysis

- 전체 기간 기준 출발 Station 및 도착 Station Top 10 분석
- Station ID와 Station Name을 함께 사용하여 Station 단위의 집계 기준 정의
- Day 3에서 확인한 피크 시간대(08시, 17시, 18시)의 출발 Station Top 5 분석
- `CTE`, `ROW_NUMBER()`, `PARTITION BY`, `QUALIFY`를 활용하여 시간대별 Station 순위 계산
- 주말 12~17시 Trip을 하나의 분석 범위로 정의하여 주말 오후 주요 출발 Station Top 5 분석
- 출발 Top 10과 도착 Top 10을 `INNER JOIN`하여 공통 Station의 출발량과 도착량 비교
- 동일한 Station 개념을 `station_id`, `station_name`으로 표준화하여 JOIN 수행
- 출발량과 도착량의 차이를 계산하여 Station별 이동 흐름 차이 탐색
- 전체 기간, 피크 시간대, 주말 오후의 주요 Station 구성이 서로 다를 수 있음을 확인
- Trip 발생량만으로 이용 목적, 실제 자전거 재고 상태, 운영상 문제를 단정할 수 없다는 분석 한계 정의

#### Day 4 Key Findings

- Pershing Square North는 전체 출발 Trip뿐만 아니라 08시, 17시, 18시에서도 높은 출발량을 보였다.
- 08시와 17~18시에는 주요 출발 Station 구성이 서로 다르게 나타났다.
- 17시와 18시는 주요 출발 Station 구성이 비교적 유사하게 나타났다.
- 주말 12~17시에는 West St & Chambers St가 가장 높은 출발량을 기록했으며, 피크 시간대와는 다른 Station 구성이 나타났다.
- 출발량이 높은 Station과 도착량이 높은 Station은 상당 부분 겹치지만 각 Station의 순위와 Trip 수는 동일하지 않았다.

#### Day 4 Outputs

- `sql/04_station_analysis.sql`
- `docs/station_analysis.md`

### Day 5 - Station Flow Analysis

- Station ID와 Station Name의 관계를 검증하여 47개 Station ID에서 복수의 이름이 존재함을 확인
- Station ID를 기준으로 출발량과 도착량을 각각 집계
- `FULL OUTER JOIN`과 `COALESCE()`를 활용하여 전체 Station Flow 구성
- `net_departure = start_count - end_count` 지표 정의
- 전체 Station의 Net Departure 상위·하위 TOP 10 분석
- `Hour × Station` Grain을 정의하고 복합 JOIN Key 적용
- 08시, 17시, 18시의 시간대별 Net Departure TOP 5 분석
- 전체 기간과 시간대별 Station Flow 차이 확인
- Station ID 중복, NULL, Net Departure 계산 오류 검증
- JOIN 전후 출발·도착 Trip 합계 보존 검증
- Trip 흐름과 실제 자전거 재고 상태를 구분하여 분석 한계 정의

#### Day 5 Key Findings

- 전체 Station Flow에서 927개의 고유 Station ID가 확인되었다.
- Station 519는 전체 기간 Net Departure +40,059건으로 가장 높은 값을 기록하였다.
- Station 324는 전체 기간 Net Departure -29,976건으로 가장 낮은 값을 기록하였다.
- 08시에는 Station 521, 17시에는 Station 359, 18시에는 Station 402의 Net Departure가 가장 높았다.
- 전체 기간의 Station Flow 순위와 시간대별 Station Flow 순위는 동일하지 않았다.
- 전체 출발 Trip과 도착 Trip은 각각 53,108,721건으로 동일하였다.
- Station ID 중복, NULL, 계산 오류는 모두 0건이었다.
- JOIN 전후 출발·도착 Trip 합계가 동일하게 유지되어 전체 Station Flow의 집계 보존 검증을 통과하였다.

#### Day 5 Outputs

- `sql/05_station_flow_analysis.sql`
- `docs/station_flow_analysis.md`

### Day 6 — BigQuery Data Mart Creation & Validation

**Objective:** NYC Citi Bike 원본 데이터를 월별 Station 출발량 Data Mart로 구축하고 집계 정확성을 검증한다.

**BigQuery Implementation**
- `CREATE TABLE AS SELECT`를 사용하여 `station_monthly_summary` 생성
- Grain: Month × Start Station
- 저장 결과: 24,876행, 53개월, 881개 Station
- 집계 Trip: 53,108,721건

**Validation**
- Grain 중복: 0건
- NULL 및 비정상 집계값: 0건
- 원본 대비 전체 Trip 차이: 0건
- 월별 집계 불일치: 0행
- Month × Station 집계 불일치: 0건

**Deliverables**
- `sql/06_create_data_mart.sql`
- `docs/data_mart_design.md`

**Key Learning:** BigQuery CTAS를 통한 영구 테이블 생성, Data Mart Grain 설계, Source-to-Target Reconciliation

**Status:** Data Mart 생성 및 정확성 검증 완료. 성능과 비용 최적화는 미검증.

### Day 7 — BigQuery Partitioning & Clustering

**Objective:** BigQuery Data Mart에 Partitioning과 Clustering을 적용하고, 데이터 정확성과 쿼리 처리량을 비교하여 저장 구조 최적화의 효과와 한계를 검증한다.

**BigQuery Implementation**
- `PARTITION BY`를 이용한 날짜 기반 Partitioning 실습
- BigQuery Sandbox의 Partition 만료 제한 확인
- `RANGE_BUCKET()`과 `GENERATE_ARRAY()`를 활용한 정수 범위 Partitioning 적용
- `station_id` 기준 100 간격의 정수 범위 Partition 구성
- `CLUSTER BY trip_month`를 이용한 Clustering 적용
- `INFORMATION_SCHEMA.PARTITIONS`를 이용한 Partition 메타데이터 조회

**Data Validation**
- 원본 Data Mart 행 수: 24,876건
- 정수 범위 Partitioned Table 행 수: 24,876건
- 전체 Trip 합계: 53,108,721건
- 데이터가 존재하는 Partition: 14개
- Partition 메타데이터의 전체 행 수 합계: 24,876건
- Clustering 테이블의 Month × Station 집계 불일치: 0건

**Performance Analysis**
- Station 519 조회에서 일반 Data Mart와 정수 범위 Partitioned Table의 보고된 처리량 비교: 약 583KB → 약 48KB
- 두 처리량 수치의 단위가 동일하다는 전제에서 약 91.8% 감소
- 위 비교의 실행 후 Job 상세 정보는 별도로 확인하지 않아 측정 방식에 한계가 있음
- Station 519 및 2017년 1월 조건의 실제 Job 처리량 비교: Partitioning만 적용한 경우 47.95KB, Clustering까지 적용한 경우 47.95KB
- 두 쿼리의 청구된 바이트: 각각 10MB
- Clustering 추가에 따른 처리량 감소: 관측되지 않음
- 실행 시간은 단일 측정이므로 최적화 효과의 근거로 사용하지 않음

**Key Findings**
- Partitioning은 조회 조건과 일치하는 Partition을 선택하여 불필요한 데이터 읽기를 줄일 수 있다.
- Clustering은 데이터 블록 단위로 작동하며, 데이터 규모와 조회 조건에 따라 추가적인 처리량 감소가 발생하지 않을 수 있다.
- BigQuery Sandbox의 만료 제한을 고려하여 테이블 저장 구조를 설계해야 한다.
- 저장 구조 최적화는 데이터 정확성과 실제 Job 측정값을 함께 검증해야 한다.

**Deliverables**
- `sql/07_partition_clustering.sql`
- `docs/partition_clustering_analysis.md`

**Status:** Partitioning 및 Clustering 실습, 데이터 정확성 검증, 처리량 비교 완료.

### Day 8 — BigQuery Views & Reusable Analytics Layer

**Objective:** BigQuery Standard View와 Materialized View를 활용하여 재사용 가능한 분석 계층을 구축하고, 데이터 정확성 및 실제 쿼리 처리량을 검증한다.

**BigQuery Implementation**
- `CREATE VIEW`를 활용한 월별 Station 조회 View 생성
- `vw_station_monthly_usage`를 통한 Month × Station 데이터 조회
- `vw_station_total_usage`를 통한 Station별 전체 출발량 집계 로직 재사용
- `CREATE MATERIALIZED VIEW`를 활용한 집계 결과 저장 및 재사용
- `INFORMATION_SCHEMA.MATERIALIZED_VIEWS`를 통한 갱신 상태 확인
- `INFORMATION_SCHEMA.TABLE_OPTIONS`를 통한 자동 갱신 설정 확인

**Data Validation**
- 월별 View의 전체 행 수: 24,876건
- 월별 View의 Trip 합계: 53,108,721건
- 월별 View의 행 단위 누락 및 불일치: 0건
- Station 집계 View 검증 대상: 881개 Station
- Station 집계 View의 누락 및 불일치: 0건
- Materialized View의 Station별 집계 불일치: 0건

**Performance Analysis**
- 비교 조건: `station_id = 519`
- Standard View 처리량: 388.69 KB
- Materialized View 처리량: 13.77 KB
- 처리량 감소율: 약 96.5%
- 두 쿼리의 Bytes billed: 각각 10 MB
- Standard View 실행 시간: 195 ms
- Materialized View 실행 시간: 278 ms
- 단일 실행 결과이므로 실행 속도 개선은 입증되지 않음
- Materialized View의 저장 및 갱신 유지 비용은 비교에 포함하지 않음

**Materialized View Refresh**
- 자동 갱신 활성화: `true`
- 갱신 간격 설정: 30분
- 마지막 갱신 오류 상태: `NULL`
- 원본 데이터 변경 후 갱신 동작은 별도로 검증하지 않음

**Key Findings**
- Standard View는 SQL 정의를 저장하여 반복되는 분석 로직을 재사용할 수 있다.
- Materialized View는 집계 결과를 저장하여 특정 조회에서 처리량을 줄일 수 있다.
- 처리된 바이트 감소가 실제 청구 비용이나 실행 시간 개선을 의미하지는 않는다.
- View 설계 시 재사용성, 데이터 정확성, 쿼리 처리량 및 갱신 정책을 함께 고려해야 한다.

**Deliverables**
- `sql/08_bigquery_views.sql`
- `docs/view_design_analysis.md`

**Status:** View 생성, 데이터 정확성 검증, 성능 비교 및 갱신 설정 확인 완료. GitHub 최종 검토 대기.