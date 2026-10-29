# knut-smartmobile-flutter

한국교통대학교 스마트모바일 1.1.3(Android)을 Flutter로 옮기고, 앱에서 고칠 수 있는 문제점을 고치는 프로젝트입니다.
홈 화면 내용은 원본처럼 학교 웹 페이지(`mobile.ut.ac.kr`)입니다. 개선판 2차에서 만든 하단 탭 다섯 개(홈·출결·도서관·교통·학식)와 학식·교통 탭은 2026-10-29에 되돌렸고, 대표색만 남았습니다.

| 판 | 어디에 | 패키지 | 앱 이름 |
|---|---|---|---|
| **개선판** | `main` | `kr.ac.ut.mobile.renewal` | 스마트모바일 개선판 |
| 순수 이식판(개선 없이 옮긴 것) | 태그 `port-1.1.3` | `kr.ac.ut.mobile.flutter` | 한국교통대학교 스마트모바일 |
| 원본 | `한국교통대학교 스마트모바일_1.1.3.apk` | `kr.ac.ut.mobile` | 한국교통대학교 스마트모바일 |

세 앱은 패키지가 달라 같은 폰에 나란히 설치됩니다. 서버에는 원본과 같은 버전(1.1.3)으로 접속합니다.

- 개선판에서 고친 것과 고치지 않은 것, 확인 목록: [IMPROVEMENTS.md](IMPROVEMENTS.md)(2차: 10절, 되돌림: 12절)
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

