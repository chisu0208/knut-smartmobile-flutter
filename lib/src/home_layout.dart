import 'package:flutter/material.dart';

import 'legacy_widgets.dart';

/// 홈 탭 배치(개선판 2차): 위쪽 막대(서버 `footer`), 서버 헤더, 본문(메인 웹뷰).
///
/// 원본은 헤더 / 본문 / 회색 구분선(`line_footer`) / 하단 바(`main_footer`) 순서였다. 앱 탭
/// 막대가 화면 아래에 생겨서, 서버가 보내는 하단 바 버튼(≡ ☆ 집 로그인)은 홈 탭 맨 위 막대로
/// 옮기고, 하단 바용 회색 구분선은 없앴다. [topBar]가 없으면(서버가 footer를 보내지 않음) 막대를
/// 숨긴다. 원본이 처음에 보이던 `*` 버튼도 없다.
class HomeLayout extends StatelessWidget {
  const HomeLayout({super.key, this.topBar, this.header, required this.body});

  final Widget? topBar;
  final Widget? header;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        ?topBar,
        ?header,
        const SizedBox(height: 1), // main_body layout_marginTop
        Expanded(child: body),
      ],
    );
  }
}

/// 위쪽 막대의 버튼 하나.
class HomeTopBarButton {
  const HomeTopBarButton({required this.child, this.onTap});

  /// 원본 모양 버튼(아이콘 칸 `d1`).
  final Widget child;
  final VoidCallback? onTap;
}

/// 홈 위쪽 막대: 서버 footer 버튼을 원본 하단 바처럼 가로로 똑같이 나눈 칸 가운데에 그린다(50dp).
///
/// 원본 버튼 칸은 px 단위(90·110px, Pixel 7에서 약 34dp)라 누르는 곳이 작았다. 개선판 2차는 칸
/// 전체(가로 1/n × 50dp)를 누르는 곳으로 해서 48dp 이상이다(통합본 5-4). 버튼 모양·크기는 그대로다.
class HomeTopBar extends StatelessWidget {
  const HomeTopBar({super.key, required this.box, required this.buttons});

  /// 배경색·그림·테두리(서버 footer의 `bgColor`·`bgImage`·`border`).
  final GradientBox box;
  final List<HomeTopBarButton> buttons;

  static const double height = 50;

  @override
  Widget build(BuildContext context) {
    return BoxBackground(
      box: box,
      height: height,
      child: Row(
        children: <Widget>[
          for (final HomeTopBarButton button in buttons)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: button.onTap,
                child: Center(child: button.child),
              ),
            ),
        ],
      ),
    );
  }
}
