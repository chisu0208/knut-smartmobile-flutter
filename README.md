# knut-smartmobile-flutter

한국교통대학교 스마트모바일 1.1.3(Android)을 기능 추가나 개선 없이 Flutter로 옮긴 프로젝트입니다.
화면 내용은 원본처럼 학교 웹 페이지(`mobile.ut.ac.kr`)이고, 앱은 그 웹 페이지를 띄우는 껍데기입니다.

- 원본 분석, 동작 규칙, 이식 구조, 원본과 다른 점: [HANDOFF.md](HANDOFF.md)
- 원본 디컴파일 코드와 리소스: `docs/legacy/`

## 실행

Flutter 3.47.2, Android 전용입니다.
Windows에서는 `C:\dev\knut-smartmobile-flutter`처럼 한글·공백이 없는 C 드라이브 영문 경로에 clone하세요(한글 경로는 분석·빌드 실패, `subst` 드라이브는 Kotlin 컴파일 실패. HANDOFF.md 2장).

```bash
flutter pub get
flutter run
```

패키지 이름이 `kr.ac.ut.mobile.flutter`라서 원본 앱과 같은 폰에 함께 설치됩니다.
