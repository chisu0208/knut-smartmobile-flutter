# 인계 문서 — 기존 스마트모바일 앱을 Flutter로 1:1 이식

> 2026-10-26 작성, 2026-10-29 간소화. 원본 앱의 동작 규칙(5장)과 이식 구조(6장)를 적었다.
> 날짜별 갱신 기록, 에뮬레이터 확인 상세, 클라우드 Setup script 전문은 [HANDOFF.bak.md](HANDOFF.bak.md)에 있다.
> 개선판에서 바뀐 동작은 [IMPROVEMENTS.md](IMPROVEMENTS.md).

---

## 1. 할 일

`한국교통대학교 스마트모바일_1.1.3.apk`(패키지 `kr.ac.ut.mobile`, versionCode 19)의 **Java로 된 앱 부분(네이티브 껍데기)을 Flutter/Dart로 옮긴다.** 화면 내용은 원본처럼 `mobile.ut.ac.kr` 학교 웹 페이지를 띄운다.

- 배경: 모바일프로그래밍 수업 4인 팀 프로젝트(기존 앱 UI/UX 개선). 마감 2026-12-15.
- **이식판**: 사용자 결정(2026-10-26) "기능 추가 및 개선점 반영 없이 순수하게 플러터 프로젝트로만 변환". 태그 `port-1.1.3`(커밋 `3fd6182`)으로 보존했고 비교 기준이다.
- **개선판**: 지금 `main`(패키지 `kr.ac.ut.mobile.renewal`, 앱 이름 "스마트모바일 개선판"). 앱(Flutter·Kotlin)에서 고칠 수 있는 문제만 고쳤고, 화면 구성(웹 페이지, 하단 바, 메뉴)은 원본 그대로다.

| 단계 | 날짜 | 내용 |
|---|---|---|
| 개선판 1차 | 2026-10-26 | 통합본 항목 가운데 앱에서 고칠 수 있는 것 |
| 1차 후속 | 2026-10-27 | 웹 글자 1.3배 상한, 원본 버그로 남겨 두었던 앱 쪽 동작(5.21), 창 크기가 바뀔 때 팝업 크기(6-12) |
| 2차 | 2026-10-27 | 하단 탭 5개와 학식·교통·출결·도서관 탭, 대표색 #A3162B |
| 외부 리뷰 반영 | 2026-10-27~28 | 보안 4건과 작은 버그(IMPROVEMENTS.md 11절) |
| 2차 화면 되돌림 | 2026-10-29 | 하단 탭과 새 화면을 빼고 1차 모양으로. 대표색과 외부 리뷰 반영은 남김(IMPROVEMENTS.md 12절) |
| 기기 토큰 주소 제한 | 2026-10-30 | 기기 토큰이 든 웹뷰 공통 헤더와 결과 POST를 학교 주소에만 보냄. POST 리디렉트도 학교 주소로만(IMPROVEMENTS.md 13절) |

5장 규칙 가운데 개선판에서 바뀐 곳에는 **(개선판)** 표시를 달았다. 자세한 내용은 IMPROVEMENTS.md.

### 현재 상태

- `flutter analyze` 문제 없음, 시험 128개 통과, `flutter build apk --debug` 성공.
- 에뮬레이터(Pixel 7 AVD, Android 17)에서 로그인 전후 확인을 마쳤다: 메인·하단 바·팝업·뒤로 키, 로그인 후 타일 16개 전부, ≡ 메뉴 학사 항목, 내려받기, 동영상 전체 화면, 글자 크기 200%. 앱 크래시·Dart 예외 로그 없음.
- 학생시간표조회는 학교 서버 SQL 오류(`ORA-00923`)라 앱 문제가 아니다.
- 확인하지 못한 것: 실기기(SM-F741N), NFC·비콘·GPS, 실제 두 손가락 확대 동작.

### 원본과 비교가 필요한 것

에뮬레이터 이식판 확인에서 원본 규칙대로 나왔지만 원본 앱과 같은지 확인해야 하는 것(고치지 말고 기록만). 개선판에서 고친 것은 IMPROVEMENTS.md 1절 "에뮬레이터 시험에서 찾은 것".

1. 첫 실행에서 권한 안내 → 메인으로 간 뒤 뒤로 키를 두 번 누르면 `page/authority#1`로 돌아가 앱 헤더 없이 불러와 HTTP 404
2. QR 화면 닫기 버튼이 내비게이션 바에 반쯤 가려짐
3. 페이지 로드가 끝난 뒤에도 몇 초 동안 웹뷰가 늦게 그려짐(에뮬레이터)
4. `dialog` 버튼 글자가 90px 정사각형 칸에 잘림(5.8·5.9)
5. ECAMPUS가 열리자마자 닫힘: 자식 창(`panopto_login_popup`)의 `window.close()` → 팝업도 닫음(5.11)
6. 첨부파일을 받은 뒤 팝업이 하얗게 남고(자식 창 `about:blank`), 뒤로 키 한 번에 공지 팝업까지 닫힘

### 사용자 결정 (2026-10-26)

1. **applicationId**: 이식판 `kr.ac.ut.mobile.flutter`. 원본 앱과 나란히 설치해 비교한다.
2. **푸시(FCM)**: Firebase는 넣지 않는다(5.19). `push_url`로 다시 여는 흐름(5.2, 4장 `onNewIntent`)만 옮겨 둔다.
3. **HCE 학생증 서비스**: 옮기지 않는다(5.20).
4. **NFC 레코드 3개 미만 태그**: 강제 종료하지 않고 조용히 무시한다(5.15). 원본이 예외로 종료되는 다른 경우에도 적용했다(6.4, 사용자 확인 전).

### 아직 남은 것

- **실기기 확인**(8장, 개선판은 IMPROVEMENTS.md 9절).
- **원본과 비교**: 위 6가지를 원본 앱이 설치된 실기기에서 본다.
- **시작 화면 배경 이미지**: 해상도별 split APK에만 있어 저장소에 없다(5.2). 지금은 흰 화면. 앱 아이콘은 base APK의 `assets/app_icon_1024.png`로 만들었다.

---

## 2. 개발 환경 (사용자 PC 기준)

| 항목 | 값 |
|---|---|
| Flutter | 3.47.2 stable (`E:\flutter`), Dart 3.13.2 |
| Android SDK | `E:\AndroidSDK` (adb: `E:\AndroidSDK\platform-tools\adb.exe`) |
| 작업 위치 | `E:\knut-smartmobile-flutter-main\knut-smartmobile-flutter-main` (git clone, `origin/main` 추적) |
| 에뮬레이터 | Pixel 7 AVD, Android 17 |
| 시험 폰 | SM-F741N (원본 앱 설치됨) |
| 디컴파일러 | jadx 1.5.6 (로컬 임시 폴더, 저장소에는 없음) |

- 에뮬레이터를 `-no-snapshot-save`로 켜면 끌 때 상태가 버려져 그 사이 설치한 빌드가 사라진다. 이 옵션으로 켰다면 시험 전에 빌드를 다시 설치한다.
- 지금은 모든 작업을 로컬에서 한다. 클라우드 세션 환경(Flutter `/opt/flutter`, Android SDK `/opt/android-sdk`, Maven Central 429 대비 Google 미러)과 Setup script는 [HANDOFF.bak.md](HANDOFF.bak.md) 2·7장.

### Windows 주의 사항

- **영문 경로**: 한글·공백이 들어간 경로에서는 `flutter analyze`의 분석 서버가 LSP 오류로 죽고(`dart analyze`는 됨), AGP도 non-ASCII 경로를 거부해 빌드가 실패한다.
- **다른 드라이브**: 프로젝트와 pub 캐시가 다른 드라이브에 있으면 Kotlin 증분 컴파일이 `this and base files have different roots`로 실패한다. `%USERPROFILE%\.gradle\gradle.properties`에 `kotlin.incremental=false`를 넣는다(저장소의 `android/gradle.properties`에는 넣지 않음).
- **zip으로 받은 경우**: 폴더가 한 겹 더 생긴다. Android Studio는 `pubspec.yaml`이 있는 폴더를 열어야 한다("Dart SDK is not configured" 방지).

---

## 3. 저장소 안 자료

