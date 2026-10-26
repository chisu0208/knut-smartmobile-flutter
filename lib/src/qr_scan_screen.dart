import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'app_colors.dart';

/// 원본 `ZxingActivity`(HANDOFF 5.17). 읽은 내용을 돌려주고, 닫거나 뒤로 가면 null.
///
/// 원본은 ZXing(journeyapps) 화면이고, 여기서는 같은 배치를 Flutter로 그리고 인식은
/// mobile_scanner가 한다. 인식 범위는 원본처럼 가운데 250dp 사각형.
class QrScanScreen extends StatefulWidget {
  const QrScanScreen({super.key});

  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen> {
  static const double _framing = 250;

  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  late final Timer _inactivity;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    // CaptureManager의 InactivityTimer: 5분 동안 아무것도 없으면 닫힌다.
    _inactivity = Timer(const Duration(minutes: 5), () => _finish(null));
  }

  @override
  void dispose() {
    _inactivity.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _finish(String? result) {
    if (_done || !mounted) return;
    _done = true;
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        // 카메라가 뜨기 전. 원본은 colorAccent(#03DAC5)였다(통합본 5-10).
        backgroundColor: Colors.black,
        body: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final Size size = constraints.biggest;
            final Rect frame = Rect.fromCenter(
              center: size.center(Offset.zero),
              width: _framing,
              height: _framing,
            );
            return Stack(
              children: <Widget>[
                Positioned.fill(
                  child: MobileScanner(
                    controller: _controller,
                    scanWindow: frame,
                    errorBuilder: _cameraError,
                    onDetect: (BarcodeCapture capture) {
                      for (final Barcode barcode in capture.barcodes) {
                        final String? value = barcode.rawValue;
                        if (value != null) {
                          _finish(value);
                          return;
                        }
                      }
                    },
                  ),
                ),
                Positioned.fill(child: _Viewfinder(frame: frame)),
                // ll_scan_box: 가운데 260dp, 배경 qr_area.png
                Positioned.fromRect(
                  rect: Rect.fromCenter(
                    center: size.center(Offset.zero),
                    width: 260,
                    height: 260,
                  ),
                  child: Image.asset(
                    'assets/images/qr_area.png',
                    fit: BoxFit.fill,
                  ),
                ),
                // zxing_status_view: 상자 위 10dp, 흰색 20dp. 원본은 "QR코드"만 #03DAC5였다.
                // 어두운 카메라 화면 위에서 학교색(적갈색)은 잘 안 보여 굵은 흰 글자로 강조한다(5-10).
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: size.height - (size.height / 2 - 130) + 10,
                  child: Center(
                    child: Text.rich(
                      const TextSpan(
                        children: <TextSpan>[
                          TextSpan(text: '사각 테두리 안에 '),
                          TextSpan(
                            text: 'QR코드',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextSpan(text: '를\n 인식해주세요.'),
                        ],
                      ),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 20, color: Colors.white),
                    ),
                  ),
                ),
                // btn_qr_close: 아래 30dp, 가운데
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 30,
                  child: Center(
                    child: GestureDetector(
                      onTap: () => _finish(null),
                      child: Image.asset(
                        'assets/images/btn_qr_close.png',
                        width: 60,
                        height: 60,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// 카메라를 열지 못했을 때의 안내. 원본(ZXing)은 영어 `Sorry, the Android camera encountered a
/// problem…`이었다(통합본 7-1). 닫기 버튼은 그 위에 그대로 있다.
Widget _cameraError(BuildContext context, MobileScannerException error) {
  final String message =
      error.errorCode == MobileScannerErrorCode.permissionDenied
      ? '카메라 권한이 없어 QR 코드를 읽을 수 없습니다.'
      : '카메라를 열 수 없습니다.\n다른 앱이 카메라를 쓰고 있는지 확인해 주세요.';
  return ColoredBox(
    color: Colors.black,
    child: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
    ),
  );
}

/// ZXing `ViewfinderView`: 인식 범위 밖을 #60000000으로 가리고, 가운데에 깜빡이는 선.
/// 선 색은 원본 #1976d2에서 학교 대표색으로 바꿨다(통합본 5-10).
class _Viewfinder extends StatefulWidget {
  const _Viewfinder({required this.frame});

  final Rect frame;

  @override
  State<_Viewfinder> createState() => _ViewfinderState();
}

class _ViewfinderState extends State<_Viewfinder> {
  static const List<int> _alphas = <int>[0, 64, 128, 192, 255, 192, 128, 64];
  late final Timer _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 80), (_) {
      setState(() => _index = (_index + 1) % _alphas.length);
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _ViewfinderPainter(widget.frame, _alphas[_index]),
      ),
    );
  }
}

class _ViewfinderPainter extends CustomPainter {
  _ViewfinderPainter(this.frame, this.laserAlpha);

  final Rect frame;
  final int laserAlpha;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint mask = Paint()..color = const Color(0x60000000);
    canvas.drawRect(Rect.fromLTRB(0, 0, size.width, frame.top), mask);
    canvas.drawRect(
      Rect.fromLTRB(0, frame.top, frame.left, frame.bottom + 1),
      mask,
    );
    canvas.drawRect(
      Rect.fromLTRB(frame.right + 1, frame.top, size.width, frame.bottom + 1),
      mask,
    );
    canvas.drawRect(
      Rect.fromLTRB(0, frame.bottom + 1, size.width, size.height),
      mask,
    );
    final double middle = frame.height / 2 + frame.top;
    canvas.drawRect(
      Rect.fromLTRB(frame.left + 2, middle - 1, frame.right - 1, middle + 2),
      Paint()..color = schoolColor.withAlpha(laserAlpha),
    );
  }

  @override
  bool shouldRepaint(_ViewfinderPainter oldDelegate) =>
      oldDelegate.laserAlpha != laserAlpha || oldDelegate.frame != frame;
}
