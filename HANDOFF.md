# 인계 문서 — 기존 스마트모바일 앱을 Flutter로 1:1 이식

> 작성: 2026-10-26, 로컬 Claude Code 세션에서 클라우드 세션으로 넘기기 위해 작성
> 이 문서만 읽고 바로 이어서 작업할 수 있도록, 원본 코드를 읽으며 확인한 동작 규칙을 모두 적었다.

---

## 1. 할 일

`한국교통대학교 스마트모바일_1.1.3.apk`(패키지 `kr.ac.ut.mobile`, versionCode 19)의
**Java로 된 앱 부분(네이티브 껍데기)을 Flutter/Dart로 그대로 옮긴다.**

- 사용자 결정(2026-10-26): **"기능 추가 및 개선점 반영 없이 순수하게 플러터 프로젝트로만 변환"**
  - 방식은 "앱 껍데기 그대로 이식"으로 확정. 화면 내용은 지금처럼 `mobile.ut.ac.kr` 학교 웹 페이지를 띄운다.
  - 화면을 위젯으로 다시 그리는 방식은 **선택하지 않았다.**
  - 교통·학식 탭, 길찾기(`mockups/`)는 **새 기능이라 이번 범위가 아니다.** UI/UX 개선점 목록도 반영하지 않는다.
- 배경: 모바일프로그래밍 수업 4인 팀 프로젝트(기존 앱 UI/UX 개선). 이 작업은 그중 "기존 앱을 Flutter로 옮겨 놓는" 출발점이다. 마감 2026-12-15.

### 현재 상태

- **분석 완료, Flutter 코드는 아직 한 줄도 없다.**
- 원본 디컴파일 코드와 리소스는 `docs/legacy/`에 있다(아래 3장).

### 아직 정하지 않은 것 (사용자에게 확인 필요)

1. **applicationId**: 원본과 같은 `kr.ac.ut.mobile`로 하면 원본 앱이 깔린 폰에 서명 충돌로 설치되지 않는다. 다른 이름(예: `kr.ac.ut.mobile.flutter`)을 쓸지 물어볼 것.
2. **푸시(FCM)**: 학교 Firebase 설정 파일(`google-services.json`)이 없어 동작할 수 없다. 코드만 옮길지, 빼고 문서에만 남길지.
3. **HCE 학생증 서비스**: 원본에서도 매니페스트 등록이 빠져 한 번도 동작하지 않은 죽은 코드다(5.20). 옮기지 않는 것을 제안.
4. **원본의 강제 종료 동작**: 레코드가 3개 미만인 NFC 태그를 읽으면 원본은 예외로 종료될 수 있다(5.15). 그대로 재현할지, 무시하고 넘어갈지.
5. **시작 화면 배경 이미지**: 해상도별 split APK에만 있어 저장소에 없다(5.2). 사용자 폰에서 꺼내야 한다.

---

## 2. 개발 환경 (사용자 PC 기준)

| 항목 | 값 |
|---|---|
| Flutter | 3.47.2 stable (`E:\flutter`), Dart 3.13.2 |
| Android SDK | `E:\AndroidSDK` (adb: `E:\AndroidSDK\platform-tools\adb.exe`) |
| 시험 폰 | SM-F741N (원본 앱 설치됨). 작성 시점에는 연결 안 됨 |
| 디컴파일러 | jadx 1.5.6 (로컬 임시 폴더, 저장소에는 없음) |

클라우드 세션에서는 실기기 시험이 안 된다. `flutter analyze`, 빌드까지만 확인하고 실기기 확인은 사용자 PC에서 한다.

---

## 3. 저장소 안 자료

| 경로 | 내용 |
|---|---|
| `한국교통대학교 스마트모바일_1.1.3.apk` | 원본 APK (base APK만. 해상도별 split APK는 없음) |
| `docs/legacy/src/` | jadx로 복원한 앱 코드 전부(7개 클래스 + HTTP 도우미). 디컴파일러 주석은 지웠다 |
| `docs/legacy/res/` | 이식에 필요한 레이아웃·도형·애니메이션·문자열·이미지 |
| `docs/legacy/AndroidManifest.xml` | 리소스 이름이 풀린 매니페스트 |
| `mockups/` | 다른 작업(교통·학식·길찾기 개선안) 목업. **이번 작업과 무관** |

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
| `h2.c.f7356a` (0x7f07008a) | drawable `ic_launcher` — **xxhdpi split APK에만 있어 저장소에 없음** |
| `h2.f.f7392a` / `f7393b` / `f7394c` / `f7395d` | string `app_close` / `nfc_detail` / `nw_not_conn` / `qr_guide` |
| `h2.g.f7396a` | style `CustomDialog` |

