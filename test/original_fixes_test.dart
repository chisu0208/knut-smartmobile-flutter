import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knut_smartmobile/src/allytte_http.dart';
import 'package:knut_smartmobile/src/legacy_json.dart';
import 'package:knut_smartmobile/src/legacy_widgets.dart';

/// flutter_test는 모든 HTTP 요청에 400을 돌려주는 가짜 클라이언트를 쓴다. 로컬 서버에 실제로
/// 연결하도록 기본 HttpClient로 되돌린다.
class _RealHttp extends HttpOverrides {}

/// 원본 버그로 남겨 두었던 앱 쪽 동작을 고친 것(HANDOFF 5.21, IMPROVEMENTS.md).
void main() {
  group('메인 헤더 메뉴가 배열이어도 받는다(HANDOFF 5.6)', () {
    final JObj menu = JObj.parse(
      '{"left":{"name":"a"},"center":[{"name":"b"},{"name":"c"}],'
      '"right":"x","empty":[]}',
    );

    test('객체 하나면 버튼 하나, 배열이면 차례로', () {
      expect(
        menu.getJSONObjects('left').map((JObj o) => o.getString('name')),
        <String>['a'],
      );
      expect(
        menu.getJSONObjects('center').map((JObj o) => o.getString('name')),
        <String>['b', 'c'],
      );
      expect(menu.getJSONObjects('empty'), isEmpty);
    });

    test('객체도 배열도 아니면 원본처럼 예외', () {
      expect(
        () => menu.getJSONObjects('right'),
        throwsA(isA<JsonFormatError>()),
      );
      expect(
        () => menu.getJSONObjects('none'),
        throwsA(isA<JsonFormatError>()),
      );
    });
  });

  group('그림을 받지 못하면 그림 없이(HANDOFF 5.8)', () {
    test('실패·그림 아님이면 그림이 없다(원본은 직전 그림을 썼다)', () {
      expect(const BitmapFailed().image, isNull);
      expect(const BitmapUndecodable().image, isNull);
    });

    testWidgets('로컬 서버: 404와 그림이 아닌 응답은 null, PNG는 그림', (
      WidgetTester tester,
    ) async {
      await tester.runAsync(() async {
        final List<int> png = File('assets/images/loading01.png')
            .readAsBytesSync();
        final HttpServer server = await HttpServer.bind(
          InternetAddress.loopbackIPv4,
          0,
        );
        server.listen((HttpRequest request) {
          final HttpResponse response = request.response;
          switch (request.uri.path) {
            case '/png':
              response.add(png);
            case '/text':
              response.write('not an image');
            default:
              response.statusCode = 404;
          }
          response.close();
        });
        Future<ui.Image?> fetch(String path) =>
            HttpOverrides.runWithHttpOverrides(
              () async =>
                  (await fetchBitmap('http://127.0.0.1:${server.port}$path'))
                      .image,
              _RealHttp(),
            );
        expect(await fetch('/missing'), isNull);
        expect(await fetch('/text'), isNull);
        final ui.Image? image = await fetch('/png');
        expect(image, isNotNull);
        expect(image!.width, greaterThan(0));
        await server.close(force: true);
      });
    });
  });

  group('헤더·푸터 배경 그림은 자기 칸에(HANDOFF 5.8 g1)', () {
    testWidgets('그림이 없으면 배경색·테두리', (WidgetTester tester) async {
      final GradientBox box = GradientBox(color: const Color(0xFF123456))
        ..setStroke(1, Colors.black);
      await tester.pumpWidget(
        Center(
          child: BoxBackground(
            box: box,
            height: 50,
            child: const SizedBox(width: 100),
          ),
        ),
      );
      final Container container = tester.widget<Container>(
        find.byType(Container),
      );
      final BoxDecoration decoration = container.decoration! as BoxDecoration;
      expect(decoration.color, const Color(0xFF123456));
      expect(decoration.border, isNotNull);
      expect(find.byType(RawImage), findsNothing);
      expect(tester.getSize(find.byType(BoxBackground)).height, 50);
    });

    testWidgets('그림이 있으면 그 칸에 늘려 깔고 칸 모서리대로 자른다', (WidgetTester tester) async {
      final ui.Image image = (await tester.runAsync(
        () => createTestImage(width: 4, height: 2),
      ))!;
      final GradientBox box = GradientBox(
        color: Colors.white,
        radius: cornerRadii(tl: 30, tr: 30),
      )..image = image;
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: BoxBackground(
              box: box,
              height: 58,
              child: const SizedBox(width: 200),
            ),
          ),
        ),
      );
      final RawImage raw = tester.widget<RawImage>(find.byType(RawImage));
      expect(raw.image, same(image));
      expect(raw.fit, BoxFit.fill);
      expect(tester.getSize(find.byType(RawImage)), const Size(200, 58));
      expect(
        tester.widget<ClipRRect>(find.byType(ClipRRect)).borderRadius,
        cornerRadii(tl: 30, tr: 30),
      );
    });
  });
}
