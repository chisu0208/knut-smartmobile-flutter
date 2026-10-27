import 'dart:ui';

/// 앱이 직접 그리는 강조색. 원본은 개발 도구 기본값(파랑 #006BD0, 보라 #3700B3, 청록 #03DAC5,
/// alert 버튼 #1B9CE8)이 섞여 있었다. 개선판은 학교 대표색 하나로 맞춘다(통합본 5-10).
///
/// 값은 원본 APK의 학교 엠블럼(`assets/app_icon_1024.png`) 바탕에서 가장 많이 쓰인 적갈색이다.
/// 학교 공식 UI 색 규정을 찾지 못해 엠블럼에서 골랐다(IMPROVEMENTS.md). 바꿀 때는 Android 쪽
/// `android/app/src/main/res/values/colors.xml`의 `school`도 같이 바꾼다.
const Color schoolColor = Color(0xFF76161B);
