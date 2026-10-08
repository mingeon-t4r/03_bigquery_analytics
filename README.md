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