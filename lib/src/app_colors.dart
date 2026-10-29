import 'dart:ui';

/// 앱 전체 색 토큰. 팀원 도서관 탭 Figma(변수 "KNUT Library", `mockups/library/01_overview.png`)의
/// 값을 2026-10-27에 앱 전체 색으로 정했다(개선판 2차).
///
/// 개선판 1차는 학교 엠블럼에서 고른 적갈색 #76161B 하나를 썼다(통합본 5-10). 2차는 그 자리를
/// [primary]로 바꿨다. 이 토큰으로 만든 새 화면용 Material 3 테마는 `app_theme.dart`다(2차 새
/// 화면은 2026-10-29에 되돌려 지금은 쓰지 않음). 흰 글자와의 명암비는 [primary] 7.8:1,
/// [primaryDark] 12.1:1로 기준(4.5:1)을 넘는다(IMPROVEMENTS.md 개선판 2차).
///
/// Android 쪽 같은 값은 `android/app/src/main/res/values/colors.xml`에 있다. 바꿀 때는 둘 다
/// 바꾸고, `test/app_colors_test.dart`가 둘이 같은지 확인한다.
abstract final class AppColors {
  /// 대표색(버튼, 강조, 선택된 탭).
  static const Color primary = Color(0xFFA3162B);

  /// 진한 대표색(옅은 대표색 위의 글자).
  static const Color primaryDark = Color(0xFF6E0E1C);

  /// 옅은 대표색(선택 표시 바탕, 배지 바탕).
  static const Color primarySoft = Color(0xFFFBECEE);

  /// 본문 글자.
  static const Color ink = Color(0xFF17191E);

  /// 보조 글자.
  static const Color sub = Color(0xFF5B6070);

  /// 흐린 글자(지난 시각 등). 흰 바탕 명암비 2.6:1이라 읽어야 하는 글자에는 쓰지 않는다.
  static const Color mute = Color(0xFF9AA0AE);

  /// 구분선.
  static const Color line = Color(0xFFE6E8EE);

  /// 화면 바탕.
  static const Color bg = Color(0xFFF4F5F8);

  static const Color green = Color(0xFF0E9F4F);
  static const Color amber = Color(0xFFD97A00);
  static const Color blue = Color(0xFF2F6FEB);
  static const Color seatUsed = Color(0xFFD5D9E0);
}

/// 앱이 직접 그리는 강조색(대표색). 1차에서 학교색 #76161B를 쓰던 곳(alert `확인`, 연결 안내
/// `다시 시도`, QR 닫기 버튼, AppCompat 대화상자 버튼, 적응형 아이콘 배경)이 이 값을 쓴다.
const Color schoolColor = AppColors.primary;