| 경로 | 내용 |
|---|---|
| `한국교통대학교 스마트모바일_1.1.3.apk` | 원본 APK (base APK만. 해상도별 split APK는 없음) |
| `docs/legacy/src/` | jadx로 복원한 앱 코드 전부(7개 클래스 + HTTP 도우미) |
| `docs/legacy/res/` | 이식에 필요한 레이아웃·도형·애니메이션·문자열·이미지 |
| `docs/legacy/AndroidManifest.xml` | 리소스 이름이 풀린 매니페스트 |
| `스마트모바일 기술 스택.md` | 원본 앱·웹·서버 기술 스택 분석 |
| `통합본.md` | UI/UX 개선점 목록. 개선판에 앱에서 고칠 수 있는 항목을 반영했다 |
| `IMPROVEMENTS.md` | 개선판에서 고친 것과 고치지 않은 것, 확인 목록 |
| `lib/`, `android/`, `test/`, `assets/` | Flutter 코드(6장) |
| `mockups/` | 새 화면(교통·학식 탭, 길찾기) 목업, 팀원 도서관 탭 Figma 캡처(`library/`). 앱에는 색 토큰만 남아 있다 |
| `tool/make_launcher_icons.py` | 런처 아이콘을 원본 APK의 학교 엠블럼으로 만드는 스크립트 |

### 파일 이름 대응

| 저장소 파일 | 원본 클래스 | 역할 |
|---|---|---|
| `BaseActivity_a.java` | `kr.ac.ut.mobile.a` | 공통 부모 Activity |
| `IntroActivity.java` | `kr.ac.ut.mobile.IntroActivity` | 시작 화면, 권한, 기기 등록 |
| `MainActivity.java` | `kr.ac.ut.mobile.MainActivity` | 앱의 거의 전부 |
| `RequestHttpURLConnection_i2a.java` | `i2.a` | POST 도우미 |
| `ZxingActivity.java` | 같음 | QR 스캔 화면 |
| `RoundedWebView.java` | `kr.ac.ut.util.RoundedWebView` | 모서리 둥근 웹뷰 |
| `FirebaseMessagingService.java` | `kr.ac.ut.service.…` | 푸시 수신 |
| `CardHostApduService.java` | `kr.ac.ut.service.…` | HCE (죽은 코드) |

### 난독화된 리소스 ID 대응

| 코드 속 이름 | 실제 리소스 |
|---|---|
| `h2.e.f7386b` / `f7387c` | layout `activity_intro` / `activity_main` |
| `h2.e.f7388d` / `f7389e` / `f7390f` / `f7391g` | layout `alert_popup` / `dialog_popup` / `nfc_popup` / `progress` |
| `h2.e.f7385a` | layout `activity_custom_scanner` |
| `h2.d.f7368j` / `f7365g` / `f7363e` / `f7376r` | `main_header` / `left_container` / `center_container` / `right_container` |
| `h2.d.f7369k` / `f7367i` / `f7366h` | `main_webview` / `main_footer` / `line_footer` |
| `h2.d.f7370l` / `f7372n` | `popup_bg_container` / `popup_container` |
| `h2.d.f7374p` / `f7371m` / `f7373o` | `popup_header` / `popup_body` / `popup_footer` |
| `h2.d.f7375q` / `f7383y` | `popup_webview` / `webview_frame` |
| `h2.d.f7380v` / `f7377s` / `f7381w` | `sub_left_container` / `sub_center_container` / `sub_right_container` |
| `h2.d.f7379u` / `f7378t` | `sub_head_container` / `sub_head2_container` |
| `h2.d.f7382x` / `f7360b` / `f7359a` / `f7361c` | `tvComment` / `btnOk` / `btnCancel` / `btn_container` |
| `h2.b.f7348a`~`f7355h` | anim `translate_in_bottom`, `_in_left`, `_in_right`, `_in_top`, `_out_bottom`, `_out_left`, `_out_right`, `_out_top` (순서대로) |
| `h2.c.f7357b` | drawable `round_head_title` |
| `h2.c.f7356a` (0x7f07008a) | drawable `ic_launcher` — xxhdpi split APK에만 있음 |
| `h2.f.f7392a` / `f7393b` / `f7394c` / `f7395d` | string `app_close` / `nfc_detail` / `nw_not_conn` / `qr_guide` |
| `h2.g.f7396a` | style `CustomDialog` |

`MainActivity`의 주요 필드:

| 필드 | 뜻 |
|---|---|
| `f7692M` / `f7714X` | 메인 웹뷰 / 팝업 웹뷰(`RoundedWebView`) |
| `f7715Y`, `f7716Z` | 팝업 안에서 `window.open`으로 열린 자식·손자 웹뷰 |
| `f7684I` / `f7686J` / `f7688K` / `f7690L` | 메인 헤더 / 왼쪽·가운데·오른쪽 메뉴 칸 |
| `f7719c0` / `f7720d0` | 메인 푸터 / 푸터 위 구분선 |
| `f7694N` / `f7708U` | 팝업 반투명 배경 / 팝업 본체 |
| `f7696O` / `f7698P` / `f7700Q` | 팝업 헤더 / 몸통 / 푸터 |
| `f7702R` / `f7704S` / `f7706T` | 팝업 헤더 왼쪽·가운데·오른쪽 메뉴 칸 |
| `f7710V` / `f7712W` | `sub_head_container` / `sub_head2_container` |
| `f7741y0` / `f7742z0` / `f7677E0` / `f7681G0` | 메인 헤더 / 메인 푸터 / 팝업 헤더 / 팝업 푸터의 배경(GradientDrawable) |
| `f7670B` | 팝업이 열려 있는지(애니메이션 상태와 얽혀 있음, 5.12) |
| `f7676E` | 지금 메인 웹뷰가 주인인지(true) 팝업이 주인인지(false) |
| `f7717a0` / `f7718b0` | 자식 / 손자 웹뷰가 열려 있는지 |
| `f7724h0` | 흔들기 동작 허용 여부 |
| `f7672C` | 현재 팝업 정렬(`left`·`right`·`top`·`bottom`·`center`·`full`) |
| `f7722f0` / `f7723g0` | NFC 결과 전송 주소 / QR·비콘 결과 전송 주소 |
| `f7680G` / `f7682H` | 메뉴 버튼 칸 크기(px). 기본 100 / 110 |
| `f7833u` / `f7832t` | 로딩 표시 Dialog / 알림·대화상자 Dialog |

---

## 4. 전체 흐름

```
IntroActivity
  ├ 최초 실행: assets/app_icon_1024.png → files/allytte/intro.png 복사 (화면엔 안 보임)
  ├ 권한 요청 (전부 허용해야 진행)
  ├ 저장된 splash_url 있으면 → intro.png로 내려받기
  └ 기기 등록 POST → 응답 문자열을 "screen_info"로 MainActivity에 넘김
MainActivity
  ├ 응답(JSON 명령)을 명령 처리기(x0)에 넣음
  │   └ 보통 {"command":"webview","config":{"show":"main", url, header, footer…}} → 메인 웹뷰 구성
  ├ 웹 페이지는 allytteAndroid.allytteCommandHandler(json)으로 다시 명령을 보냄
  └ 명령에 따라 팝업 웹뷰, 알림창, 외부 브라우저, QR, GPS, NFC, 비콘 등을 실행
```

- MainActivity는 `singleTask`다. 앱이 떠 있을 때 푸시를 누르면 IntroActivity가 `push_url`로 POST한 뒤 MainActivity를 다시 부르고, 기존 MainActivity의 `onNewIntent`가 `screen_info`를 받아 명령 처리기에 넣는다.

---

## 5. 동작 규칙 (원본 코드 기준)

> 원본(과 이식판)의 규칙이다. 개선판에서 바뀐 곳은 **(개선판)** 뒤에 바뀐 동작을 적었다. **(재확인)**은 원본 자료를 다시 읽어 처음 분석과 다르게 확인된 곳이다.

### 5.1 공통 부모 (`BaseActivity_a.java`)

- 저장소: SharedPreferences 이름 `"device"`, 키 `device_token`, `push_token`, `splash_url`, `webview`(`"main"`/`"popup"`)
- `O()` = versionName. `N(dp)` = dp→px
- 상태바: 흰 바탕 + 어두운 아이콘. 내용은 시스템 바 영역만큼 안쪽 여백
- 화면 방향: 인트로·메인 모두 세로 고정
- 언어 설정(`Y()`)은 기본 리소스가 한국어뿐이라 결과에 영향 없음 → 옮기지 않음
- `V(dialog)`: 대화상자 폭 = 화면폭 − 70dp, 높이 wrap, 배경 어둡게 0.5

