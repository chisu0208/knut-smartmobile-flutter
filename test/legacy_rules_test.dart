import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:knut_smartmobile/src/android_color.dart';
import 'package:knut_smartmobile/src/legacy_json.dart';
import 'package:knut_smartmobile/src/legacy_widgets.dart';
import 'package:knut_smartmobile/src/popup_animation.dart';

void main() {
  group('org.json 흉내', () {
    test('toString은 Android처럼 슬래시를 \\/로 바꾸고 순서를 지킨다', () {
      final JObj json = JObj.parse('{"b":"https://www.allytte.com/x","a":1}');
      json.map['urlConnResult'] = 200;
      expect(
        json.toString(),
        r'{"b":"https:\/\/www.allytte.com\/x","a":1,"urlConnResult":200}',
      );
      // 그래서 x0의 주소 바꾸기는 다시 직렬화된 문자열에서는 맞지 않는다.
      expect(json.toString().contains('https://www.allytte.com'), isFalse);
    });

    test('정수로 떨어지는 실수는 직렬화할 때 소수점이 빠지지만 getString은 그대로', () {
      final JObj json = JObj.parse('{"n":1.0,"m":0.5}');
      expect(json.toString(), '{"n":1,"m":0.5}');
      expect(json.getString('n'), '1.0');
    });

    test('JSON null과 없는 키는 isNull, getString(null)은 "null"', () {
      final JObj json = JObj.parse('{"a":null}');
      expect(json.isNull('a'), isTrue);
      expect(json.isNull('b'), isTrue);
      expect(json.getString('a'), 'null');
      expect(() => json.getString('b'), throwsA(isA<JsonFormatError>()));
    });

    test('형이 다르면 예외(원본에서 메인 헤더 메뉴가 배열이면 중단된 이유)', () {
      final JObj menu = JObj.parse(
        '{"left":[{"name":"x"}],"right":{"name":"y"}}',
      );
      expect(() => menu.getJSONObject('left'), throwsA(isA<JsonFormatError>()));
      expect(menu.getJSONObject('right').getString('name'), 'y');
      expect(() => menu.getJSONArray('right'), throwsA(isA<JsonFormatError>()));
    });

    test('getBoolean은 문자열 true/false도 받는다', () {
      final JObj json = JObj.parse('{"a":true,"b":"FALSE","c":"yes"}');
      expect(json.getBoolean('a'), isTrue);
      expect(json.getBoolean('b'), isFalse);
      expect(() => json.getBoolean('c'), throwsA(isA<JsonFormatError>()));
    });

    test('Integer.parseInt처럼 공백과 소수를 거부한다', () {
      expect(javaParseInt('2'), 2);
      expect(javaParseInt('+3'), 3);
      expect(() => javaParseInt(' 2'), throwsFormatException);
      expect(() => javaParseInt('1.0'), throwsFormatException);
    });

    test('Java Double.toString 표기', () {
      expect(javaDoubleToString(127.5), '127.5');
      expect(javaDoubleToString(0), '0.0');
      expect(javaDoubleToString(1e-5), '1.0E-5');
      expect(javaDoubleToString(12345678.0), '1.2345678E7');
    });
  });

  group('Color.parseColor', () {
    test('#RRGGBB, #AARRGGBB, 이름', () {
      expect(parseAndroidColor('#1b9ce8'), const Color(0xFF1B9CE8));
      expect(parseAndroidColor('#66000000'), const Color(0x66000000));
      expect(parseAndroidColor('White'), const Color(0xFFFFFFFF));
    });

    test('모르는 값은 예외', () {
      expect(() => parseAndroidColor('#fff'), throwsArgumentError);
      expect(() => parseAndroidColor('orange'), throwsArgumentError);
    });
  });

  group('RoundedWebView 모서리', () {
    test('오른쪽 아래가 둥글지 않으면 폭을 4000px로 잡는다', () {
      const RoundedWebViewClipper clipper = RoundedWebViewClipper(
        topLeft: true,
        topRight: true,
        bottomRight: false,
        bottomLeft: false,
        devicePixelRatio: 2,
      );
      final Rect bounds = clipper.getClip(const Size(300, 500)).getBounds();
      expect(bounds.width, 2000);
    });
  });

  group('옛 Android 애니메이션', () {
    test('끝나면 리스너가 한 번 불리고 마지막 위치에 머문다(fillAfter)', () {
      int calls = 0;
      final AnimTrack track = AnimTrack(
        (_) =>
            () => calls++,
      );
      track.start(LegacyAnim.inRight);
      track.tick(Duration.zero);
      expect(track.offset(const Size(400, 800), const Size(320, 800)).dx, 400);
      track.tick(const Duration(milliseconds: 600));
      expect(calls, 1);
      expect(track.attached, isTrue);
      expect(
        track.offset(const Size(400, 800), const Size(320, 800)),
        Offset.zero,
      );
      track.clear();
      expect(calls, 1);
      expect(track.attached, isFalse);
    });

    test('도는 중에 clear하면 끝 알림이 간다, 시작 전이면 안 간다', () {
      int calls = 0;
      final AnimTrack track = AnimTrack(
        (_) =>
            () => calls++,
      );
      track.start(LegacyAnim.outLeft);
      track.clear();
      expect(calls, 0);
      track.start(LegacyAnim.outLeft);
      track.tick(Duration.zero);
      track.tick(const Duration(milliseconds: 100));
      track.clear();
      expect(calls, 1);
    });

    test('나가는 애니메이션은 자기 크기만큼 움직인다', () {
      final AnimTrack track = AnimTrack((_) => () {});
      track.start(LegacyAnim.outBottom);
      track.tick(Duration.zero);
      track.tick(AnimTrack.duration);
      expect(track.offset(const Size(400, 800), const Size(400, 640)).dy, 640);
    });

    test('개선판: 0.25초, 빠르게 출발해 감속(통합본 6-2)', () {
      expect(AnimTrack.duration, const Duration(milliseconds: 250));
      int calls = 0;
      final AnimTrack track = AnimTrack(
        (_) =>
            () => calls++,
      );
      track.start(LegacyAnim.inRight);
      track.tick(Duration.zero);
      // 절반 시간에 이미 거리의 3/4를 왔다(원본 accelerate_decelerate는 1/2).
      track.tick(const Duration(milliseconds: 125));
      expect(
        track.offset(const Size(400, 800), const Size(320, 800)).dx,
        closeTo(100, 0.001),
      );
      expect(calls, 0);
      track.tick(const Duration(milliseconds: 250));
      expect(calls, 1);
      expect(AnimTrack.curve(0), 0);
      expect(AnimTrack.curve(1), 1);
    });
  });
}
