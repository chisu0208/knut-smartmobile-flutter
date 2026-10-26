import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// 원본 테마(Theme.AppCompat.Light)의 창 배경색.
const Color windowBackground = Color(0xFFFAFAFA);

/// GradientDrawable(헤더·푸터 배경)의 색, 테두리, 모서리.
class GradientBox {
  GradientBox({required this.color, this.radius = BorderRadius.zero});

  Color color;
  double strokeWidth = 0;
  Color strokeColor = const Color(0xFFFFFFFF);
  BorderRadius radius;

  /// `setStroke(N(dp), color)`
  void setStroke(double widthDp, Color color) {
    strokeWidth = widthDp;
    strokeColor = color;
  }

  BoxDecoration decoration() => BoxDecoration(
    color: color,
    borderRadius: radius,
    border: strokeWidth > 0
        ? Border.all(color: strokeColor, width: strokeWidth)
        : null,
  );
}

/// GradientDrawable `setCornerRadii` 배열: (왼위, 오위, 오아래, 왼아래).
BorderRadius cornerRadii({
  double tl = 0,
  double tr = 0,
  double br = 0,
  double bl = 0,
}) => BorderRadius.only(
  topLeft: Radius.circular(tl),
  topRight: Radius.circular(tr),
  bottomRight: Radius.circular(br),
  bottomLeft: Radius.circular(bl),
);

/// 메뉴 버튼의 배경.
sealed class ButtonBackground {
  const ButtonBackground();
}

/// 스타일 기본 배경(AppCompat 회색 버튼).
class DefaultButtonBackground extends ButtonBackground {
  const DefaultButtonBackground();
}

/// `setBackgroundColor(#00ff0000)` — 투명.
class TransparentButtonBackground extends ButtonBackground {
  const TransparentButtonBackground();
}

/// 아이콘 이미지를 버튼 전체에 늘려 깐 배경(`BitmapDrawable`). 이미지가 null이면 빈 그림.
class ImageButtonBackground extends ButtonBackground {
  const ImageButtonBackground(this.image);
  final ui.Image? image;
}

/// `new Button(this)`(Widget.AppCompat.Button → Widget.Material.Button).
///
/// 최소 88×48dp, 글자 14sp 굵게·대문자, 기본 배경은 4dp/6dp 안쪽에 그린 #d6d7d7 2dp 둥근
/// 사각형과 그림자, 안쪽 여백은 가로 12dp·세로 10dp(배경 그림의 여백). 배경을 바꿔도
/// 여백은 그대로 남는다.
class LegacyButton extends StatelessWidget {
  const LegacyButton({
    super.key,
    this.text,
    this.textColor = const Color(0xDE000000),
    this.textSize = 14,
    this.background = const DefaultButtonBackground(),
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    this.onTap,
  });

  final String? text;
  final Color textColor;
  final double textSize;
  final ButtonBackground background;
  final EdgeInsets padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Widget label = Padding(
      padding: padding,
      child: Center(
        widthFactor: 1,
        heightFactor: 1,
        child: text == null
            ? const SizedBox.shrink()
            : Text(
                text!.toUpperCase(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: textColor,
                  fontSize: textSize,
                  fontWeight: FontWeight.w500,
                  height: 1.17,
                ),
              ),
      ),
    );
    final ButtonBackground bg = background;
    Widget body = switch (bg) {
      DefaultButtonBackground() => _DefaultButtonFrame(
        onTap: onTap,
        child: label,
      ),
      TransparentButtonBackground() => label,
      ImageButtonBackground(:final ui.Image? image) => Stack(
        fit: StackFit.passthrough,
        children: <Widget>[
          if (image != null)
            Positioned.fill(
              child: RawImage(image: image, fit: BoxFit.fill),
            ),
          label,
        ],
      ),
    };
    if (bg is! DefaultButtonBackground && onTap != null) {
      body = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: body,
      );
    }
    return ClipRect(
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 88, minHeight: 48),
        child: body,
      ),
    );
  }
}

class _DefaultButtonFrame extends StatelessWidget {
  const _DefaultButtonFrame({required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.passthrough,
      children: <Widget>[
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Material(
              color: const Color(0xFFD6D7D7),
              elevation: 2,
              borderRadius: BorderRadius.circular(2),
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
        IgnorePointer(child: child),
      ],
    );
  }
}

/// 원본 `progress.xml`: 38dp 크기로 `loading01.png`를 돌린다(animated-rotate 기본값
/// 12단계 × 150ms).
class LoadingSpinner extends StatefulWidget {
  const LoadingSpinner({super.key});

