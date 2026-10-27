import 'package:flutter_test/flutter_test.dart';
import 'package:knut_smartmobile/src/web_entry.dart';

/// 웹 글자 크기(통합본 5-1): 휴대폰 글자 크기 설정을 따르되 1.3배에서 멈춘다.
void main() {
  test('기본 크기에서는 100%, 작게·크게 한 만큼 따른다', () {
    expect(WebEntry.textZoomFor(1), 100);
    expect(WebEntry.textZoomFor(0.85), 85);
    expect(WebEntry.textZoomFor(1.15), 115);
    expect(WebEntry.textZoomFor(1.3), 130);
  });

  test('1.3배보다 크게 해도 130%에서 멈춘다(학교 페이지 배치가 무너지지 않게)', () {
    expect(WebEntry.maxWebFontScale, 1.3);
    for (final double scale in <double>[1.5, 1.8, 2]) {
      expect(WebEntry.textZoomFor(scale), 130, reason: '$scale');
    }
  });

  test('설정 값의 소수 오차는 반올림한다', () {
    expect(WebEntry.textZoomFor(1.149999), 115);
    expect(WebEntry.textZoomFor(0.8999), 90);
  });
}