`MainActivity`의 주요 필드:

| 필드 | 뜻 |
|---|---|
| `f7692M` | 메인 웹뷰 |
| `f7714X` | 팝업 웹뷰(`RoundedWebView`) |
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
| `f7833u` | 로딩 표시 Dialog |
| `f7832t` | 알림·대화상자 Dialog |

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

- MainActivity는 `singleTask`다. 앱이 떠 있을 때 푸시를 누르면 IntroActivity가 `push_url`로 POST한 뒤 MainActivity를 다시 부르고, 기존 MainActivity의 `onNewIntent`가 `screen_info`를 받아 명령 처리기에 넣는다(새 화면을 만들지 않음).

---

## 5. 동작 규칙 (원본 코드 기준)

### 5.1 공통 부모 (`BaseActivity_a.java`)

- 저장소: SharedPreferences 이름 `"device"`, 키 `device_token`, `push_token`, `splash_url`, `webview`(`"main"`/`"popup"`)
- `O()` = versionName. `N(dp)` = dp→px
- 상태바: 흰 바탕 + 어두운 아이콘(`AppTheme.NoActionBar`, `SYSTEM_UI_FLAG_LIGHT_STATUS_BAR`). 내용은 시스템 바 영역만큼 안쪽 여백을 준다.
- 화면 방향: 인트로·메인 모두 세로 고정
- 언어 설정(`Y()`)은 기본 리소스가 한국어뿐이라 결과에 영향 없음 → 옮기지 않아도 됨
- `V(dialog)`: 대화상자 폭 = 화면폭 − 70dp, 높이 wrap, 배경 어둡게 0.5

### 5.2 시작 화면 (`IntroActivity.java`)

- 레이아웃: 배경 drawable `0x7f0700f2`(**xxhdpi split APK에만 있어 저장소에 없음**). `iv_intro` 이미지뷰는 `gone`이라 실제로 보이는 건 배경뿐이다.
  - 사용자 폰에서 split APK를 꺼내면 구할 수 있다: `adb shell pm path kr.ac.ut.mobile` → `split_config.xxhdpi.apk` pull.
- 푸시로 열렸으면 `push_url` extra를 기억한다.
- 권한(모두 허용돼야 다음으로):

| SDK | 요청 권한 |
|---|---|
| 33 이상 | READ_PHONE_NUMBERS, CALL_PHONE, CAMERA, ACCESS_COARSE_LOCATION, POST_NOTIFICATIONS, NEARBY_WIFI_DEVICES |
| 30~32 | READ_PHONE_NUMBERS, WRITE/READ_EXTERNAL_STORAGE, CALL_PHONE, CAMERA, ACCESS_COARSE_LOCATION |
| 29 이하 | READ_PHONE_STATE, WRITE/READ_EXTERNAL_STORAGE, CALL_PHONE, CAMERA, ACCESS_COARSE_LOCATION |

- 이미 모두 허용 상태: `splash_url`이 저장돼 있으면 그 이미지를 `intro.png`로 받은 뒤 기기 등록, 없으면 바로 기기 등록
- 권한 결과: 하나라도 거부 → 토스트 `권한이 거부되었습니다. 해당권한을 허용하셔야 합니다.` → (SDK 29 이상) 제목 없는 대화상자 `[전화,카메라]권한을 추가해 주세요.` + `OK` 버튼(앱 설정 화면 열고 종료), 취소 불가 / (28 이하) 그냥 종료
  - 라벨 규칙(권한 이름에 포함된 단어 순서대로 검사): PHONE→전화, MEDIA→사진및동영상,카메라, CAMERA→카메라, ACCESS→위치, NOTIFICATION→알림, NEARBY→근처기기, STORAGE→파일및미디어, 그 외 기타. 중복 제거, 쉼표로 이음
  - 모두 허용 → 바로 기기 등록(이 경로에서는 splash 내려받기 안 함)
