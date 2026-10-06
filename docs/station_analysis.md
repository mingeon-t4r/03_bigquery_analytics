# Day 4 - Station Demand Analysis

## Business Question

어떤 Station에서 Citi Bike 이용이 집중되며, 시간대와 평일/주말 여부에 따라 주요 Station의 순위가 달라지는가?

## Grain

### Original Data

1 row = 1 Trip

### Station Aggregation

1 row = 1 Start Station

### Hourly Station Aggregation

1 row = Hour × Start Station

분석 과정에서 원본 데이터의 Grain은 1 Trip이지만 Station별 집계에서는 1 Start Station으로, 시간대별 Station 분석에서는 Hour × Start Station으로 Grain이 변경된다.

---

## Overall Station Demand

### Top Start Stations

전체 기간 기준 출발 Trip이 가장 많은 Station은 다음과 같다.

1. Pershing Square North: 438,077
2. E 17 St & Broadway: 423,334
3. W 21 St & 6 Ave: 403,795
4. West St & Chambers St: 384,116
5. Lafayette St & E 8 St: 372,255
6. Broadway & E 22 St: 367,194
7. Broadway & E 14 St: 344,546
8. 8 Ave & W 33 St: 330,378
9. Cleveland Pl & Spring St: 318,700
10. W 41 St & 8 Ave: 311,403

### 관찰 결과

전체 기간 기준 Pershing Square North의 출발 Trip이 438,077건으로 가장 많았으며, E 17 St & Broadway와 W 21 St & 6 Ave가 그 뒤를 이었다.

상위 Station 사이에서도 출발 Trip 수에 차이가 존재하며, 일부 Station에서 상대적으로 많은 출발 Trip이 발생한 것을 확인할 수 있다.

### 해석

Citi Bike의 출발 Trip은 모든 Station에서 동일하게 발생하지 않으며, 일부 Station에서 상대적으로 높은 출발량이 관찰된다.

다만 전체 기간을 합산한 결과이므로 시간대와 요일에 따른 Station 이용 패턴의 차이는 이 결과만으로 확인할 수 없다.

---

## Top End Stations

전체 기간 기준 도착 Trip이 가장 많은 Station은 다음과 같다.

1. E 17 St & Broadway: 444,460
2. Pershing Square North: 419,931
3. W 21 St & 6 Ave: 407,982
4. West St & Chambers St: 399,033
5. Broadway & E 22 St: 377,854
6. Lafayette St & E 8 St: 372,679
7. Broadway & E 14 St: 344,033
8. W 20 St & 11 Ave: 323,647
9. Cleveland Pl & Spring St: 319,866
10. W 41 St & 8 Ave: 318,435

### 관찰 결과

전체 기간 기준 E 17 St & Broadway의 도착 Trip이 444,460건으로 가장 많았으며, Pershing Square North와 W 21 St & 6 Ave가 그 뒤를 이었다.

출발 Trip이 많은 Station 중 상당수가 도착 Trip 순위에서도 상위권에 포함되어 있다.

### 해석

Citi Bike의 도착 Trip 역시 모든 Station에서 동일하게 발생하지 않으며, 일부 Station에서 상대적으로 높은 도착량이 관찰된다.

출발량이 높은 Station과 도착량이 높은 Station이 상당 부분 겹치지만 각 Station의 순위와 Trip 수는 완전히 동일하지 않다.

---

## Start and End Station Comparison

출발 TOP 10과 도착 TOP 10을 비교하면 Pershing Square North, E 17 St & Broadway, W 21 St & 6 Ave, West St & Chambers St, Broadway & E 22 St 등 다수의 Station이 양쪽 순위에 모두 포함되어 있다.

Pershing Square North는 출발 Trip이 438,077건이고 도착 Trip이 419,931건으로 출발량이 18,146건 더 많았다.

E 17 St & Broadway는 출발 Trip이 423,334건이고 도착 Trip이 444,460건으로 도착량이 21,126건 더 많았다.

### 해석

전체 이용량이 많은 Station이라도 출발량과 도착량은 완전히 동일하지 않으며, Station마다 출발과 도착의 상대적인 크기에 차이가 존재한다.