### 5.2 시작 화면 (`IntroActivity.java`)

- 레이아웃: 배경 drawable `0x7f0700f2`(xxhdpi split APK에만 있음). `iv_intro`는 `gone`이라 보이는 건 배경뿐이다.
  - 사용자 폰에서 구하기: `adb shell pm path kr.ac.ut.mobile` → `split_config.xxhdpi.apk` pull.
- 푸시로 열렸으면 `push_url` extra를 기억한다. **(개선판)** `https://mobile.ut.ac.kr` 주소만 받는다(Kotlin `pushUrlOf`). 등록할 때 Dart `registerUrl`이 학교 주소(`isSchoolUrl`)인지 다시 보고, 아니면 기본 등록 주소로 보냄
- 권한(모두 허용돼야 다음으로): **(개선판)** 시작할 때 묻지 않고 기능을 쓸 때 그 권한만 요청

| SDK | 요청 권한 |
|---|---|
| 33 이상 | READ_PHONE_NUMBERS, CALL_PHONE, CAMERA, ACCESS_COARSE_LOCATION, POST_NOTIFICATIONS, NEARBY_WIFI_DEVICES |
| 30~32 | READ_PHONE_NUMBERS, WRITE/READ_EXTERNAL_STORAGE, CALL_PHONE, CAMERA, ACCESS_COARSE_LOCATION |
| 29 이하 | READ_PHONE_STATE, WRITE/READ_EXTERNAL_STORAGE, CALL_PHONE, CAMERA, ACCESS_COARSE_LOCATION |

- 이미 모두 허용 상태: `splash_url`이 있으면 그 이미지를 `intro.png`로 받은 뒤 기기 등록, 없으면 바로 기기 등록
- 권한 결과: 하나라도 거부 → 토스트 `권한이 거부되었습니다. 해당권한을 허용하셔야 합니다.` → (SDK 29 이상) 제목 없는 대화상자 `[전화,카메라]권한을 추가해 주세요.` + `OK`(앱 설정 화면 열고 종료), 취소 불가 / (28 이하) 그냥 종료
  - 라벨 규칙(권한 이름에 든 단어 순서대로): PHONE→전화, MEDIA→사진및동영상,카메라, CAMERA→카메라, ACCESS→위치, NOTIFICATION→알림, NEARBY→근처기기, STORAGE→파일및미디어, 그 외 기타. 중복 제거, 쉼표로 이음
  - 모두 허용 → 바로 기기 등록(splash 내려받기 안 함)
- 기기 등록:
  - `device_token` 없으면 `UUID.randomUUID().toString().toUpperCase()` 생성·저장
  - 주소(**순서·값 그대로**):
    ```
    https://mobile.ut.ac.kr//service/api/device/save
      ?devicePlatform=android&modelName={Build.MODEL}&deviceToken={token}
      &osVersion={Build.VERSION.SDK_INT}&osLang={Locale.getDefault().getLanguage()}
      &osName={Build.VERSION.RELEASE}&appVersion={versionName}&pushToken={push_token}&siteId=0
    ```
    (osVersion에 SDK 번호, osName에 버전 문자열, 슬래시 두 개 모두 원본 그대로)
  - `push_url`이 있으면 위 주소 대신 `push_url`로 POST
  - 응답(5.3)을 받는 즉시 MainActivity를 열고 인트로 종료. **(개선판)** 화면 설정을 받지 못하면 메인으로 넘어가지 않고 연결 안내와 다시 시도

### 5.3 POST 도우미 (`RequestHttpURLConnection_i2a.java`)

- POST, 본문 없음, 연결 제한 3초(읽기 제한 없음). **(개선판)** 기기 등록은 전체 10초 제한
- 리디렉트는 `HttpURLConnection` 기본값대로 따라간다(SDK 소스로 확인, 앱으로는 보지 않음): POST에 온 300~303은 GET으로 바꿔 최대 20번, http·https가 바뀌면 따라가지 않음, 다른 호스트로 가도 `Authorization` 말고는 헤더(기기 토큰 포함)를 그대로 붙임. **(개선판)** 학교 주소로 갈 때만 따라감(아니면 null). 따라가는 응답·횟수는 Dart `HttpClient`와 같아서 POST에 온 300~302는 따라가지 않고 그 응답을 그대로 읽으며, 최대 5번. http→https는 따라가고 https→http는 따라가지 않음
- 헤더: `User-Agent: allytte {versionName}`, `allytte-device-token: {token}`, `allytte-device-platform: android`
- 200이면 본문, 아니면 오류 본문을 JSON으로 파싱해 `"urlConnResult": 응답코드`를 더한 문자열
- 어떤 예외든 `null`(→ 명령 처리기는 아무것도 안 함)
- 모든 호스트를 통과시키는 HostnameVerifier가 있지만 실제 연결에는 쓰이지 않는다

### 5.4 메인 화면 구조 (`activity_main.xml`, `content_main.xml`)

```
CoordinatorLayout (바깥 여백 1dp)
├ 세로 LinearLayout
│  ├ main_header: 흰 배경, 높이 wrap
│  │   ├ center_container: 가로 꽉, 높이 50dp, 가운데 정렬
│  │   ├ left_container: 왼쪽 붙음, padding 3dp, 위아래 margin 5dp
│  │   └ right_container: 오른쪽 붙음, 같은 여백
│  ├ main_body(흰 배경, 위 margin 1dp, 남은 높이 전부) → main_webview
│  ├ line_footer: 높이 1dp, #dddddd
│  └ main_footer: 높이 50dp, 흰 배경. 처음엔 "*" 버튼 하나
│     (서버가 푸터를 보내면 바뀐다. 오프라인이면 "*"만 보임)
└ popup_bg_container: 화면 전체, #66000000, 처음엔 숨김, 누르면 팝업 닫기(A0)
   └ popup_container(세로, 폭 match/높이 wrap → 코드에서 크기 지정)
      ├ popup_header: 높이 58dp, 흰 배경 위쪽 모서리 30dp, 처음엔 숨김. 터치는 소비만 함
      │   ├ sub_head_container: 높이 50dp, #dddddd 30dp 둥근
      │   ├ sub_head2_container: 250×44dp, #333333 30dp 둥근
      │   ├ sub_center_container: 높이 40dp, 좌우 padding 10dp, #333333 30dp 둥근
      │   ├ sub_left_container / sub_right_container: 메인과 같은 여백
      ├ popup_body: 남은 높이, #66000000 30dp 둥근 → webview_frame(FrameLayout) → popup_webview
      └ popup_footer: 높이 50dp, 흰 배경 위쪽 모서리 30dp, 처음엔 숨김
```

- 메뉴 버튼 칸 크기 `f7680G`/`f7682H`는 **px** 100/110. 화면 높이(dp)가 750 이상이면 80/90.
- 로딩 표시(`progress.xml`): 투명 Dialog, 가운데 38dp 회전 이미지(`loading01.png`), 취소 불가. 페이지 시작 때 보이고 끝날 때 숨긴다. 화면 전체 터치를 막아 로딩 중에는 뒤로가기·닫기가 안 먹는다. **(개선판)** 입력을 막지 않고, 첫 화면이 그려지면 걷음

### 5.5 명령 처리기 `x0(json)`

1. null·빈 문자열이면 무시
2. 문자열 안의 `https://www.allytte.com`과 `http://allytte.com`을 `https://mobile.ut.ac.kr/`로 바꾼다
3. `{"action":[…]}` 배열을 앞에서부터 실행. 예외는 조용히 무시(이후 항목도 중단)

| command | 처리 |
|---|---|
| `webview` | `config.show`: `main` → 메인 구성(5.6) 후 `webview="main"` 저장 / `popup` → 팝업 구성(5.7) 후 `webview="popup"` / `change` → 현재 주인 웹뷰에 `config.url` 로드(5.10) |
| `alert` | `config.message` 알림창(5.9) |
| `dialog` | 버튼 대화상자(5.9) |
| `function` | 아래 표 |
| `browser` | 팝업 닫기(A0) 후 외부 브라우저로 `config.url` |
| `app` | `config.contentUrl`을 패키지 이름으로 보고 실행 시도, 없으면 `config.storeUrl`을 외부로. **(개선판)** Android 11부터 늘 스토어로 가던 것을, 그 앱의 시작 화면을 먼저 열어 봄 |
| `data` | `config.type=="global"`이고 `config.json.type=="splash"`이면 `config.json.config.url`을 `splash_url`로 저장하고 `intro.png`로 내려받음 |

