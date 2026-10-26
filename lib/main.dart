import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'src/intro_screen.dart';
import 'src/legacy_widgets.dart';
import 'src/main_screen.dart';
import 'src/native_bridge.dart';

/// 한국교통대학교 스마트모바일 1.1.3(Android)의 Flutter 이식.
///
/// 원본처럼 시작 화면(IntroActivity)에서 기기를 등록하고, 받은 화면 설정으로 메인 화면
/// (MainActivity)을 띄운다. 화면 내용은 학교 웹 페이지다(HANDOFF.md).
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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '한국교통대학교 스마트모바일',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.light,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF006BD0),
        useMaterial3: false,
      ),
      builder: legacyAppBuilder,
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