- 기기 등록:
  - `device_token` 없으면 `UUID.randomUUID().toString().toUpperCase()` 생성·저장
  - 주소(**순서·값 그대로**):
    ```
    https://mobile.ut.ac.kr//service/api/device/save
      ?devicePlatform=android&modelName={Build.MODEL}&deviceToken={token}
      &osVersion={Build.VERSION.SDK_INT}&osLang={Locale.getDefault().getLanguage()}
      &osName={Build.VERSION.RELEASE}&appVersion={versionName}&pushToken={push_token}&siteId=0
    ```
    (주의: osVersion에 SDK 번호, osName에 버전 문자열이 들어간다. 원본 그대로. 슬래시 두 개도 그대로)
  - `push_url`이 있으면 위 주소 대신 `push_url`로 POST
  - 응답(5.3)을 받는 즉시 MainActivity를 열고 인트로는 종료

### 5.3 POST 도우미 (`RequestHttpURLConnection_i2a.java`)

- 방식 POST, 본문 없음, 연결 제한 3초(읽기 제한 없음)
- 헤더: `User-Agent: allytte {versionName}`, `allytte-device-token: {token}`, `allytte-device-platform: android`
- 200이면 본문, 아니면 오류 본문을 읽어 JSON으로 파싱하고 `"urlConnResult": 응답코드`를 추가해 문자열로 돌려준다
- 어떤 예외든 `null`을 돌려준다(→ 명령 처리기는 null이면 아무것도 안 함)
- 모든 호스트 이름 검증을 통과시키는 HostnameVerifier가 있지만 실제로 연결에 쓰이지는 않는다

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
│  └ main_footer: 높이 50dp, 흰 배경. 처음엔 "*" 버튼 하나가 들어 있다
│     (서버가 푸터를 보내면 지워지고 바뀐다. 오프라인이면 "*"만 보임 — 사용자 확인)
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

- 메뉴 버튼 칸 크기 `f7680G`/`f7682H`는 **px 단위** 100/110. 화면 높이(dp)가 750 이상이면 80/90.
- 로딩 표시(`progress.xml`): 투명 Dialog, 화면 가운데 38dp 회전 이미지(`loading01.png`), 취소 불가. 페이지 시작 때 보이고 끝날 때 숨긴다.
  - 원본은 이 Dialog가 화면 전체 터치를 막아 로딩 중에는 뒤로가기·닫기가 안 먹는다(사용자 실기기 확인). 이식에서도 같은 동작.

### 5.5 명령 처리기 `x0(json)`

1. null·빈 문자열이면 무시
2. 문자열 안의 `https://www.allytte.com`과 `http://allytte.com`을 `https://mobile.ut.ac.kr/`로 바꾼다
3. `{"action":[…]}` 배열을 앞에서부터 실행. 파싱 실패 등 예외는 조용히 무시(이후 항목도 중단)

| command | 처리 |
|---|---|
| `webview` | `config.show`: `main` → 메인 구성(5.6) 후 `webview="main"` 저장 / `popup` → 팝업 구성(5.7) 후 `webview="popup"` / `change` → 현재 주인 웹뷰에 `config.url` 로드(5.10) |
| `alert` | `config.message` 알림창(5.9) |
| `dialog` | 버튼 대화상자(5.9) |
| `function` | 아래 표 |
| `browser` | 팝업 닫기(A0) 후 외부 브라우저로 `config.url` |
| `app` | `config.contentUrl`을 패키지 이름으로 보고 실행 시도, 없으면 `config.storeUrl`을 외부로 열기 |
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
| `url` | `config.url`로 POST(5.3) → 응답을 다시 명령 처리기에 넣음 |

"POST 후 응답을 명령 처리기에 넣는다"(`O0`)는 NFC·GPS·흔들기·비콘·QR·url 모두 공통이다.

### 5.6 메인 웹뷰 구성 (`webview`/`main`, 클래스 `w`)

