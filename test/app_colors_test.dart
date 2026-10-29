import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knut_smartmobile/main.dart' show SmartMobileApp;
import 'package:knut_smartmobile/src/app_colors.dart';

/// 대표색(개선판 2차: 팀원 Figma 토큰 primary #A3162B, 1차는 #76161B)은 Dart와 Android 리소스에
/// 한 번씩 적혀 있다. 둘이 같아야 한다.
void main() {
  test('Dart 대표색과 Android @color/school이 같다(Figma primary)', () {
    final String xml = File('android/app/src/main/res/values/colors.xml')
        .readAsStringSync();
    final RegExpMatch? match = RegExp(
      r'<color name="school">#([0-9A-Fa-f]{6})</color>',
    ).firstMatch(xml);
    expect(match, isNotNull);
    expect(
      0xFF000000 | int.parse(match!.group(1)!, radix: 16),
      schoolColor.toARGB32(),
    );
    expect(schoolColor, const Color(0xFFA3162B));
    // 적응형 아이콘 배경도 대표색을 가리킨다.
    expect(
      xml,
      contains('<color name="ic_launcher_background">@color/school</color>'),
    );
  });

  test('AppCompat 테마 색은 모두 대표색을 가리킨다', () {
    final String styles = File('android/app/src/main/res/values/styles.xml')
        .readAsStringSync();
    for (final String item in <String>[
      'colorPrimary',
      'colorPrimaryDark',
      'colorAccent',
    ]) {
      expect(styles, contains('<item name="$item">@color/school</item>'));
    }
    // 색 코드를 직접 적은 항목이 없다(원본 #006bd0·#3700b3·#03dac5).
    expect(styles, isNot(matches(RegExp(r'<item name="color\w+">#'))));
  });

  test('Flutter 테마의 강조색도 대표색', () {
    expect(SmartMobileApp.theme.colorScheme.primary, schoolColor);
  });

  test('흰 글자와 대표색의 명암비가 4.5:1 이상', () {
    double ratio(Color a, Color b) {
      final double la = a.computeLuminance();
      final double lb = b.computeLuminance();
      final double hi = la > lb ? la : lb;
      final double lo = la > lb ? lb : la;
      return (hi + 0.05) / (lo + 0.05);
    }

    expect(ratio(Colors.white, AppColors.primary), greaterThan(4.5));
    expect(ratio(Colors.white, AppColors.primaryDark), greaterThan(4.5));
    expect(
      ratio(AppColors.primaryDark, AppColors.primarySoft),
      greaterThan(4.5),
    );
    expect(ratio(AppColors.sub, AppColors.bg), greaterThan(4.5));
  });
}
