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