| function | 처리 |
|---|---|
| `qrcode` | QR 화면(5.17) |
| `gps` | 위치 전송(5.14) |
| `nfc` | NFC 대기(5.15) |
| `beacone` | 비콘 검색(5.16). 철자 그대로 |
| `back` | 뒤로가기 처리(5.13) |
| `close` | 팝업 닫기(A0) |
| `exit` | 앱 종료(`finishAffinity`) |
| `url` | `config.url`로 POST(5.3) → 응답을 다시 명령 처리기에 |

"POST 후 응답을 명령 처리기에 넣는다"(`O0`)는 NFC·GPS·흔들기·비콘·QR·url 모두 공통이다. **(개선판)** 주소가 학교 주소(`ut.ac.kr`과 그 하위, http·https)가 아니면 보내지 않는다(규칙은 `lib/src/school_url.dart`).

**(재확인) 명령이 어디서 왔는지에 따라 달라지는 점**

- 웹 페이지가 보낸 명령은 JavaBridge 스레드에서 처리된다. 메인·팝업 구성, A0, NFC 확인은 `runOnUiThread`로 넘겨져 x0이 끝난 뒤 실행되고, `webview` 값 저장은 그보다 먼저 된다. 버튼·POST 응답의 명령은 UI 스레드라 구성이 먼저, 값 저장이 뒤다. 그래서 `B0`가 어느 웹뷰에 불러올지가 달라질 수 있다.
- 웹 페이지가 보낸 `function: back`은 JavaBridge 스레드에서 `WebView.canGoBack()`을 불러 예외가 나므로 **아무 일도 하지 않고** 남은 명령도 버려진다. 버튼이나 뒤로 키의 뒤로가기는 정상.
- 2번의 주소 바꾸기는 웹 페이지가 보낸 문자열에만 맞는다. 서버 응답과 버튼 명령은 `JSONObject.toString()`을 거쳐 `/`가 `\/`로 바뀌어 맞지 않는다.

### 5.6 메인 웹뷰 구성 (`webview`/`main`, 클래스 `w`)

1. `f7676E = true`. 팝업이 열려 있으면(`f7670B`) 닫기(A0). 팝업 애니메이션 취소
2. `config.setting.gesture`가 없으면 흔들기 허용 true, 있으면 그 값
3. `config.header`가 없으면 메인 헤더 숨김. 있으면:
   - `bgColor`: `"null"` → 흰색, `"transparent"` → 투명, 그 외 색상 코드
   - `bgImage`가 `"null"`이 아니면 그 이미지를 **메인 헤더 배경**으로(5.8)
   - `border`: `"null"` → 테두리 없음, 숫자 → 그 dp 두께 검은 테두리
   - `menu.left`/`center`/`right`: 없으면 그 칸 숨김. 있으면 칸을 비운 뒤 J0로 버튼 하나(5.8). 칸 이름 `main_left`·`main_center`·`main_right`
   - **(재확인)** 값이 **배열이면 예외로 이후 구성(푸터, 주소 불러오기)이 모두 중단된다**(바이트코드 확인). **(개선판)** 배열이면 버튼을 차례로 넣음
4. `config.footer`가 없으면 푸터와 구분선 숨김. 있으면 둘 다 보이고 푸터 구성(H0)
   - **(재확인)** H0는 시작할 때 `f7676E = false`로 바꾼다. 그래서 푸터가 있는 메인 구성 뒤 첫 뒤로가기는 팝업 쪽 분기(5.13 4번)로 가서 보이는 변화 없이 `f7676E`만 true로 돌린다. **(개선판)** 바꾸지 않아 첫 뒤로 키부터 반응
5. `config.url`을 헤더와 함께 로드(5.10)

### 5.7 팝업 웹뷰 구성 (`webview`/`popup`, 클래스 `RunnableC0257a`)

> jadx 결과가 이 부분에서 뒤틀려 있어 바이트코드 흐름을 따라 정리했다.

1. `f7676E = false`, `f7670B = false`, 팝업 웹뷰를 **새로 만들어 교체**(Z0, 5.11)
2. `config.align`, `url`, `header`, `footer` 읽기. 흔들기 설정은 메인과 같음. `f7672C = align`
3. 정렬별 팝업 크기와 등장(화면 크기는 `Display.getSize`). **(개선판)** 창 크기가 바뀌면 다시 계산

| align | 위치(gravity) | 폭 × 높이 | 등장 |
|---|---|---|---|
| `left` | 왼쪽 | 화면폭×0.8 × 꽉 | 왼쪽에서 밀려 들어옴 |
| `right` | 오른쪽 | 화면폭×0.8 × 꽉 | 오른쪽에서 |
| `top` | 위 가운데 | 꽉 × 화면높이×0.8 | 위에서 |
| `bottom` | 아래 가운데 | 꽉 × 화면높이×0.8 | 아래에서 |
| `center` | 가운데 | 화면폭×0.8 × 화면높이×0.8 | 애니메이션 없이 바로, `f7670B=true` |
| `full` | 가운데 | 꽉 × 꽉 | 애니메이션 없이 바로, `f7670B=true` |

   - 애니메이션: 500ms, accelerate_decelerate, `%p` 기준 이동(`docs/legacy/res/anim`). **(개선판)** 250ms decelerate
   - `left`만 등장 애니메이션을 **반투명 배경 전체(`f7694N`)**에 건다(배경까지 밀려 들어옴). 퇴장은 본체(`f7708U`)
