import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:knut_smartmobile/main.dart' show SmartMobileApp;
import 'package:knut_smartmobile/src/app_colors.dart';

/// 학교 대표색(통합본 5-10)은 Dart와 Android 리소스에 한 번씩 적혀 있다. 둘이 같아야 한다.
void main() {
  test('Dart schoolColor와 Android @color/school이 같다', () {
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
  });

  test('AppCompat 테마 색은 모두 학교 대표색을 가리킨다', () {
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

  test('Flutter 테마의 강조색도 학교 대표색', () {
    expect(SmartMobileApp.theme.colorScheme.primary, schoolColor);
  });
}
