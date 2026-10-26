import 'package:flutter/material.dart';

/// 연결 안내의 종류(통합본 1-9, 1-10, 6-10).
enum ConnectionProblem {
  /// 10초가 지나도 서버가 답하지 않는다.
  slow,

  /// 와이파이·모바일 데이터 연결이 없다.
  offline,

  /// 서버에 연결하지 못했다.
  failed,
}

/// 연결이 안 되거나 늦을 때 빈 화면 대신 보여 주는 한글 안내와 다시 시도 버튼.
///
/// 원본은 이때 빈 화면(시작할 때는 `*` 버튼 하나)만 보였다. 시작 화면, 메인 웹뷰, 팝업 웹뷰가
/// 같은 안내를 쓴다.
class ConnectionNotice extends StatelessWidget {
  const ConnectionNotice({
    super.key,
    required this.problem,
    required this.onRetry,
    this.onClose,
  });

  final ConnectionProblem problem;
  final VoidCallback onRetry;

  /// 있으면 `닫기` 버튼도 보인다(팝업).
  final VoidCallback? onClose;

  static String titleOf(ConnectionProblem problem) => switch (problem) {
    ConnectionProblem.slow => '연결이 늦어지고 있습니다',
    ConnectionProblem.offline => '인터넷에 연결되어 있지 않습니다',
    ConnectionProblem.failed => '연결할 수 없습니다',
  };

  static String messageOf(ConnectionProblem problem) => switch (problem) {
    ConnectionProblem.slow => '학교 서버의 응답을 기다리고 있습니다.\n조금 더 기다리거나 다시 시도해 주세요.',
    ConnectionProblem.offline => '와이파이나 모바일 데이터를 켠 뒤\n다시 시도해 주세요.',
    ConnectionProblem.failed => '학교 서버에 연결하지 못했습니다.\n잠시 뒤 다시 시도해 주세요.',
  };

  static IconData iconOf(ConnectionProblem problem) => switch (problem) {
    ConnectionProblem.slow => Icons.hourglass_bottom,
    ConnectionProblem.offline => Icons.wifi_off,
    ConnectionProblem.failed => Icons.cloud_off,
  };

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return ColoredBox(
      color: Colors.white,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(iconOf(problem), size: 48, color: const Color(0xFF757575)),
              const SizedBox(height: 16),
              Text(
                titleOf(problem),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF212121),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                messageOf(problem),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.4,
                  color: Color(0xFF616161),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: colors.onPrimary,
                  minimumSize: const Size(160, 48),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                child: const Text('다시 시도'),
              ),
              if (onClose != null) ...<Widget>[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: onClose,
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF616161),
                    minimumSize: const Size(160, 48),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                  child: const Text('닫기'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