4. 팝업 헤더 숨김 후, `config.header`가 없으면 모서리 규칙(i1)만 적용. 있으면:
   - 배경색 규칙은 메인과 같고, `transparent`일 때만 i1의 마지막 인자가 true
   - 모서리 규칙(i1, 5.7.1) 적용, `bgImage`는 **메인 헤더** 배경으로 감(원본 버그), 테두리 규칙 같음. **(개선판)** 팝업 헤더에 그림
   - `align=="full"`이면 `sub_head_container` 보이고 `sub_center_container` 배경을 `round_head_title`(#333333)로, 아니면 `sub_head_container` 숨기고 가운데 칸 배경 투명. `sub_head2_container`는 항상 숨김
   - `menu.left`/`center`/`right`: 길이 > 0인 배열이면 칸을 보이고 I0로 버튼 추가(칸 이름 `popup_left`, 가운데는 full이면 `popup_full` 아니면 `popup_center`, `popup_right`). 하나라도 있으면 팝업 헤더를 보임
5. `config.footer`가 없으면 팝업 푸터 숨김, 있으면 보이고 L0로 구성
6. 팝업 웹뷰에 `javascript:document.clear();document.open();document.close();`를 먼저 실행한 뒤 `config.url`을 c1로 로드(5.10)

#### 5.7.1 모서리 규칙 `i1(align, header, footer, 헤더투명)`

먼저 팝업 헤더 배경 모서리 = 위쪽 30dp, 팝업 몸통 padding 0. 그다음 align별로(헤더·푸터는 문자열 `"null"` 여부):

- `bottom`
  - 둘 다 없음 → 웹뷰 위쪽 두 모서리만 둥글게
  - 헤더만 → 헤더 위쪽 30dp. 헤더 투명이면 웹뷰 위쪽 둥글게, 아니면 웹뷰 모서리 없음
  - 푸터만 → 웹뷰 위쪽 둥글게, 팝업 푸터 모서리 없음
  - 둘 다 → 헤더 위쪽 30dp, 푸터 모서리 없음. 헤더 투명이면 웹뷰 위쪽 둥글게, 아니면 없음
- `center`
  - 둘 다 없음 → 웹뷰 네 모서리
  - 헤더만 → 헤더 위쪽 30dp. 헤더 투명이면 네 모서리, 아니면 아래쪽 두 모서리만
  - 푸터만 → 팝업 몸통 위 padding 30dp, 푸터 아래쪽 30dp
  - 둘 다 → 헤더 위쪽, 푸터 아래쪽 30dp. 헤더 투명이면 웹뷰 위쪽만, 아니면 없음
- `top`
  - 둘 다 없음 → 웹뷰 아래쪽 두 모서리
  - 헤더 있음 → 헤더 모서리 없음, 웹뷰 아래쪽 두 모서리
  - 푸터만 → 푸터 아래쪽 30dp
- 그 외(`left`·`right`·`full`) → 헤더·푸터·웹뷰 모두 모서리 없음

웹뷰 모서리 반지름은 15dp(`RoundedWebView`), 순서는 (왼위, 오위, 오아래, 왼아래). 팝업 웹뷰를 새로 만들기 때문에 **기본값은 네 모서리 모두 둥글다.** 위에서 웹뷰 모서리를 언급하지 않은 경우(`center` 푸터만, `top` 푸터만)는 네 모서리가 둥근 채로 남는다.

### 5.8 버튼 만들기 (E0)와 메뉴 칸

- 버튼 하나(JSON): `icon`, `name`, `align`, `color`, `action`. 값이 없으면 문자열 `"null"`로 취급
- `icon`이 없으면 배경 투명. 있으면 이미지를 **동기로 내려받아** `align`별 배치:
  - `null` → 버튼 배경 전체를 이미지로
  - `left`/`top`/`right`/`bottom` → 그쪽에 아이콘(compound drawable), 그쪽 padding 30dp
  - **(재확인)** bounds 없는 drawable을 넘겨 아이콘이 그려지지 않는다. 이 경우와 `align`이 그 밖의 값일 때는 **AppCompat 기본 회색 버튼**(#d6d7d7, 그림자) 모양이 남는다. 이식도 같게 했다(실기기 확인 필요)
  - 내려받은 그림은 아이콘·헤더 배경이 함께 쓰는 필드 하나(`f7721e0`)에 들어가, 실패하면 **직전에 받은 그림이 대신 쓰인다**. **(개선판)** 그림 없이 둠
- 버튼은 `new Button(this)`: 최소 88×48dp, 글자 14sp 굵게·대문자, 안쪽 여백 가로 12dp·세로 10dp(배경을 바꿔도 남음). 정사각형 칸 안에서는 칸 크기로 줄어든다. **(개선판)** 글자만 있는 버튼은 글자가 다 보이게
- `name`이 있으면 글자, 14sp
- 글자색: `color`가 있으면 그 색, 없으면 칸 이름이 `popup_full`일 때 흰색, 그 외 검정
- `action`이 있으면 누를 때 **버튼 JSON 전체**를 명령 처리기에 넣는다. 칸 이름이 `dialog`면 대화상자도 닫는다
  - **(재확인)** 명령을 처리한 **뒤에** 대화상자를 닫으므로, 그 명령이 띄운 새 대화상자가 바로 닫힌다. **(개선판)** 먼저 닫고 명령 처리
- 메뉴 칸 채우기:
  - I0(배열) / J0(객체 하나): 아이콘이 없으면 버튼만, 있으면 `f7680G`×`f7680G` px 칸에 넣어서
  - 메인 푸터 H0: 항목마다 가로 균등(weight 1) 가운데 정렬 칸 안에 `f7682H`×`f7682H` px 칸 + 버튼(칸 이름 `main`)
  - 팝업 푸터 L0: 같은 구조(칸 이름 `popup`)
  - 푸터 배경색·이미지·테두리 규칙은 헤더와 같음. 이미지 역시 **메인 헤더 배경**으로 감(g1 원본 버그). **(개선판)** 각자 자리에

### 5.9 대화상자

| 종류 | 레이아웃 | 내용 |
|---|---|---|
| alert (C0) | `alert_popup.xml` | 흰 10dp 둥근 박스, padding 25dp, 18dp 검은 글자 가운데, `확인` 버튼(#1b9ce8, 5dp 둥근, 흰 18sp). 닫기만 함. 바깥 터치·뒤로 취소 불가. **(개선판)** 버튼 학교 대표색, 글자는 글자 크기 설정을 따름 |
| dialog (G0) | `dialog_popup.xml` | 흰 바탕, 위아래 #aaaaaa 1dp 선, 18dp 글자(`config.message`, 없으면 "null"), 아래 `config.button[]`을 가로 균등 칸에 `f7682H`px 칸으로 E0(칸 이름 `dialog`) |
| nfc (K0) | `nfc_popup.xml` | `핸드폰을 NFC 태그보드에 가까이 대세요.` + `취소`(#7a7b7c) |
| 루팅 | 기본 AlertDialog | `루팅된 기기는 사용할 수 없습니다.` + `OK` → 앱 종료. 취소 불가. **(개선판)** 처음 한 번 안내만 |

- 공통: 이전 대화상자가 있으면 닫고 새로 띄움. 스타일 `CustomDialog`(투명 창) 위에 V()로 폭 = 화면폭 − 70dp, 배경 0.5 어둡게
- 내부 알림(Q0): `{"action":[{"command":"alert","config":{"message":"…"}}]}`를 만들어 명령 처리기에 넣음

### 5.10 URL 로드

- 공통 헤더: `User-Agent: allytte {versionName}`, `allytte-device-token`, `allytte-device-platform: android` — **loadUrl의 추가 헤더로만** 붙는다(링크 이동 등 이후 요청에는 없음). **(개선판)** 학교 주소(`ut.ac.kr`과 그 하위, http·https)일 때만 붙이고, 다른 주소는 헤더 없이 불러옴
- B0(url): 저장된 `webview`가 `"popup"`이면 팝업 웹뷰, 아니면 메인 웹뷰에 로드
- c1(url, 팝업 전용): 네트워크(와이파이·모바일) 연결이 없으면 `네트워크가 연결되어 있지 않습니다.` 알림 후 중단. **(개선판)** 팝업 안에 연결 안내. 판정은 기본 네트워크가 인터넷을 쓸 수 있는지(VPN·유선랜 포함)

### 5.11 웹뷰 설정

| | 메인 | 팝업 | 자식·손자(window.open) |
|---|---|---|---|
| JS | 켬 | 켬 | 켬 |
| 혼합 콘텐츠 | 항상 허용 | 항상 허용 | 기본 |
| 글자 크기 | 85% | 85% | 85% (개선판: 100% × 휴대폰 글자 크기(1.3배까지), 두 손가락 확대 허용) |
| DOM storage / DB | 켬 / 켬 | 켬 / 켬 | 켬 / 기본 |
| 여러 창 | 기본(끔) | 켬, JS로 창 열기 허용 | 켬 |
| useWideViewPort | 기본 | **끔** | 기본 |
| 파일 접근 | 기본 | 기본 | 모두 허용 (개선판: 모두 끔) |
| `allytteAndroid` 객체 | 있음 (개선판: 학교 주소 페이지에서만 명령을 받음) | 있음 (메인과 같음) | 없음 |
| 다운로드 | 없음 | 있음 | 있음 |
| JS alert/confirm | 안드로이드 기본 대화상자 (개선판: 팝업과 같음) | 제목 없는 AlertDialog, alert는 취소 불가·뒤로가기=확인(창은 닫히지 않음), confirm은 확인/취소 (개선판: alert도 뒤로 키로 닫힘) | 팝업과 같음 |
| 파일 선택 | 없음 | 토스트 `파일 선택창을 선택하였습니다.` 후 모든 형식 다중 선택 | 자식만 있음(손자 없음) |
| 원격 디버깅 | 켬 | 켬 | (개선판: debug 빌드에서만) |

- `allytteAndroid` 메서드: `allytteCommandHandler(json)` → 명령 처리기, `addressSave(phone)` → 연락처 추가 화면(직장 전화)
- 링크 처리:
  - 메인: `sms:`/`mailto:` → SENDTO, `tel:` → DIAL, 나머지는 웹뷰가 그대로
  - 팝업: 위 + `intent://` 실행(앱 없으면 그 패키지 마켓 페이지), `play.google.com/store/apps/details?id=` 또는 `market://details?id=` → 마켓 앱. **(개선판)** `intent://`는 브라우저처럼 정리(`BROWSABLE`, `component`·`selector` 제거)하고 예외로 꺼지지 않음
  - 자식·손자: 가로채지 않음
- 자식 웹뷰는 팝업 웹뷰와 같은 `webview_frame` 위에 꽉 차게 얹는다. 자식에서 `https://tis.ut.ac.kr/main.do` 로드가 끝나면 y0 실행. **(개선판)** 사용자 조작 없이 열린 창은 처음에 숨기고, 입력 칸이 보이거나 20초가 지나면 보임
- 자식 `window.close()` → 자식 제거, 그리고 **팝업도 닫음**(A0). 손자 `window.close()` → 손자 제거·파괴. **(개선판)** 닫힌 창만 제거·파괴하고 팝업은 남김. 내려받기만 한 창은 바로 닫음. 팝업을 바꿀 때 이전 팝업과 그 자식·손자도 파괴
- 다운로드: `Content-Disposition`에서 파일 이름을 뽑아(`attachment; filename=` 제거, `=` 뒤 마지막, 따옴표·공백·세미콜론 정리) DownloadManager로 공용 Download 폴더에 저장, 쿠키·UA 헤더 포함, 토스트 `파일이 다운로드됩니다.` 실패 시 저장 권한 요청 + 토스트 `다운로드를 위해\n권한이 필요합니다.` **(개선판)** Android 9 이하에서만 저장 권한 요청. `%`가 든 이름, `filename*=UTF-8''`, 경로·빈 이름도 처리
- 페이지 시작 → 로딩 표시, 끝 → 숨김 (모든 웹뷰)

### 5.12 팝업 닫기 A0와 상태 값

- A0: `webview="main"` 저장 후 닫기. **(개선판)** 자식·손자 창도 함께 닫음
  - `f7670B`가 false면 배경 숨기기만
  - true면 정렬별 퇴장 애니메이션(`left`/`right`/`top`/`bottom`), `center`·`full`은 바로 숨기고 `f7670B=false`
- 애니메이션 끝 처리(등장·퇴장 같은 리스너): `f7670B`가 false였으면 true로(등장 완료), true였으면 배경을 숨기고(`INVISIBLE`) false로(퇴장 완료). 오른쪽 리스너는 false였을 때 저장된 `webview`가 `"main"`이면 false 유지
- 팝업 반투명 배경을 누르면 A0
- `f7676E`는 팝업이 열릴 때 false, 메인 구성·뒤로가기로 팝업이 닫힐 때 true. **(개선판)** A0에서 닫을 때마다 true(규칙은 `lib/src/popup_state.dart`)
- **(재확인)** 애니메이션 XML은 모두 `fillAfter="true"`라 애니메이션이 붙은 뷰는 INVISIBLE·GONE이어도 그려지고 터치를 받는다(`clearAnimation()` 전까지). `left` 팝업은 닫은 뒤에도 배경과 팝업이 남아 있다가 메인 구성이나 `center`·`full` 팝업이 애니메이션을 지울 때 사라진다. ≡ 메뉴는 오른쪽에서 나오므로(통합본 3-5) 평소에는 드러나지 않는다. **(개선판)** 닫힐 때 애니메이션도 뗌
- **(재확인)** 애니메이션 시간은 처음 그려지는 프레임에서 시작한다. 숨겨진 동안 멈춰 있다가, 다시 그려질 때 이미 500ms가 지났으면 곧바로 끝 처리가 불린다(`lib/src/popup_animation.dart`)

### 5.13 뒤로가기 y0

1. 손자 웹뷰가 열려 있으면: 뒤로 갈 수 있으면 뒤로, 아니면 `window.close()` 실행하고 손자 상태 false
2. 자식도 같은 방식
3. 메인이 주인(`f7676E`)이면: 뒤로 갈 수 있으면 뒤로, 아니면 2초 안에 두 번째면 앱 종료, 처음이면 토스트 `'뒤로' 버튼을 한번 더 누르시면 종료됩니다.` **(개선판)** `webview`/`main`으로 불러온 페이지가 끝나면 방문 기록을 지워 이전 서버 페이지로 돌아가지 않음. 끝내기 전에 쿠키 저장
4. 팝업이 주인이면: 팝업이 뒤로 갈 수 있으면 뒤로, 아니면 A0 후 `f7676E=true`

### 5.14 센서·위치

- **(개선판)** 흔들기 감지는 없앴다. 위치는 `gps` 명령 때 위치 권한을 요청한다.
- 가속도(SENSOR_DELAY_NORMAL): 합력 / 9.80665 > **2.7g**이고 직전 감지에서 **500ms** 지났으면 흔들기 1회 → 흔들기 허용이면 `https://mobile.ut.ac.kr//service/api/device/gesture/shake?value=`로 POST
- 자기장 센서 처리가 가속도 분기 안에 있어 **방위각은 항상 0**
- 앱이 백그라운드로 가면 센서 해제
- `gps`: 정밀 위치 권한이 없으면 요청만 하고 0,0,0으로 보냄. 있으면 network → gps 순서로 마지막 위치를 읽음(gps가 있으면 덮어씀)
  - 주소: `config.url + String.format("&latitude=%s&longitude=%s&altitude=%s&azimuth=%s", 경도, 위도, 고도, 방위각)` — **위도 자리에 경도, 경도 자리에 위도**(원본 버그), `?` 확인 없이 `&`. **(개선판)** 주소를 형식 문자열 밖에서 붙여 `%`가 있어도 보냄(위도·경도 자리는 그대로)

### 5.15 NFC

- 메인 화면이 앞에 있는 동안 항상 foreground dispatch 켬(모든 태그)
- 기기에 NFC가 없으면 메인 시작 때 토스트 `NFC를 지원하지 않는 단말기입니다.`
- `function: nfc`: NFC가 켜져 있으면 nfc 대화상자(5.9), 꺼져 있으면 알림 `설정 화면의 NFC모드를 '기본' 또는 '읽기/쓰기'로 설정하시기 바랍니다.` 그리고 `config.url`에 `?value=`(또는 `&value=`)를 붙여 기억
- 태그를 읽으면: NDEF 메시지 첫 번째의 **세 번째 레코드** payload를 UTF-8로 읽고 첫 `s` 글자부터 잘라 trim → 비어 있지 않으면 기억한 주소(없으면 `https://mobile.ut.ac.kr//service/api/device/nfc?value=`) + 값으로 POST
- 태그 ID 16진수는 계산하지만 쓰지 않음
- 레코드가 3개보다 적으면 원본은 예외로 **앱이 종료될 수 있다.** 이식에서는 조용히 무시(사용자 결정 4)

### 5.16 비콘 (`function: beacone`)

- iBeacon 레이아웃 `m:2-3=0215,i:4-19,i:20-21,i:22-23,p:24-24`(AltBeacon)
- **(개선판)** 검색 전에 근처 기기(`BLUETOOTH_SCAN`, Android 12 이상)·정밀·대략 위치 권한 요청. 원본은 대략 위치만 있어 Android 10 이상에서 찾지 못했다
- `config.uuid` 배열과 `config.url`(+`?uuid=`/`&uuid=`) 기억 → 검색 시작 → **5초 뒤**: 찾은 비콘 중 id1이 배열의 uuid와 같은 것(뒤에 나온 것이 이김)으로 `url + id1 + "&major=" + id2 + "&major=" + id3` POST(**major가 두 번**, 못 찾으면 `null` 문자열) → 검색 중지. **(개선판)** 알림·해석기를 하나만 붙이고 멈출 때·화면이 닫힐 때 뗌

### 5.17 QR (`function: qrcode`)

- `config.url`에 `?value=`/`&value=`를 붙여 기억하고 스캔 화면을 연다(방향 고정, 삑 소리 끔)
- 화면(`activity_custom_scanner.xml`): 카메라 전체, 가운데 260dp 테두리 이미지(`qr_area.png`), 그 위 10dp에 흰 20dp 글자 `사각 테두리 안에 QR코드를\n 인식해주세요.`("QR코드"만 #03DAC5), 아래 30dp에 닫기 이미지 버튼(`btn_qr_close.png`)
- 결과: 내용이 있으면 기억한 주소 + 내용으로 POST, 취소면 토스트 `Cancelled`. **(개선판)** 한글 토스트, 열기 전에 카메라 권한 요청, 닫기 버튼은 시스템 바 위, 테두리·선은 흰색, 닫기 버튼은 학교색 원

### 5.18 루팅 확인

- 메인 시작 때 `Runtime.exec("su")`가 성공하면 루팅 대화상자(5.9). **(개선판)** su 파일만 확인하고 처음 한 번 안내

### 5.19 푸시 (FCM, data 메시지)

- 키 `title`, `body`, `url`. 알림 채널 `20005`/`ALLYTTE`(중요도 높음), 아이콘 `ic_launcher`, 누르면 IntroActivity에 `push_url`
- 토큰 갱신 시 `device.push_token` 저장
- 학교 Firebase 설정 없이는 동작 불가 — 이식하지 않음(사용자 결정 2)

### 5.20 HCE 학생증 (`CardHostApduService`)

- 매니페스트에 서비스만 있고 `BIND_NFC_SERVICE`·`HOST_APDU_SERVICE` 필터·`apduservice.xml`이 없어 **시스템이 쓸 수 없다**. 원본에서 동작한 적 없는 코드
- 참고용 AID: `F0534D4152544447554731323232`

### 5.21 일부러 그대로 둔 원본 동작

이식판은 아래를 모두 원본대로 옮겼다. 개선판(1차 후속)은 서버로 가는 값이거나 서버 페이지가 맞춰져 있을 수 있는 것만 그대로 두고 나머지는 고쳤다(이유는 IMPROVEMENTS.md 1절 "1차 후속에서 고친 것").

| 원본 동작 | 개선판 |
|---|---|
| 기기 등록의 `osVersion`/`osName` 뒤바뀜, `//service` 슬래시 두 개 | 그대로 |
| GPS 위도·경도 뒤바뀜, 방위각 항상 0 | 그대로 |
| 비콘 `major` 두 번 | 그대로 |
| 웹 페이지가 보낸 `back` 무시(5.5) | 그대로 |
| 아이콘 `align` 배치(5.8) | 그대로 |
| 헤더·푸터 `bgImage`가 모두 메인 헤더 배경으로 감 | 각자 자리에 |
| 메인 웹뷰 JS 알림창이 안드로이드 기본 대화상자 | 팝업과 같은 창 |
| 로딩 중 화면 전체 터치 막힘 | 입력을 막지 않음(통합본 3-31) |
| 글자 크기 85% 고정 | 100% × 휴대폰 글자 크기, 1.3배까지(통합본 5-1) |
| 메인 푸터 처음 "*" 버튼 | 서버 푸터 설정 전에는 푸터·구분선을 그리지 않음. 등록 실패 시 연결 안내(통합본 1-9) |
| 메인 헤더 메뉴가 배열이면 구성 중단(5.6) | 버튼을 차례로 넣음 |
| 푸터를 만들면 `f7676E=false`(5.6) | 바꾸지 않음 |
| `left` 팝업의 배경 남음(5.12) | 떼어 냄 |
| 대화상자 버튼이 새 대화상자를 닫음(5.8) | 먼저 닫고 처리 |
| 실패한 그림 대신 직전 그림(5.8) | 그림 없이 |

- 이미지(아이콘·배경)를 화면 그리는 중에 동기로 내려받는 것은 Flutter에서 비동기로 받되 결과는 같게 했다. 명령을 한 줄로 세워 처리해서, 내려받기가 끝날 때까지 다음 명령(뒤로가기 포함)이 기다린다.

---

## 6. Flutter 구현

### 6.1 구조

원본 화면 2개(IntroActivity, MainActivity)와 QR 화면을 Flutter 화면으로 옮겼다. Android 쪽 액티비티는 Flutter용 하나(`MainActivity.kt`)뿐이다. 원본에서 Android가 직접 처리하던 것(시스템 대화상자, 토스트, 인텐트, 권한, NFC, 비콘, 다운로드, 파일 선택)만 Kotlin이 같은 API로 처리하고, 채널(`kr.ac.ut.mobile.flutter/native`)로 주고받는다. 표에서 *개선판*은 개선판에만 있는 것이다.

| 파일 | 원본 | 내용 |
|---|---|---|
| `lib/main.dart` | — | 시작: 인트로 → 메인. 모든 화면을 투명 `Material`로 감쌈(6.3). 테마 강조색은 학교 대표색 |
| `lib/src/intro_screen.dart` | `IntroActivity` | 시작 이미지, 기기 등록(5.2). *개선판*: 권한을 묻지 않음, 등록 10초 제한과 연결 안내·다시 시도, `push_url`을 Dart로 다시 확인(`registerUrl`) |
| `lib/src/main_screen.dart` | `MainActivity` | 명령 처리기, 메인·팝업 구성, 메뉴·버튼, 대화상자, 로딩, 뒤로가기, NFC·비콘·QR·GPS. 메서드 옆 주석이 원본 이름(`x0`, `E0`, `i1`, …). *개선판*: 연결 안내, 기능별 권한 요청, 동영상 전체 화면, 글자 크기 변경 받기, 화면 크기 다시 재기, 사용자 조작 없이 열린 창 숨기기, 팝업을 닫거나 바꿀 때 자식·손자 창 정리(`_a0`·`_z0`), 기기 토큰이 든 공통 헤더와 POST는 학교 주소에만(`_extraHeaders`·`_post`가 `commonHeaders`·`schoolPost`를 부름) |
| `lib/src/web_entry.dart` | `X0()`/`Z0()`/`onCreateWindow` | 웹뷰 하나(메인·팝업·자식·손자) 만들기. *개선판*: 불러오기 상태 연결, 다시 시도, 방문 기록 지우기, 웹 글자 크기(`textZoomFor`) |
| `lib/src/page_load.dart` | — | *개선판*: 웹뷰 하나의 불러오기 상태(로딩 표시, 10초 지연·실패 안내, 다시 시도, 방문 기록 지우기 시점, 내려받기만 한 창 닫기) |
| `lib/src/connection_notice.dart` | — | *개선판*: 연결 실패·지연 안내 화면 |
| `lib/src/offline_banner.dart` | — | *개선판*: 앱을 쓰는 동안 인터넷이 끊기면 홈 맨 위 안내 띠(`OfflineBanner`), 잠깐 끊김을 거르는 `OfflineTracker`. Kotlin `networkChanged`를 받음 |
| `lib/src/school_url.dart` | — | *개선판*: 기기 토큰을 보내도 되는 학교 주소인지(`isSchoolUrl`, 이미 읽은 주소는 `isSchoolUri`). `WebViewBridge.kt` `isSchoolPage`와 같은 규칙이지만, 웹뷰가 정리하기 전의 명령 문자열을 Dart `Uri`로 읽으므로 사용자 정보(`@` 앞)가 있거나, 호스트(대문자는 소문자로 바뀜)에 영문 소문자·숫자·`.`·`-` 밖의 글자(`%XX`로 남은 것이나 `_`·`!` 같은 기호)가 있으면 학교 주소로 보지 않음 |
| `lib/src/app_colors.dart` | `colors.xml` | *개선판*: Figma 색 토큰 `AppColors`, 학교 대표색 `schoolColor`(= primary, Android `colors.xml`의 `school`과 같은 값) |
| `lib/src/popup_animation.dart` | `res/anim`, 애니메이션 리스너 | 옛 Android 애니메이션 규칙(5.12), 정렬별 팝업 크기(`popupSizePx`) |
| `lib/src/popup_state.dart` | `f7670B`·`f7672C`·`f7676E`, A0 | 팝업 보임 상태와 뒤로가기 주인(5.7·5.12) |
| `lib/src/legacy_widgets.dart` | 레이아웃 XML, `RoundedWebView` | 버튼, 로딩 표시, 웹뷰 모서리, alert·dialog·nfc 대화상자, `SquareSlot`, `BarTextScale`, `BoxBackground` |
| `lib/src/legacy_json.dart` | `org.json` | 같은 예외 규칙, Android `toString()` 직렬화 |
| `lib/src/android_color.dart` | `Color.parseColor` | |
| `lib/src/allytte_http.dart` | `i2.a`, 내려받기 스레드 | POST 도우미(5.3, *개선판*: 리디렉트는 학교 주소로만 `nextRedirect`. 학교 주소에만 붙이는 공통 헤더 `commonHeaders`와 결과 POST `schoolPost`), 아이콘·시작 이미지 내려받기(*개선판*: 아이콘은 연결 3초·전체 10초 제한) |
| `lib/src/device_prefs.dart` | SharedPreferences `"device"` | |
| `lib/src/qr_scan_screen.dart` | `ZxingActivity` | 같은 배치, 인식은 mobile_scanner(ML Kit). *개선판*: 테두리·닫기 버튼을 코드로 그림 |
| `lib/src/native_bridge.dart` | — | Kotlin 채널. *개선판*: 기능별 권한 요청(`requestFeaturePermission`) |
| `android/.../MainActivity.kt` | 두 액티비티의 Android 부분 | 권한, 시스템 대화상자, 토스트, 인텐트, NFC, GPS, AltBeacon, 파일 선택 결과. *개선판*: `pushUrlOf`, `launchPackage`, `gpsUrl`, `isNetworkConnected`, 비콘 알림 정리, 종료 전 쿠키 저장(`exitApp`), 연결 상태 알림(`watchNetwork`) |
| `android/.../WebViewBridge.kt` | WebView 설정·클라이언트 | 원본 설정값, `allytteAndroid`, 링크 처리, 다운로드, `window.open`·`window.close`, JS 알림창, 파일 선택. *개선판*: 글자 크기·확대, `webEvent`, 방문 기록 지우기, `sanitizeBrowsable`, `isSchoolPage`, 자식·손자 파일 접근 끔, `downloadFileName` |
| `tool/make_launcher_icons.py` | `assets/app_icon_1024.png` | *개선판*: 런처 아이콘 만들기 |

2차의 하단 탭과 새 화면 파일, Material 3 테마(`app_theme.dart`)는 2026-10-29에 뺐다(커밋 `ea31d1b`에 있음).

### 6.2 웹뷰

- `webview_flutter`(공식)로 만들고, `WebViewFlutterAndroidExternalApi`로 네이티브 WebView를 받아 원본과 같은 설정과 객체를 붙인다. 그래서 웹 페이지는 원본처럼 `allytteAndroid.allytteCommandHandler(json)`을 그대로 부른다.
- 플러그인이 생성자에서 바꾸는 기본값(확대 버튼, overview 모드, 여러 창)은 Android 기본값으로 되돌린 뒤 원본 값을 입힌다.
- 링크 처리·새 창·JS 알림창은 플러그인 클라이언트를 감싸서 처리한다. 페이지 시작·끝은 Dart로 넘어가 로딩 표시를 켜고 끈다.
  - 개선판: 플러그인이 넘기지 않는 이벤트(`navigate`, `committed`, `visible`, `download`)를 Kotlin이 `webEvent`로 보낸다(`page_load.dart`).
  - 개선판: 동영상 전체 화면은 `setCustomWidgetCallbacks`로 메인 화면이 띄운다.
- `window.open`은 Kotlin이 요청을 붙잡아 두고 Dart가 새 웹뷰를 만든 뒤 연결한다. 자식·손자 창은 팝업 웹뷰와 같은 틀에 쌓인다.
- 주소 불러오기는 원본처럼 네이티브 `loadUrl(url, 헤더)`에 문자열을 그대로 넘긴다.
  - 개선판: 공통 헤더(5.10)는 학교 주소일 때만 넘기고, 다른 주소에는 빈 헤더를 넘긴다(`school_url.dart`, IMPROVEMENTS.md 13절).
- `flutter_inappwebview`는 2024년 이후 출시가 없고 AGP 9에서 빌드가 깨져서 쓰지 않았다.

### 6.3 화면 모양

- Kotlin이 띄우는 시스템 대화상자(JS 알림, 권한 안내, 루팅)는 원본처럼 AppCompat 테마다. 버튼 색은 colorAccent(원본 #03dac5, 개선판 #A3162B).
- Flutter가 그리는 부분(헤더·푸터 버튼, 대화상자, 로딩 표시)은 원본 XML 크기·색을 dp 그대로 옮겼다. 글꼴만 다를 수 있다. 개선판은 대화상자 글자도 휴대폰 글자 크기 설정을 따른다.
- 모든 화면은 `MaterialApp.builder`에서 투명 `Material`로 감싼다(`SmartMobileApp.wrapScreens`). 감싸기 전에는 글자가 노란 이중 밑줄·monospace·w900으로 나왔다(`test/text_style_test.dart`).
- 앱 화면 크기(`Display.getSize`)는 창 크기에서 상태 표시줄과 내비게이션 바를 뺀 값이다.

### 6.4 원본과 다른 점

| 항목 | 원본 | 이식 | 이유 |
|---|---|---|---|
| 패키지 | `kr.ac.ut.mobile` | `kr.ac.ut.mobile.flutter` | 사용자 결정 1. 개선판은 `kr.ac.ut.mobile.renewal` |
| 버전 | 1.1.3(19) | 1.1.3(19) | 서버에 `appVersion`·User-Agent로 보내므로 같게 둠 |
| 푸시(FCM), HCE | 있음 | 없음 | 사용자 결정 2, 3. `push_url` 흐름은 남김 |
| 앱이 예외로 종료되는 경우 | 종료 | 무시 | 사용자 결정 4: NFC 레코드 3개 미만, uuid 목록 없이 끝난 비콘 검색, 처리할 앱이 없는 `tel:`/`sms:`/`mailto:`, 패키지 없는 `intent://` |
| 시작 화면 배경, 앱 아이콘 | split APK 그림 | 흰 화면, Flutter 기본 아이콘 | 그림이 없음. 개선판 아이콘은 `assets/app_icon_1024.png`로 만듦 |
| `app_icon_1024.png` → `intro.png` 복사 | 있음 | 없음 | 보이지 않는 이미지뷰에만 쓰임 |
| QR 인식 | ZXing | ML Kit(mobile_scanner) | 배치·안내 글·닫기·"Cancelled"는 같음. 인식 점 표시는 없음 |
| minSdk / targetSdk | 23 / 35 | 24 / 36 | Flutter 3.47 기본값 |
| Android 7.x(API 24–25) | — | 링크 처리·새 창·JS 알림창 감싸기 생략 | 현재 클라이언트를 읽는 API가 8.0부터. 개선판의 웹뷰 이벤트·확대 스크립트·메인 JS 알림창 모양도 7.x에서는 빠진다 |
| 팝업 웹뷰 모서리 | 하드웨어 레이어에 지우기 | Flutter에서 잘라내기 | 같은 모양(4000px 규칙 포함) |

---

## 7. 클라우드 세션 Setup script

지금은 로컬에서만 작업해서 쓰지 않는다. 스크립트 전문과 실행 기록은 [HANDOFF.bak.md](HANDOFF.bak.md) 7장. 첫 `flutter build apk --debug`는 NDK·CMake를 내려받느라 7분 남짓 걸린다.

---

## 8. 실기기 확인 목록 (SM-F741N)

> 이식판 기준 목록이다. 개선판 확인 목록은 IMPROVEMENTS.md 9절. 1번(권한), 3번(0.5초), 5번(로딩 중 막힘), 9번(흔들기), 11번(첫 뒤로 키)은 개선판에서 바뀌었다.

원본 앱과 나란히 설치되므로 같은 화면을 두 앱에서 번갈아 열어 비교한다. *(에뮬레이터)* 표시는 에뮬레이터에서 확인한 항목이고, 실기기에서도 다시 본다.

```
flutter run          # 또는 flutter build apk --debug 후 adb install
```

1. 첫 실행: 권한 요청 6개 → 모두 허용하면 메인으로. 하나라도 거부하면 토스트 + "[…]권한을 추가해 주세요." 대화상자 *(에뮬레이터)*
2. 메인: 헤더·하단 바의 아이콘 크기와 위치, 헤더 아래 1dp 선, 하단 바 위 회색 선
3. 하단 바 버튼과 ≡ 메뉴: 팝업이 오른쪽에서 밀려 들어오고(0.5초), 배경을 누르거나 뒤로 키로 닫힘 *(에뮬레이터)*
4. 팝업 모서리(가운데·아래 정렬 팝업), 팝업 헤더·푸터
5. 로딩 중 회전 이미지, 로딩 중에는 터치와 뒤로 키가 막힘 *(에뮬레이터)*
6. 팝업 안에서 새 창이 열리는 메뉴와 그 창의 뒤로가기·닫기 *(에뮬레이터: 학사 항목은 팝업 안에서 열림, 새 창은 ECAMPUS·공지 첨부에서 열림)*
7. 파일 내려받기, 파일 선택, `tel:` 링크, 외부 브라우저로 열리는 메뉴(포탈, 전자출결) *(에뮬레이터)*
8. 대표홈페이지 등 JS 알림창이 뜨는 화면
9. 흔들기, NFC(태그보드), QR, 위치를 쓰는 메뉴
10. 앱이 꺼진 상태·백그라운드 상태에서 NFC 태그(text/plain)를 대면 시작 화면부터 다시 진행
11. 메인에서 뒤로 키: 푸터가 있는 화면이면 첫 번째는 반응 없음(5.6), 그다음 종료 토스트 → 2초 안에 다시 누르면 종료 *(에뮬레이터)*
12. 글자 모양: full 팝업 헤더 제목(`로그인`, `교내전화`), 헤더·푸터 버튼 글자, alert·dialog 메시지에 노란 밑줄이 없고 보통 굵기인지(6.3) *(에뮬레이터)*