현재 결과는 전체 기간을 합산한 값이므로 이러한 차이가 특정 시간대에 발생하는지 지속적으로 발생하는지는 추가 분석이 필요하다.

---

# Peak Hour Station Demand

Day 3 분석에서 전체 Trip 수가 특히 많았던 08시, 17시, 18시를 대상으로 출발 Station별 Trip 수를 비교하였다.

## 08:00

### Top Stations

1. Pershing Square North: 44,675
2. 8 Ave & W 31 St: 42,919
3. E 7 St & Avenue A: 31,100
4. 12 Ave & W 40 St: 29,328
5. E 14 St & Avenue B: 28,574

### 관찰 결과

08시에는 Pershing Square North의 출발 Trip이 44,675건으로 가장 많았으며, 8 Ave & W 31 St가 42,919건으로 두 번째로 많았다.

08시 TOP 5에는 E 7 St & Avenue A, 12 Ave & W 40 St, E 14 St & Avenue B도 포함되었다.

### 해석

08시에는 특정 Station에서 상대적으로 많은 출발 Trip이 발생하며, 전체 기간 기준 Station 순위와는 다른 Station도 상위권에 나타난다.

---

## 17:00

### Top Stations

1. Pershing Square North: 69,566
2. Broadway & E 22 St: 54,004
3. E 47 St & Park Ave: 51,364
4. E 17 St & Broadway: 49,616
5. West St & Chambers St: 44,777

### 관찰 결과

17시에도 Pershing Square North가 69,566건으로 가장 많은 출발 Trip을 기록하였다.

08시 TOP 5와 비교하면 Broadway & E 22 St, E 47 St & Park Ave, E 17 St & Broadway, West St & Chambers St가 새롭게 상위권에 나타났다.

### 해석

17시의 주요 출발 Station 구성은 08시와 차이가 있으며, 같은 날이라도 시간대에 따라 출발 Trip이 집중되는 Station이 달라지는 패턴이 나타난다.

---

## 18:00

### Top Stations

1. Pershing Square North: 66,707
2. Broadway & E 22 St: 54,698
3. E 17 St & Broadway: 49,535
4. West St & Chambers St: 46,214
5. W 21 St & 6 Ave: 45,019

### 관찰 결과

18시에도 Pershing Square North가 66,707건으로 출발 Trip 1위를 기록하였다.

Broadway & E 22 St, E 17 St & Broadway, West St & Chambers St는 17시와 18시 모두 TOP 5에 포함되었다.

### 해석

17시와 18시는 주요 출발 Station의 구성이 비교적 유사하게 나타나며, 두 시간대에 비슷한 공간적 이용 패턴이 존재하는 것으로 보인다.

다만 현재 데이터만으로 이러한 패턴이 특정 이용 목적 때문에 발생했다고 단정할 수는 없다.

---

## Peak Hour Comparison

Pershing Square North는 08시, 17시, 18시 모두 출발 Trip 1위를 기록하여 분석한 세 시간대에서 지속적으로 높은 출발량을 보였다.

08시에는 8 Ave & W 31 St, E 7 St & Avenue A 등이 상위권에 포함된 반면 17시와 18시에는 Broadway & E 22 St, E 17 St & Broadway, West St & Chambers St 등이 공통적으로 상위권에 나타났다.

### 해석

전체 기간의 Station별 Trip 수만으로는 확인하기 어려운 시간대별 차이가 존재하며, Station 이용 패턴을 분석할 때 시간 Dimension을 함께 고려할 필요가 있다.

08시와 17~18시의 Station 구성이 다르다는 사실은 시간대에 따라 Citi Bike의 공간적 이용 패턴이 달라질 가능성을 보여준다.

현재 데이터에서는 개별 Trip의 이용 목적을 확인할 수 없으므로 이를 출근 또는 퇴근 목적의 이용이라고 단정할 수는 없다.

---

# Weekend Afternoon

주말 12시부터 17시까지의 출발 Trip을 합산한 결과는 다음과 같다.

1. West St & Chambers St: 63,985
2. E 17 St & Broadway: 58,745
3. Central Park S & 6 Ave: 57,453
4. 12 Ave & W 40 St: 54,926
5. Broadway & W 60 St: 50,353

