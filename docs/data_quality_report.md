# Day 2 - Data Quality Report

## Dataset

NYC Citi Bike Trips

## Grain

1 row = Citi Bike 이용 1건(Trip)

즉, 테이블의 한 행은 한 번의 자전거 이용 여정을 의미한다.

## Data Period

- First trip: 2013-07-01 00:00:00
- Last trip: 2018-05-31 23:59:59.606000

전체 데이터는 2013년 7월부터 2018년 5월까지의 Trip을 포함한다.

단, 시작 연도인 2013년과 마지막 연도인 2018년은 1년 전체 기간의 데이터가 아니므로 연도별 단순 비교 시 주의가 필요하다.

## Total Trips

전체 Trip 수: 58,937,715건

약 5,894만 건의 Trip이 존재하므로, 전체 데이터를 직접 확인하기보다는 SQL 집계를 이용하여 데이터의 특성과 품질을 확인할 필요가 있다.

## NULL Check

| Column | NULL Count | NULL Rate |
|---|---:|---:|
| starttime | 5,828,994 | 9.89% |
| stoptime | 5,828,994 | 9.89% |
| start_station_name | 0 | 0.00% |
| end_station_name | 0 | 0.00% |

### 해석

starttime과 stoptime에서 각각 약 9.89%의 NULL이 확인되었다.

반면 start_station_name과 end_station_name에서는 NULL이 확인되지 않았다.

시간을 기준으로 하는 분석에서는 starttime 또는 stoptime이 NULL인 데이터가 분석 결과에 영향을 줄 수 있으므로 제외 여부를 결정하기 전에 NULL 발생 패턴을 추가로 확인할 필요가 있다.

## Time Validation

stoptime < starttime인 행: 119건

### 해석

종료 시간이 시작 시간보다 빠른 Trip이 119건 존재한다.

정상적인 Trip이라면 종료 시간이 시작 시간보다 빠를 수 없으므로 시간 관련 분석에서는 비정상 데이터로 판단할 수 있다.

전체 58,937,715건과 비교하면 매우 적은 수이지만, Trip 시간 계산 등에 오류를 발생시킬 수 있으므로 분석 전 처리 방침을 정할 필요가 있다.

## Trip Duration

- Minimum: 60초
- Average: 962.49초
- Maximum: 19,510,049초

평균 Trip 시간은 약 962.49초이지만, 최댓값은 19,510,049초로 평균에 비해 매우 큰 값이 존재한다.

따라서 평균만으로 일반적인 Trip 시간을 설명하면 일부 매우 큰 값의 영향을 받을 가능성이 있다.

다만 최댓값이 크다는 사실만으로 해당 데이터를 오류라고 판단할 수는 없으므로, Trip Duration의 분포와 극단값을 추가로 확인할 필요가 있다.

## Data Quality Findings

1. starttime과 stoptime에서 각각 5,828,994건(9.89%)의 NULL이 확인되었다.

2. stoptime이 starttime보다 빠른 Trip이 119건 존재하여 시간 순서가 비정상적인 데이터가 일부 존재한다.

3. tripduration의 평균은 962.49초인 반면 최댓값은 19,510,049초로 매우 큰 차이가 확인되어, Trip Duration 분포 및 극단값에 대한 추가 검증이 필요하다.

## Analysis Decision

### 현재 제외가 가능한 데이터

stoptime < starttime인 데이터는 정상적인 Trip의 시간 순서와 일치하지 않으므로 시간 및 이용시간 분석에서 제외하는 것을 고려한다.

### 조건에 따라 제외할 데이터

starttime 또는 stoptime이 NULL인 데이터는 시간대별·일별·월별 분석과 같이 해당 컬럼이 필요한 분석에서는 사용할 수 없으므로 해당 분석에서 제외한다.

다만 Station 분석 등 시간 정보가 필요하지 않은 분석에서는 무조건 제외할 필요가 없다.

### 아직 제외를 결정하지 않은 데이터

tripduration이 매우 큰 데이터.

큰 값이 존재한다는 사실만으로 오류라고 판단할 수 없으므로 분포와 상위 극단값을 추가로 확인한 후 처리 기준을 결정한다.

## Additional Validation Required

다음 사항은 추가 확인이 필요하다.

1. starttime과 stoptime이 동시에 NULL인지 확인
2. NULL이 특정 기간에 집중되어 있는지 확인
3. tripduration의 중앙값 및 분위수 확인
4. 매우 큰 tripduration 값의 실제 Trip 정보 확인
5. 연도별 데이터가 전체 12개월을 포함하는지 확인