  @override
  State<LoadingSpinner> createState() => _LoadingSpinnerState();
}

class _LoadingSpinnerState extends State<LoadingSpinner> {
  late final Timer _timer;
  int _frame = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 150), (_) {
      setState(() => _frame = (_frame + 1) % 12);
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: _frame * math.pi / 6,
      child: Image.asset(
        'assets/images/loading01.png',
        width: 38,
        height: 38,
        fit: BoxFit.fill,
      ),
    );
  }
}

/// `kr.ac.ut.util.RoundedWebView`의 모서리 처리.
///
/// 모서리 반지름은 15dp. 오른쪽 아래를 둥글게 하지 않으면 원본은 그림 영역의 폭을 4000px로
/// 잡아서 오른쪽 두 모서리가 화면 밖으로 나가 둥글게 보이지 않는다(그대로 따름).
class RoundedWebViewClipper extends CustomClipper<Path> {
  const RoundedWebViewClipper({
    required this.topLeft,
    required this.topRight,
    required this.bottomRight,
    required this.bottomLeft,
    required this.devicePixelRatio,
  });

  final bool topLeft;
  final bool topRight;
  final bool bottomRight;
  final bool bottomLeft;
  final double devicePixelRatio;

  @override
  Path getClip(Size size) {
    // b(context, 15) = (int)(15 * density + 0.5) px
    final double r =
        (15 * devicePixelRatio + 0.5).floorToDouble() / devicePixelRatio;
    final double width = bottomRight ? size.width : 4000 / devicePixelRatio;
    return Path()..addRRect(
      RRect.fromLTRBAndCorners(
        0,
        0,
        width,
        size.height,
        topLeft: topLeft ? Radius.circular(r) : Radius.zero,
        topRight: topRight ? Radius.circular(r) : Radius.zero,
        bottomRight: bottomRight ? Radius.circular(r) : Radius.zero,
        bottomLeft: bottomLeft ? Radius.circular(r) : Radius.zero,
      ),
    );
  }

  @override
  bool shouldReclip(RoundedWebViewClipper oldClipper) =>
      oldClipper.topLeft != topLeft ||
      oldClipper.topRight != topRight ||
      oldClipper.bottomRight != bottomRight ||
      oldClipper.bottomLeft != bottomLeft ||
      oldClipper.devicePixelRatio != devicePixelRatio;
}

/// `alert_popup.xml`(확인 버튼) / `nfc_popup.xml`(취소 버튼).
class MessagePopup extends StatelessWidget {
  const MessagePopup({
    super.key,
    required this.message,
    required this.buttonText,
    required this.buttonColor,
    required this.onPressed,
  });

  final String message;
  final String buttonText;
  final Color buttonColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            color: Colors.white,
            padding: const EdgeInsets.only(top: 10),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Text(
                message,
                textAlign: TextAlign.center,
                textScaler: TextScaler.noScaling, // textSize가 dp 단위
                style: const TextStyle(fontSize: 18, color: Colors.black),
              ),
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.only(top: 20),
              child: _FilledDialogButton(
                text: buttonText,
                color: buttonColor,
                onPressed: onPressed,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// XML에서 배경을 `round_button`/`round_cancel_button`으로 바꾼 AppCompatButton.
class _FilledDialogButton extends StatelessWidget {
  const _FilledDialogButton({
    required this.text,
    required this.color,
    required this.onPressed,
  });

  final String text;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 88, minHeight: 48),
      child: Material(
        color: color,
        elevation: 2,
        borderRadius: BorderRadius.circular(5),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(5),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Center(
              widthFactor: 1,
              heightFactor: 1,
              child: Text(
                text.toUpperCase(),
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// `dialog_popup.xml`: 위아래 회색 선 사이의 글, 그 아래 버튼 칸.
class ButtonsPopup extends StatelessWidget {
  const ButtonsPopup({super.key, required this.message, required this.buttons});

  final String message;
  final List<Widget> buttons;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const SizedBox(
            height: 1,
            child: ColoredBox(color: Color(0xFFAAAAAA)),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Text(
                  message,
                  textScaler: TextScaler.noScaling, // textSize가 dp 단위
                  style: const TextStyle(fontSize: 18, color: Colors.black),
                ),
              ),
            ),
          ),
          const SizedBox(
            height: 1,
            child: ColoredBox(color: Color(0xFFAAAAAA)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: buttons,
            ),
          ),
        ],
      ),
    );
  }
}