1. `f7676E = true`. 팝업이 열려 있으면(`f7670B`) 닫기(A0). 팝업 애니메이션 취소
2. `config.setting.gesture`가 없으면 흔들기 허용 true, 있으면 그 값
3. `config.header`가 없으면 메인 헤더 숨김. 있으면:
   - `bgColor`: 문자열 `"null"` → 흰색, `"transparent"` → 투명, 그 외 색상 코드
   - `bgImage`가 `"null"`이 아니면 그 이미지를 받아 **메인 헤더 배경**으로(5.8 참고)
   - `border`: `"null"` → 테두리 없음, 숫자 → 그 dp 두께 검은 테두리
   - `menu.left`/`center`/`right`: 없으면 그 칸 숨김. 있으면 칸을 비우고 버튼 추가(객체 하나면 J0, 배열이면 I0 / 5.8). 칸 이름 `main_left`·`main_center`·`main_right`
4. `config.footer`가 없으면 푸터와 구분선 숨김. 있으면 둘 다 보이고 푸터 구성(H0)
5. `config.url`을 헤더와 함께 로드(5.10)

### 5.7 팝업 웹뷰 구성 (`webview`/`popup`, 클래스 `RunnableC0257a`)

> jadx 결과가 이 부분에서 분기가 중복·뒤틀려 있다. 아래는 바이트코드 흐름을 따라 정리한 실제 동작이다.

1. `f7676E = false`, `f7670B = false`, 팝업 웹뷰를 **새로 만들어 교체**(Z0, 5.11)
2. `config.align`, `config.url`, `config.header`, `config.footer` 읽기. 흔들기 설정은 메인과 같음. `f7672C = align`
3. 정렬별 팝업 크기와 등장(화면 크기는 `Display.getSize`):

| align | 위치(gravity) | 폭 × 높이 | 등장 |
|---|---|---|---|
| `left` | 왼쪽 | 화면폭×0.8 × 꽉 | 왼쪽에서 밀려 들어옴 |
| `right` | 오른쪽 | 화면폭×0.8 × 꽉 | 오른쪽에서 |
| `top` | 위 가운데 | 꽉 × 화면높이×0.8 | 위에서 |
| `bottom` | 아래 가운데 | 꽉 × 화면높이×0.8 | 아래에서 |
| `center` | 가운데 | 화면폭×0.8 × 화면높이×0.8 | 애니메이션 없이 바로, `f7670B=true` |
| `full` | 가운데 | 꽉 × 꽉 | 애니메이션 없이 바로, `f7670B=true` |

   - 애니메이션: 500ms, accelerate_decelerate, `%p` 기준 이동(`docs/legacy/res/anim`)
   - `left`만 등장 애니메이션을 팝업 본체가 아니라 **반투명 배경 전체(`f7694N`)**에 건다(배경까지 같이 밀려 들어옴). 퇴장은 다른 정렬처럼 본체(`f7708U`)에 건다. 원본 그대로
