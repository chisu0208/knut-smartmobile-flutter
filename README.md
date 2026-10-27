# knut-smartmobile-flutter

한국교통대학교 스마트모바일 1.1.3(Android)을 Flutter로 옮기고, 앱에서 고칠 수 있는 문제점을 고치는 프로젝트입니다.
홈 화면 내용은 원본처럼 학교 웹 페이지(`mobile.ut.ac.kr`)입니다. 개선판 2차부터 화면 아래에 탭 다섯 개(홈·출결·도서관·교통·학식)가 있고, 학식·교통 탭은 앱이 직접 그리는 새 화면입니다(앱 안 고정 데이터).

| 판 | 어디에 | 패키지 | 앱 이름 |
|---|---|---|---|
| **개선판** | `main` | `kr.ac.ut.mobile.renewal` | 스마트모바일 개선판 |
| 순수 이식판(개선 없이 옮긴 것) | 태그 `port-1.1.3` | `kr.ac.ut.mobile.flutter` | 한국교통대학교 스마트모바일 |
| 원본 | `한국교통대학교 스마트모바일_1.1.3.apk` | `kr.ac.ut.mobile` | 한국교통대학교 스마트모바일 |

세 앱은 패키지가 달라 같은 폰에 나란히 설치됩니다. 서버에는 원본과 같은 버전(1.1.3)으로 접속합니다.

- 개선판에서 고친 것과 고치지 않은 것, 확인 목록: [IMPROVEMENTS.md](IMPROVEMENTS.md)(2차: 10절)
- 원본 분석, 동작 규칙, 이식 구조: [HANDOFF.md](HANDOFF.md)
- 개선점 목록: [통합본.md](통합본.md), 새 화면 목업: `mockups/`
- 원본 디컴파일 코드와 리소스: `docs/legacy/`

## 실행

Flutter 3.47.2, Android 전용입니다.

```bash
flutter pub get
flutter run
```

Windows에서는(자세한 내용은 HANDOFF.md 2장):

- 한글·공백이 없는 영문 경로에 둡니다. 한글 경로에서는 `flutter analyze`와 Android 빌드가 실패합니다.
- Android Studio에서는 `pubspec.yaml`이 있는 폴더를 엽니다. GitHub zip은 폴더가 한 겹 더 생깁니다.
- 프로젝트가 pub 캐시(C:)와 다른 드라이브에 있으면 `%USERPROFILE%\.gradle\gradle.properties`에 `kotlin.incremental=false`를 넣습니다.

런처 아이콘을 다시 만들 때는 `python3 tool/make_launcher_icons.py`(Pillow 필요)를 실행합니다.

## 데이터 갱신 (학식·교통 탭)

학식·교통 탭은 앱 안 고정 데이터 `assets/data/`를 읽습니다. 앱은 학교 사이트에 묻지 않으므로, 새 주 식단이나 바뀐 시간표는 아래처럼 다시 만들어 커밋합니다.

| 파일 | 내용 | 출처 |
|---|---|---|
| `assets/data/meals.json` | 캠퍼스별 식당과 한 주 식단 | 학교 홈페이지 식단 안내(충주), 생활관 "오늘의 식단" 게시판 그림(증평) |
| `assets/data/transit.json` | 시내버스·통학버스·캠퍼스 순환버스 시간표, 캠퍼스별 지도 주소 | 학교 홈페이지 통학정보 |
| `assets/data/holidays.json` | 공휴일(쉬는 날)과 학기 기간 | 학교 학사일정 |

파일마다 `source`(출처 주소), `fetchedAt`(가져온 날), `validFrom`·`validTo`(적용 기간)가 들어 있고, 앱은 이 기준일을 화면에 보입니다.

스크립트는 Python 3.9 이상, 추가 패키지 없이 돌아갑니다(저장소 맨 위에서, Windows는 `python3` 대신 `py`).

```bash
python3 tool/make_data.py meals                    # 이번 주 식단(매주 월요일쯤)
python3 tool/make_data.py meals --date 2026-11-02  # 그 날짜가 든 주
python3 tool/make_data.py meals --weeks 2          # 지난주와 이번 주
python3 tool/make_data.py transit                  # 버스 시간표(학기가 바뀔 때)
python3 tool/make_data.py holidays --year 2027     # 공휴일·학기(해가 바뀔 때)
python3 tool/make_data.py all                      # 셋 다
flutter test test/data_files_test.dart             # 앱이 읽을 수 있는지 확인
```

- **충주 식단**은 학교 식단 페이지의 데이터를 그대로 나눕니다(메뉴·가격·이용 시간·안내·쉬는 날). 학교가 아직 그 주 식단을 올리지 않았으면 경고가 나오고 그 식당은 빈 주가 됩니다.
- **증평 식단**은 생활관 게시판에 그림으로만 올라옵니다. 새 식단표가 올라오면 `tool/data/meals_manual.json`의 `menus`를 그림대로 고치고(`validFrom`·`validTo`·`fetchedAt`·`note`도), `meals` 명령을 다시 돌리면 `meals.json`에 합쳐집니다.
- 캠퍼스·식당·노선을 더하거나 길찾기 주소를 바꿀 때는 `tool/make_data.py` 맨 위 설정(`SITE_RESTAURANTS`, `ROUTE_CHIPS`, `CAMPUS_MAPS` 등)을 고칩니다.
- 학교 사이트 구성이 바뀌어 읽지 못하면 스크립트가 오류로 멈추고, 읽지 못한 파일은 바꾸지 않습니다. 그때는 JSON을 직접 고쳐도 됩니다(형식은 지금 파일과 `lib/src/meal_data.dart`·`transit_data.dart`).
