import 'dart:ui';

/// Android `Color.parseColor`. 형식이 틀리면 예외를 던진다(원본도 여기서 설정 처리가 중단됨).
Color parseAndroidColor(String colorString) {
  if (colorString.startsWith('#')) {
    final String hex = colorString.substring(1);
    final int? value = int.tryParse(hex, radix: 16);
    if (value == null || hex.startsWith('-') || hex.startsWith('+')) {
      throw ArgumentError('Unknown color');
    }
    if (hex.length == 6) return Color(0xFF000000 | value);
    if (hex.length == 8) return Color(value);
    throw ArgumentError('Unknown color');
  }
  final int? named = _namedColors[colorString.toLowerCase()];
  if (named != null) return Color(named);
  throw ArgumentError('Unknown color');
}

const Map<String, int> _namedColors = <String, int>{
  'black': 0xFF000000,
  'darkgray': 0xFF444444,
  'gray': 0xFF888888,
  'lightgray': 0xFFCCCCCC,
  'white': 0xFFFFFFFF,
  'red': 0xFFFF0000,
  'green': 0xFF00FF00,
  'blue': 0xFF0000FF,
  'yellow': 0xFFFFFF00,
  'cyan': 0xFF00FFFF,
  'magenta': 0xFFFF00FF,
  'aqua': 0xFF00FFFF,
  'fuchsia': 0xFFFF00FF,
  'darkgrey': 0xFF444444,
  'grey': 0xFF888888,
  'lightgrey': 0xFFCCCCCC,
  'lime': 0xFF00FF00,
  'maroon': 0xFF800000,
  'navy': 0xFF000080,
  'olive': 0xFF808000,
  'purple': 0xFF800080,
  'silver': 0xFFC0C0C0,
  'teal': 0xFF008080,
};