### 관찰 결과

주말 12~17시에는 West St & Chambers St의 출발 Trip이 63,985건으로 가장 많았으며, E 17 St & Broadway와 Central Park S & 6 Ave가 그 뒤를 이었다.

08시, 17시, 18시 분석에서 모두 1위를 기록했던 Pershing Square North는 주말 오후 TOP 5에는 포함되지 않았다.

Central Park S & 6 Ave와 Broadway & W 60 St는 주말 오후 TOP 5에 포함되어 앞서 분석한 주요 시간대와 다른 Station 구성이 나타났다.

### 해석

주말 오후의 주요 출발 Station 구성은 앞서 분석한 08시, 17시, 18시의 주요 Station 구성과 차이가 있다.

따라서 시간대뿐만 아니라 평일과 주말의 차이도 Station별 Citi Bike 이용 패턴과 관련되어 있을 가능성이 있다.

Central Park S & 6 Ave가 주말 오후 상위 Station이라는 사실은 확인할 수 있지만, 이를 관광이나 여가 목적의 이용이라고 현재 데이터만으로 단정할 수는 없다.

---

# Current Findings

## 현재 데이터에서 확인 가능한 사실

- 일부 Station에서 다른 Station보다 상대적으로 많은 출발 및 도착 Trip이 발생한다.
- 출발량이 높은 Station과 도착량이 높은 Station은 상당 부분 겹치지만 각 Station의 순위와 Trip 수는 동일하지 않다.
- Pershing Square North는 전체 출발 Trip뿐만 아니라 08시, 17시, 18시에서도 높은 출발량을 보였다.
- 08시와 17~18시의 주요 출발 Station 구성에는 차이가 존재한다.
- 17시와 18시는 주요 출발 Station의 구성이 비교적 유사하게 나타났다.
- 주말 12~17시의 주요 출발 Station 구성은 08시, 17시, 18시의 결과와 차이가 있었다.
- Station 이용 패턴을 분석할 때 Station만 보는 것보다 시간대와 평일/주말 여부를 함께 고려할 필요가 있다.

## 현재 데이터만으로 단정할 수 없는 내용

- Station별 이용량 차이가 발생하는 구체적인 원인은 확인할 수 없다.
- 개별 Trip이 출퇴근, 관광, 여가 등의 어떤 목적으로 발생했는지 확인할 수 없다.
- Central Park 인근 Station의 주말 이용량이 관광이나 여가 활동 때문에 높다고 단정할 수 없다.
- Station의 실제 자전거 재고 상태를 확인할 수 없다.
- 특정 Station에서 실제 운영상 문제가 발생했는지 판단할 수 없다.
- 전체 기간의 출발량과 도착량 차이만으로 특정 시점의 Station 상태를 판단할 수 없다.

---

# Operational Interpretation

전체 기간뿐만 아니라 시간대와 평일/주말 여부에 따라 주요 출발 Station의 순위가 달라지는 것이 확인되었다.

따라서 Station 이용 패턴을 분석할 때 전체 Trip 수만 사용하는 것보다 요일과 시간대를 함께 고려하는 것이 필요하다.

특히 여러 시간대에서 반복적으로 높은 출발량을 보이는 Station과 특정 요일 또는 시간대에서 상대적으로 높은 출발량을 보이는 Station을 구분하여 분석할 필요가 있다.

현재 분석은 Trip 발생량만을 사용했으므로 Station의 실제 자전거 재고 상태나 운영상 문제 발생 여부까지는 판단할 수 없다.

---

# Additional Validation

- Station별 출발량과 도착량의 차이(Net Flow)를 확인한다.
- 전체 기간의 Net Flow뿐만 아니라 시간대별 Net Flow를 확인한다.
- 평일과 주말의 Station별 출발 및 도착 패턴을 비교한다.
- 동일 Station의 출발량과 도착량이 시간에 따라 어떻게 변화하는지 확인한다.
- Station 위치 및 주변 특성을 추가 데이터와 결합할 수 있는지 검토한다.
- 실제 운영 상태를 분석하려면 Station 수용량 및 자전거 재고 데이터가 추가로 필요한지 검토한다.