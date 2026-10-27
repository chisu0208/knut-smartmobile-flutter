import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knut_smartmobile/src/app_colors.dart';
import 'package:knut_smartmobile/src/qr_scan_screen.dart';

/// QR 화면 색(통합본 5-10): 어두운 카메라 화면 위에서 보이도록 테두리는 흰색, 닫기 버튼은 흰
/// 테두리를 두른 학교색 원에 흰 X. 원본 청록(`qr_area.png`·`btn_qr_close.png`)은 쓰지 않는다.
void main() {
  /// [painter]를 [size] 크기로 어두운 바탕 위에 그려 [points]의 색을 읽는다.
  Future<List<Color>> colorsAt(
    WidgetTester tester,
    CustomPainter painter,
    Size size,
    List<Offset> points,
  ) async {
    final GlobalKey key = GlobalKey();
    await tester.pumpWidget(
      Align(
        alignment: Alignment.topLeft,
        child: RepaintBoundary(
          key: key,
          child: ColoredBox(
            color: Colors.black,
            child: SizedBox.fromSize(
              size: size,
              child: CustomPaint(painter: painter),
            ),
          ),
        ),
      ),
    );
    final List<Color> colors = <Color>[];
    await tester.runAsync(() async {
      final RenderRepaintBoundary boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      // 가장자리의 부드럽게 칠한 화소를 피하도록 4배로 그려 읽는다.
      const double scale = 4;
      final ui.Image image = await boundary.toImage(pixelRatio: scale);
      final ByteData data = (await image.toByteData())!;
      for (final Offset p in points) {
        final int x = (p.dx * scale).floor();
        final int y = (p.dy * scale).floor();
        final int i = (y * image.width + x) * 4;
        colors.add(
          Color.fromARGB(
            data.getUint8(i + 3),
            data.getUint8(i),
            data.getUint8(i + 1),
            data.getUint8(i + 2),
          ),
        );
      }
    });
    return colors;
  }

  testWidgets('테두리 모서리와 안쪽 선은 흰색', (WidgetTester tester) async {
    final List<Color> colors = await colorsAt(
      tester,
      const QrFramePainter(),
      const Size(260, 260),
      const <Offset>[
        Offset(2, 2), // 왼쪽 위 모서리
        Offset(257, 257), // 오른쪽 아래 모서리
        Offset(130, 5.85), // 위쪽 가는 선(그림 8~10px → 5.2~6.5dp)
        Offset(130, 130), // 가운데는 비어 있다
      ],
    );
    expect(colors[0], Colors.white);
    expect(colors[1], Colors.white);
    expect(colors[2], Colors.white);
    expect(colors[3], Colors.black);
    expect(qrMarkColor, Colors.white);
  });

  testWidgets('닫기 버튼은 흰 테두리, 학교색 원, 흰 X', (WidgetTester tester) async {
    final List<Color> colors = await colorsAt(
      tester,
      const QrCloseButtonPainter(),
      const Size(60, 60),
      const <Offset>[
        Offset(30, 1), // 위 끝 테두리(2dp)
        Offset(30, 12), // X 위쪽의 원
        Offset(30, 30), // X 가운데
        Offset(0.5, 0.5), // 원 밖
      ],
    );
    expect(colors[0], Colors.white);
    expect(colors[1], schoolColor);
    expect(colors[2], Colors.white);
    expect(colors[3], Colors.black);
  });
}
