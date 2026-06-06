import 'dart:async';

import 'package:flutter/material.dart';

class StudySessionProvider extends ChangeNotifier {
  DateTime? _sessionStart;
  Timer? _ticker;
  Duration _elapsed = Duration.zero;

  bool get isStudying => _sessionStart != null;
  Duration get elapsed => _elapsed;

  String get elapsedLabel {
    final h = _elapsed.inHours;
    final m = _elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = _elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  void startSession() {
    if (isStudying) return;
    _sessionStart = DateTime.now();
    _elapsed = Duration.zero;
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      final sessionStart = _sessionStart;
      if (sessionStart == null) return;
      _elapsed = DateTime.now().difference(sessionStart);
      notifyListeners();
    });
    notifyListeners();
  }

  // 세션 종료 후 경과 시간(분)을 반환
  int endSession() {
    final minutes = _elapsed.inMinutes;
    _sessionStart = null;
    _ticker?.cancel();
    _ticker = null;
    _elapsed = Duration.zero;
    notifyListeners();
    return minutes;
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