4. 팝업 헤더 숨김 후, `config.header`가 없으면 모서리 규칙(i1)만 적용. 있으면:
   - 배경색 규칙은 메인과 같고, `transparent`일 때만 i1의 마지막 인자가 true
   - 모서리 규칙(i1, 5.7.1) 적용, `bgImage`는 **메인 헤더** 배경으로 감(원본 버그 그대로), 테두리 규칙 같음
   - `align=="full"`이면 `sub_head_container` 보이고 `sub_center_container` 배경을 `round_head_title`(#333333)로, 아니면 `sub_head_container` 숨기고 가운데 칸 배경 투명. `sub_head2_container`는 항상 숨김
   - `menu.left`/`center`/`right`: 배열이 있고 길이 > 0이면 칸을 보이고 I0로 버튼 추가(칸 이름 `popup_left`, 가운데는 full이면 `popup_full` 아니면 `popup_center`, `popup_right`). 하나라도 있으면 팝업 헤더를 보임
5. `config.footer`가 없으면 팝업 푸터 숨김, 있으면 보이고 L0로 구성
6. 팝업 웹뷰에 `javascript:document.clear();document.open();document.close();`를 먼저 실행한 뒤 `config.url`을 c1로 로드(5.10)

#### 5.7.1 모서리 규칙 `i1(align, header, footer, 헤더투명)`

먼저 팝업 헤더 배경 모서리 = 위쪽 30dp, 팝업 몸통 padding 0. 그다음 align별로(헤더·푸터는 문자열 `"null"` 여부):

- `bottom`
  - 헤더·푸터 둘 다 없음 → 웹뷰 위쪽 두 모서리만 둥글게
  - 헤더만 → 헤더 위쪽 30dp. 헤더 투명이면 웹뷰 위쪽 둥글게, 아니면 웹뷰 모서리 없음
  - 푸터만 → 웹뷰 위쪽 둥글게, 팝업 푸터 모서리 없음
  - 둘 다 → 헤더 위쪽 30dp, 푸터 모서리 없음. 헤더 투명이면 웹뷰 위쪽 둥글게, 아니면 없음
- `center`
  - 둘 다 없음 → 웹뷰 네 모서리 둥글게
  - 헤더만 → 헤더 위쪽 30dp. 헤더 투명이면 네 모서리, 아니면 아래쪽 두 모서리만
  - 푸터만 → 팝업 몸통 위 padding 30dp, 푸터 아래쪽 30dp
  - 둘 다 → 헤더 위쪽, 푸터 아래쪽 30dp. 헤더 투명이면 웹뷰 위쪽만, 아니면 없음
- `top`
  - 둘 다 없음 → 웹뷰 아래쪽 두 모서리
  - 헤더 있음 → 헤더 모서리 없음, 웹뷰 아래쪽 두 모서리
  - 푸터만 → 푸터 아래쪽 30dp
- 그 외(`left`·`right`·`full`) → 헤더·푸터·웹뷰 모두 모서리 없음

웹뷰 모서리 반지름은 15dp(`RoundedWebView`). 순서는 (왼위, 오위, 오아래, 왼아래).
1번에서 팝업 웹뷰를 새로 만들기 때문에 **기본값은 네 모서리 모두 둥글다.** 위 규칙에서 웹뷰 모서리를 언급하지 않은 경우(`center` 푸터만, `top` 푸터만)는 네 모서리가 둥근 채로 남는다.

### 5.8 버튼 만들기 (E0)와 메뉴 칸

- 버튼 하나(JSON): `icon`, `name`, `align`, `color`, `action`. 값이 없으면 문자열 `"null"`로 취급
- `icon`이 없으면 배경 투명. 있으면 이미지를 **동기로 내려받아**(스레드 join) `align`별 배치:
  - `null` → 버튼 배경 전체를 이미지로
  - `left`/`top`/`right`/`bottom` → 그쪽에 아이콘(compound drawable, 원본 크기), 그쪽 padding 30dp
  - 참고: `setCompoundDrawables`에 bounds 없는 drawable을 넘겨서 실제로는 아이콘이 안 보일 수 있다(원본 동작 그대로 확인 필요)
- `name`이 있으면 글자, 14sp
- 글자색: `color`가 있으면 그 색, 없으면 칸 이름이 `popup_full`일 때 흰색, 그 외 검정
- `action`이 있으면 누를 때 **버튼 JSON 전체**를 명령 처리기에 넣는다(`{"action":[…]}` 구조이므로 그대로 실행됨). 칸 이름이 `dialog`면 대화상자도 닫는다
- 메뉴 칸 채우기:
  - I0(배열) / J0(객체 하나): 아이콘이 없으면 버튼만, 있으면 `f7680G`×`f7680G` px 칸에 넣어서
  - 메인 푸터 H0: 항목마다 가로 균등(weight 1) 가운데 정렬 칸 안에 `f7682H`×`f7682H` px 칸 + 버튼(칸 이름 `main`)
  - 팝업 푸터 L0: 같은 구조(칸 이름 `popup`)
  - 푸터 배경색·이미지·테두리 규칙은 헤더와 같음. 이미지 역시 **메인 헤더 배경**으로 감(g1 원본 버그)

### 5.9 대화상자

| 종류 | 레이아웃 | 내용 |
|---|---|---|
| alert (C0) | `alert_popup.xml` | 흰 10dp 둥근 박스, padding 25dp, 18dp 검은 글자 가운데, `확인` 버튼(#1b9ce8, 5dp 둥근, 흰 18sp). 버튼은 닫기만 함. 바깥 터치·뒤로 취소 불가 |
| dialog (G0) | `dialog_popup.xml` | 흰 바탕, 위아래 #aaaaaa 1dp 선, 18dp 글자(`config.message`, 없으면 "null"), 아래 `config.button[]`을 가로 균등 칸에 `f7682H`px 칸으로 E0(칸 이름 `dialog`) |
| nfc (K0) | `nfc_popup.xml` | `핸드폰을 NFC 태그보드에 가까이 대세요.` + `취소`(#7a7b7c) |
| 루팅 | 기본 AlertDialog | `루팅된 기기는 사용할 수 없습니다.` + `OK` → 앱 종료. 취소 불가 |

- 공통: 이전 대화상자가 있으면 닫고 새로 띄움. 스타일 `CustomDialog`(투명 창, 배경 어둡게 안 함) 위에 V()로 폭 = 화면폭 − 70dp, 배경 0.5 어둡게
- 내부 알림(Q0): `{"action":[{"command":"alert","config":{"message":"…"}}]}`를 만들어 명령 처리기에 넣음

### 5.10 URL 로드

- 공통 헤더: `User-Agent: allytte {versionName}`, `allytte-device-token`, `allytte-device-platform: android` — **loadUrl의 추가 헤더로만** 붙는다. 웹뷰의 기본 User-Agent 설정은 바꾸지 않는다(링크 이동 등 이후 요청에는 이 헤더가 없다)
- B0(url): 저장된 `webview`가 `"popup"`이면 팝업 웹뷰, 아니면 메인 웹뷰에 로드
- c1(url, 팝업 전용): 네트워크(와이파이·모바일) 연결이 없으면 `네트워크가 연결되어 있지 않습니다.` 알림 후 중단

### 5.11 웹뷰 설정

| | 메인 | 팝업 | 자식·손자(window.open) |
|---|---|---|---|
| JS | 켬 | 켬 | 켬 |
| 혼합 콘텐츠 | 항상 허용 | 항상 허용 | 기본 |
| 글자 크기 | 85% | 85% | 85% |
| DOM storage / DB | 켬 / 켬 | 켬 / 켬 | 켬 / 기본 |
| 여러 창 | 기본(끔) | 켬, JS로 창 열기 허용 | 켬 |
| useWideViewPort | 기본 | **끔** | 기본 |
| 파일 접근 | 기본 | 기본 | 모두 허용 |
| `allytteAndroid` 객체 | 있음 | 있음 | 없음 |
| 다운로드 | 없음 | 있음 | 있음 |
| JS alert/confirm | **안드로이드 기본 대화상자**(크롬 클라이언트를 두 번 설정해서 콘솔 로그용만 남음) | 제목 없는 AlertDialog, alert는 취소 불가·뒤로가기=확인, confirm은 확인/취소 | 팝업과 같음 |
| 파일 선택 | 없음 | 토스트 `파일 선택창을 선택하였습니다.` 후 모든 형식 다중 선택 | 자식만 있음(손자 없음) |
| 원격 디버깅 | 켬 | 켬 | |

- `allytteAndroid` 객체 메서드: `allytteCommandHandler(json)` → 명령 처리기, `addressSave(phone)` → 연락처 추가 화면(직장 전화)
- 링크 처리:
  - 메인: `sms:`/`mailto:` → SENDTO, `tel:` → 전화 걸기 화면(DIAL), 나머지는 웹뷰가 그대로
  - 팝업: 위 + `intent://` 실행(앱 없으면 그 패키지 마켓 페이지), `play.google.com/store/apps/details?id=` 또는 `market://details?id=` → 마켓 앱
  - 자식·손자: 가로채지 않음
- 자식 웹뷰는 팝업 웹뷰와 같은 FrameLayout(`webview_frame`) 위에 꽉 차게 얹는다. 자식에서 `https://tis.ut.ac.kr/main.do` 로드가 끝나면 뒤로가기 처리(y0) 실행
- 자식 `window.close()` → 자식 제거, 그리고 **팝업도 닫음**(A0). 손자 `window.close()` → 손자 제거·파괴
- 다운로드: `Content-Disposition`에서 파일 이름을 뽑아(`attachment; filename=` 제거, `=` 뒤 마지막, 따옴표·공백·세미콜론 정리) DownloadManager로 공용 Download 폴더에 저장, 쿠키·UA 헤더 포함, 토스트 `파일이 다운로드됩니다.` 실패 시 저장 권한 요청 + 토스트 `다운로드를 위해\n권한이 필요합니다.`
- 페이지 시작 → 로딩 표시, 끝 → 숨김 (메인·팝업·자식·손자 모두)

### 5.12 팝업 닫기 A0와 상태 값

- A0: `webview="main"` 저장 후 닫기 실행
  - `f7670B`가 false면 배경 숨기기만
  - true면 정렬별 퇴장 애니메이션(`left`/`right`/`top`/`bottom`), `center`·`full`은 바로 숨기고 `f7670B=false`
- 애니메이션 끝 처리(같은 리스너가 등장·퇴장 모두에 붙어 있음): `f7670B`가 false였으면 true로(=등장 완료), true였으면 배경을 숨기고(`INVISIBLE`) false로(=퇴장 완료). 오른쪽 리스너는 false였을 때 저장된 `webview`가 `"main"`이면 false 유지
- 팝업 반투명 배경을 누르면 A0
- `f7676E`는 팝업이 열릴 때 false, 메인 구성·뒤로가기로 팝업이 닫힐 때 true

### 5.13 뒤로가기 y0

1. 손자 웹뷰가 열려 있으면: 뒤로 갈 수 있으면 뒤로, 아니면 `window.close()` 실행하고 손자 상태 false
2. 자식도 같은 방식
3. 메인이 주인(`f7676E`)이면: 메인이 뒤로 갈 수 있으면 뒤로, 아니면 2초 안에 두 번째면 앱 종료, 처음이면 토스트 `'뒤로' 버튼을 한번 더 누르시면 종료됩니다.`
4. 팝업이 주인이면: 팝업이 뒤로 갈 수 있으면 뒤로, 아니면 A0 후 `f7676E=true`

### 5.14 센서·위치

- 가속도(SENSOR_DELAY_NORMAL): 합력 / 9.80665 > **2.7g**이고 직전 감지에서 **500ms** 지났으면 흔들기 1회 → 흔들기 허용이면 `https://mobile.ut.ac.kr//service/api/device/gesture/shake?value=`로 POST(5.5)
- 원본에서 자기장 센서 처리가 가속도 분기 안에 들어가 있어 **방위각은 항상 0**이다
- 앱이 백그라운드로 가면 센서 해제
- `gps`: 정밀 위치 권한이 없으면 요청만 하고 0,0,0으로 보냄. 있으면 network → gps 순서로 마지막 위치를 읽음(gps가 있으면 덮어씀)
  - 주소: `config.url + String.format("&latitude=%s&longitude=%s&altitude=%s&azimuth=%s", 경도, 위도, 고도, 방위각)` — **위도 자리에 경도, 경도 자리에 위도**가 들어간다(원본 버그). `?` 확인 없이 `&`를 붙인다

### 5.15 NFC

- 메인 화면이 앞에 있는 동안 항상 foreground dispatch 켬(모든 태그)
- 기기에 NFC가 없으면 메인 시작 때 토스트 `NFC를 지원하지 않는 단말기입니다.`
- `function: nfc`: NFC가 켜져 있으면 nfc 대화상자(5.9), 꺼져 있으면 알림 `설정 화면의 NFC모드를 '기본' 또는 '읽기/쓰기'로 설정하시기 바랍니다.` 그리고 `config.url`에 `?value=`(또는 `&value=`)를 붙여 기억
- 태그를 읽으면: NDEF 메시지 첫 번째의 **세 번째 레코드** payload를 UTF-8로 읽고 첫 `s` 글자부터 잘라 trim → 비어 있지 않으면 기억한 주소(없으면 `https://mobile.ut.ac.kr//service/api/device/nfc?value=`) + 값으로 POST
- 태그 ID 16진수는 계산하지만 쓰지 않음
- 레코드가 3개보다 적은 NDEF 태그는 원본에서 배열 범위 예외가 잡히지 않아 **앱이 종료될 수 있다.** 이걸 그대로 재현할지는 사용자에게 확인할 것(1장 미정 사항에 추가)

### 5.16 비콘 (`function: beacone`)

- iBeacon 레이아웃 `m:2-3=0215,i:4-19,i:20-21,i:22-23,p:24-24`(AltBeacon)
- `config.uuid` 배열과 `config.url`(+`?uuid=`/`&uuid=`) 기억 → 모든 비콘 검색 시작 → **5초 뒤**: 찾은 비콘 중 id1이 배열의 uuid와 같은 것(뒤에 나온 것이 이김)의 id1·id2·id3으로
  `url + id1 + "&major=" + id2 + "&major=" + id3`로 POST(**major가 두 번**, 원본 그대로. 못 찾으면 `null` 문자열) → 검색 중지

### 5.17 QR (`function: qrcode`)

- `config.url`에 `?value=`/`&value=`를 붙여 기억하고 스캔 화면을 연다(방향 고정, 삑 소리 끔)
- 화면(`activity_custom_scanner.xml`): 카메라 전체, 가운데 260dp 테두리 이미지(`qr_area.png`), 그 위 10dp에 흰 20dp 글자 `사각 테두리 안에 QR코드를\n 인식해주세요.`(그중 "QR코드"만 #03DAC5), 아래 30dp에 닫기 이미지 버튼(`btn_qr_close.png`)
- 결과: 내용이 있으면 기억한 주소 + 내용으로 POST, 취소면 토스트 `Cancelled`

### 5.18 루팅 확인

- 메인 시작 때 `Runtime.exec("su")`가 성공하면 루팅 대화상자(5.9)

### 5.19 푸시 (FCM, data 메시지)

- 키 `title`, `body`, `url`. 알림 채널 `20005`/`ALLYTTE`(중요도 높음), 아이콘 `ic_launcher`, 누르면 IntroActivity에 `push_url`
- 토큰 갱신 시 `device.push_token` 저장
- **학교 Firebase 설정 없이는 동작 불가** — 1장 미정 사항

### 5.20 HCE 학생증 (`CardHostApduService`)

- 매니페스트에 서비스만 있고 `BIND_NFC_SERVICE`·`HOST_APDU_SERVICE` 필터·`apduservice.xml`이 없어 **시스템이 이 서비스를 쓸 수 없다**. 원본에서 실제로 동작한 적 없는 코드
- 참고용 AID: `F0534D4152544447554731323232`

### 5.21 일부러 그대로 둘 원본 동작 (고치지 말 것)

"개선점 반영 없이"가 요구 사항이므로 아래도 그대로 옮긴다.

- 기기 등록의 `osVersion`/`osName` 값 뒤바뀜, `//service` 슬래시 두 개
- GPS 위도·경도 뒤바뀜, 방위각 항상 0
- 비콘 `major` 두 번
- 헤더·푸터 `bgImage`가 모두 메인 헤더 배경으로 감
- 메인 웹뷰의 JS 알림창이 안드로이드 기본 대화상자로 뜸
- 로딩 중 화면 전체 터치 막힘
- 글자 크기 85% 고정
- 메인 푸터 처음 "*" 버튼
- 이미지(아이콘·배경)를 화면 그리는 중에 동기로 내려받음 — Flutter에서는 동기 대기가 불가하니 비동기로 받되 결과는 같게

---

## 6. Flutter로 옮길 때 참고

- 웹뷰: `webview_flutter`(공식). 추가 헤더는 `loadRequest(uri, headers:)`. JS 객체는 `addJavaScriptChannel`이 `postMessage` 하나만 주므로, 페이지 시작 때 아래 셰임을 주입하면 기존 웹 페이지를 바꾸지 않아도 된다.
  ```js
  window.allytteAndroid = {
    allytteCommandHandler: function (j) { AllytteBridge.postMessage(j); },
    addressSave: function (p) { AllytteAddress.postMessage(p); }
  };
  ```
  - `window.open`(onCreateWindow), 파일 선택, 다운로드, JS alert 커스텀, `setTextZoom` 같은 기능은 `webview_flutter_android`의 Android 전용 API로 확인할 것. 필요하면 해당 부분만 플랫폼 채널(Kotlin)로.
  - `flutter_inappwebview`는 2026-09 확인 당시 AGP 9.x에서 빌드가 깨졌다.
- 이전 로컬 시도(2026-09-16, 지금은 삭제됨)에서 겪은 빌드 문제: Windows에서 Kotlin 증분 캐시 잠김 → `kotlin.incremental=false`, 일부 AndroidX가 compileSdk 37 요구 → `android.suppressUnsupportedCompileSdk=37`, `flutter_local_notifications`는 core library desugaring 필요.
- 비콘·NFC foreground dispatch·루팅 확인은 Flutter 플러그인보다 Kotlin 플랫폼 채널이 원본과 같게 만들기 쉽다.
- 픽셀 단위(`f7680G`/`f7682H`)는 Flutter 논리 픽셀로 바꿀 때 `devicePixelRatio`로 나눠야 원본과 같은 크기가 된다.
