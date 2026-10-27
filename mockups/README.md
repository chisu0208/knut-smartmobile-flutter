# 목업

개선판 화면 목업입니다. 2026-10-06에 만들었고, 원본 위치는 `E:\KNUT_App\mockups`입니다.
Flutter Material 3 기준이며, 그림 속 시각은 2026-10-06(화) 오후 2시 32분으로 가정했습니다.

| 파일 | 내용 |
|---|---|
| `overview.png` | 교통·학식 탭 목업 모음 (학식, 교통·시내버스, 교통·통학버스) |
| `meal.png` | 학식 탭 |
| `city.png` | 교통 탭 · 시내버스 |
| `commute.png` | 교통 탭 · 통학버스 |
| `mockup.html` | 교통·학식 목업 HTML (그림 속 식단·시간표 데이터 포함) |
| `way_overview.png` | 길찾기 목업 모음 (첫 화면, 검색, 길 안내) |
| `way_home.png` · `way_search.png` · `way_route.png` | 길찾기 각 화면 |
| `wayfinding.html` | 길찾기 목업 HTML (건물 번호·이름·층별 부서 데이터 포함) |

- 식단과 시간표는 학교 홈페이지(충주캠퍼스 학생식당, 통학버스, 시내버스 안내)에서 2026-10-06에 가져온 실제 내용입니다.
- 건물 번호·이름·층별 부서는 학교 홈페이지 캠퍼스 지도(2026-10-06 확인)의 실제 내용이고, 지도 그림·경로·걸리는 시간은 예시입니다.
- 하단 탭 5개(홈·출결·도서관·교통·학식)의 이름과 순서는 가정입니다. 색은 Material 3 파란 계열 기본 색이고, 학교 색을 정하면 바꿀 수 있습니다.
- 도서관 탭 리디자인(다른 팀원 작업)은 Figma에 있습니다: [도서관 탭 리디자인](https://www.figma.com/design/jIdmeS07CjO4wENQZNd02M/%EB%8F%84%EC%84%9C%EA%B4%80-%ED%83%AD-%EB%A6%AC%EB%94%94%EC%9E%90%EC%9D%B8?node-id=0-1)

## 도서관 탭 리디자인 (`library/`)

팀원의 Figma "도서관 탭 리디자인"(MODULE 04)을 2026-10-27에 캡처했습니다. Flutter 구현 기준 화면 크기는 390×844이고, 도서명·저자·좌석 수 등 데이터는 모두 시연용 샘플입니다.

| 파일 | 내용 |
|---|---|
| `library/01_overview.png` | 현재 문제, 개선 방향, 화면 구성, 색 토큰과 글자 크기 |
| `library/02_home.png` | 도서관 홈: 캠퍼스(충주·증평·의왕), 검색, 모바일 학생증, 열람실 실시간 현황, 내 대출 현황, 바로가기, 공지 |
| `library/03_search.png` | 검색 결과: 대출가능·캠퍼스 필터, 상태 배지, 위치 |
| `library/04_book_detail.png` | 도서 상세: 소장 정보, 서가 위치, 관심도서·서가 위치 안내 |
| `library/05_reading_room.png` | 열람실 좌석: 잔여 좌석, 좌석 배치도, 좌석 배정 |
| `library/06_student_id.png` | 모바일 학생증: 바코드, 남은 시간, 화면 밝기 안내 |
| `library/07_my_shelf.png` | 내 서재: 대출 중·예약·연체, 반납 D-day, 연장하기 |
| `library/08_components.png` | 부품: 상태 배지, 도서 카드, 도서관 안 하단 탭(홈·검색·학생증·열람실·내서재) |

색 토큰(Figma 변수 "KNUT Library"): primary `#A3162B`, primaryDark `#6E0E1C`, primarySoft `#FBECEE`, ink `#17191E`, sub `#5B6070`, mute `#9AA0AE`, line `#E6E8EE`, bg `#F4F5F8`, green `#0E9F4F`, amber `#D97A00`, blue `#2F6FEB`, seatUsed `#D5D9E0`. 글자: Noto Sans KR, 화면 제목 24 Black / 섹션 18 Bold / 카드 제목 15 Bold / 본문 13 Regular / 배지 11 Bold.

- 2026-10-27에 이 색 토큰을 앱 전체 대표색으로 쓰기로 했습니다(개선판 1차의 `#76161B` 대신).
- 도서관 화면 안에 자체 하단 탭이 있어서, 앱 하단 탭(홈·출결·도서관·교통·학식) 안에 넣을 때 두 탭 막대가 겹치지 않게 정리해야 합니다.
