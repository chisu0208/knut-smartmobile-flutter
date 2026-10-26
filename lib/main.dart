import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'src/app_colors.dart';
import 'src/intro_screen.dart';
import 'src/main_screen.dart';
import 'src/native_bridge.dart';

/// 한국교통대학교 스마트모바일 1.1.3(Android)의 Flutter 개선판.
///
/// 원본처럼 시작 화면(IntroActivity)에서 기기를 등록하고, 받은 화면 설정으로 메인 화면
/// (MainActivity)을 띄운다. 화면 내용은 학교 웹 페이지다(HANDOFF.md). 원본·이식판과 달라진
/// 동작은 IMPROVEMENTS.md에 있다.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
  ]);
  final String? pushUrl = await NativeBridge.takeLaunchPushUrl();
  runApp(SmartMobileApp(pushUrl: pushUrl));
}

class SmartMobileApp extends StatelessWidget {
  const SmartMobileApp({super.key, this.pushUrl});

  final String? pushUrl;

  /// 강조색은 학교 대표색 하나(통합본 5-10). 원본 테마 색은 #006BD0이었다.
  static final ThemeData theme = ThemeData(
    colorScheme: const ColorScheme.light(
      primary: schoolColor,
      secondary: schoolColor,
    ),
    useMaterial3: false,
  );

  /// 모든 화면(인트로, 메인, QR, 다시 뜨는 인트로)을 감싼다.
  ///
  /// `MaterialApp`은 `Material` 밖의 글자에 오류 표시용 스타일(노란 이중 밑줄, monospace,
  /// w900)을 물려준다. 원본 TextView처럼 밑줄 없는 시스템 글꼴·보통 굵기를 기본으로 준다.
  /// 투명 Material이라 색, 터치, 배치는 바뀌지 않는다.
  static Widget wrapScreens(BuildContext context, Widget? child) =>
      Material(type: MaterialType.transparency, child: child);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '스마트모바일 개선판',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.light,
      theme: theme,
      builder: wrapScreens,
      home: Builder(
        builder: (BuildContext context) => IntroScreen(
          pushUrl: pushUrl,
          onFinished: (String? screenInfo) {
            // 원본: MainActivity를 열고 IntroActivity는 끝낸다.
            Navigator.of(context).pushReplacement(
              PageRouteBuilder<void>(
                pageBuilder: (_, _, _) => MainScreen(screenInfo: screenInfo),
                transitionDuration: Duration.zero,
              ),
            );
          },
        ),
      ),
    );
  }
}
